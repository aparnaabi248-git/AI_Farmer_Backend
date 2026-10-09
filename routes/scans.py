import io
import os
import json
import uuid
import time
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, File, UploadFile, HTTPException
from fastapi.responses import StreamingResponse
from fastapi.concurrency import run_in_threadpool

from PIL import Image
from google import genai
from google.genai import types
from dotenv import load_dotenv

from database import db
from schemas.scans import PlantScanResponse
from utils.auth_utils import get_current_user


load_dotenv()

router = APIRouter(
    prefix="/scans",
    tags=["Plant Scanning & Diagnosis"]
)

# Use one model per request to avoid long fallback chains.
GEMINI_MODEL = "gemini-2.5-flash-lite"
GEMINI_TIMEOUT_MS = 45000

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
gemini_client = None

if not GEMINI_API_KEY:
    print("WARNING: GEMINI_API_KEY is not configured")
else:
    try:
        gemini_client = genai.Client(
            api_key=GEMINI_API_KEY,
            http_options=types.HttpOptions(
                timeout=GEMINI_TIMEOUT_MS
            )
        )
        print("Gemini client initialized")
        print("Gemini model:", GEMINI_MODEL)
        print("Gemini HTTP timeout:", GEMINI_TIMEOUT_MS, "ms")
    except Exception as e:
        print("GEMINI CLIENT INIT ERROR:", repr(e))


PLANT_PROMPT = """
You are an agricultural plant disease analysis assistant.
Analyze the actual uploaded image and return JSON only.

Determine whether the image contains a plant or leaf.

If it is not a plant, return:
{
  "disease": "Invalid Plant Image",
  "confidence": "0%",
  "pest": "None",
  "medicine": "None",
  "prevention": "Please upload a clear image of a plant or leaf."
}

If the plant image is unclear, return:
{
  "disease": "Uncertain - Image Not Clear",
  "confidence": "0%",
  "pest": "Unknown",
  "medicine": "Please upload a clearer image.",
  "prevention": "Take a clear photo of the affected leaf in good lighting."
}

If the plant appears healthy, return:
{
  "disease": "Healthy Plant",
  "confidence": "95%",
  "pest": "None",
  "medicine": "No treatment required.",
  "prevention": "Continue proper watering, sunlight, nutrition and regular monitoring."
}

For a diseased plant:
- Identify the most likely disease from visible symptoms.
- Do not invent a disease or claim certainty without evidence.
- Give a realistic confidence percentage.
- Mention pests only when reasonably indicated.
- Give practical, safe treatment and prevention advice.
- Do not give dangerous pesticide mixing instructions.
- Recommend following product labels and local agricultural guidance.

Return exactly these JSON fields:
disease, confidence, pest, medicine, prevention.

Do not return Markdown fences or explanations outside the JSON.
"""


def analyze_plant_with_gemini(image_bytes: bytes):
    if gemini_client is None:
        raise HTTPException(
            status_code=503,
            detail="Gemini AI is not configured on the server."
        )

    try:
        with Image.open(io.BytesIO(image_bytes)) as source:
            print(
                "IMAGE INFO:",
                "format=", source.format,
                "size=", source.size,
                "mode=", source.mode
            )

            image = source.convert("RGB")
            image.thumbnail((1024, 1024))

    except Exception as e:
        print("IMAGE PROCESSING ERROR:", repr(e))
        raise HTTPException(
            status_code=400,
            detail="Could not process the uploaded image."
        )

    started = time.monotonic()

    try:
        print("GEMINI REQUEST START:", GEMINI_MODEL)

        response = gemini_client.models.generate_content(
            model=GEMINI_MODEL,
            contents=[PLANT_PROMPT, image],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                temperature=0.2,
                max_output_tokens=600
            )
        )

        elapsed = time.monotonic() - started
        print(f"GEMINI RESPONSE RECEIVED in {elapsed:.2f} seconds")

    except Exception as e:
        elapsed = time.monotonic() - started
        error_text = str(e)

        print(
            f"GEMINI REQUEST FAILED after {elapsed:.2f} seconds:",
            type(e).__name__,
            repr(e)
        )

        if (
            "timeout" in error_text.lower()
            or "timed out" in error_text.lower()
        ):
            raise HTTPException(
                status_code=504,
                detail=(
                    "Gemini analysis timed out. "
                    "Please try again with a clear, smaller plant image."
                )
            )

        if (
            "429" in error_text
            or "RESOURCE_EXHAUSTED" in error_text
        ):
            raise HTTPException(
                status_code=503,
                detail=(
                    "Gemini is temporarily busy or the API quota "
                    "has been reached. Please try again later."
                )
            )

        raise HTTPException(
            status_code=503,
            detail="Gemini could not analyze the image. Please try again."
        )

    response_text = response.text

    if not response_text:
        raise HTTPException(
            status_code=503,
            detail="Gemini returned an empty response."
        )

    try:
        result = json.loads(response_text.strip())
    except json.JSONDecodeError:
        print("INVALID GEMINI JSON:", response_text[:1000])
        raise HTTPException(
            status_code=502,
            detail="Gemini returned an invalid response. Please try again."
        )

    if not isinstance(result, dict):
        raise HTTPException(
            status_code=502,
            detail="Gemini returned an invalid response structure."
        )

    required_fields = [
        "disease",
        "confidence",
        "pest",
        "medicine",
        "prevention"
    ]

    for field in required_fields:
        if not isinstance(result.get(field), str):
            raise HTTPException(
                status_code=502,
                detail="Gemini returned incomplete analysis. Please try again."
            )

    print(
        "GEMINI ANALYSIS SUCCESS:",
        result.get("disease"),
        result.get("confidence")
    )

    return (
        result["disease"],
        result["confidence"],
        result["pest"],
        result["medicine"],
        result["prevention"]
    )


@router.post("/analyze", response_model=PlantScanResponse)
async def analyze_plant(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):
    started = time.monotonic()

    print("NEW PLANT SCAN REQUEST:", file.filename, file.content_type)

    allowed_types = {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    }

    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail="Only JPG, JPEG, PNG and WEBP images are allowed."
        )

    try:
        image_bytes = await file.read()
    finally:
        await file.close()

    if not image_bytes:
        raise HTTPException(
            status_code=400,
            detail="Uploaded image is empty."
        )

    max_size = 4 * 1024 * 1024

    if len(image_bytes) > max_size:
        raise HTTPException(
            status_code=413,
            detail="Image size must be less than 4 MB."
        )

    try:
        with Image.open(io.BytesIO(image_bytes)) as image:
            image.verify()
    except Exception:
        raise HTTPException(
            status_code=400,
            detail="Invalid or corrupted image."
        )

    print(f"IMAGE SIZE: {len(image_bytes) / 1024:.2f} KB")

    # Run the synchronous Gemini SDK in a worker thread.
    disease, confidence, pest, medicine, prevention = (
        await run_in_threadpool(
            analyze_plant_with_gemini,
            image_bytes
        )
    )

    user_id = str(
        current_user.get("_id", current_user.get("id", ""))
    )

    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="User ID not found."
        )

    image_id = str(uuid.uuid4())
    created_at = datetime.now(timezone.utc).isoformat()

    scan_document = {
        "user_id": user_id,
        "disease": disease,
        "confidence": confidence,
        "pest": pest,
        "medicine": medicine,
        "prevention": prevention,
        "image_id": image_id,
        "image_url": f"/scans/image/{image_id}",
        "created_at": created_at,
        "image_data": image_bytes,
        "image_content_type": file.content_type
    }

    try:
        result = await run_in_threadpool(
            db["scans"].insert_one,
            scan_document
        )
        scan_id = str(result.inserted_id)
        print("SCAN SAVED:", scan_id)
    except Exception as e:
        print("MONGODB SCAN SAVE ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Could not save scan result."
        )

    print(
        f"SCAN REQUEST COMPLETED in "
        f"{time.monotonic() - started:.2f} seconds"
    )

    return {
        "id": scan_id,
        "disease": disease,
        "confidence": confidence,
        "pest": pest,
        "medicine": medicine,
        "prevention": prevention,
        "image_url": f"/scans/image/{image_id}",
        "created_at": created_at
    }


@router.get("/image/{image_id}")
async def get_scan_image(
    image_id: str,
    current_user: dict = Depends(get_current_user)
):
    user_id = str(
        current_user.get("_id", current_user.get("id", ""))
    )

    try:
        scan = await run_in_threadpool(
            db["scans"].find_one,
            {"image_id": image_id, "user_id": user_id}
        )
    except Exception as e:
        print("IMAGE DATABASE ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Database error."
        )

    if not scan:
        raise HTTPException(
            status_code=404,
            detail="Scan image not found."
        )

    image_data = scan.get("image_data")

    if not image_data:
        raise HTTPException(
            status_code=404,
            detail="Image data not found."
        )

    return StreamingResponse(
        io.BytesIO(image_data),
        media_type=scan.get("image_content_type", "image/jpeg")
    )


@router.get("/history", response_model=list[PlantScanResponse])
async def get_scan_history(
    current_user: dict = Depends(get_current_user)
):
    user_id = str(
        current_user.get("_id", current_user.get("id", ""))
    )

    if not user_id:
        raise HTTPException(
            status_code=401,
            detail="User ID not found."
        )

    try:
        scans = await run_in_threadpool(
            lambda: list(
                db["scans"].find(
                    {"user_id": user_id}
                ).sort("created_at", -1)
            )
        )

        return [
            {
                "id": str(scan.get("_id", "")),
                "disease": scan.get("disease", ""),
                "confidence": scan.get("confidence", ""),
                "pest": scan.get("pest", ""),
                "medicine": scan.get("medicine", ""),
                "prevention": scan.get("prevention", ""),
                "image_url": scan.get("image_url", ""),
                "created_at": scan.get("created_at", "")
            }
            for scan in scans
        ]

    except Exception as e:
        print("SCAN HISTORY ERROR:", repr(e))
        raise HTTPException(
            status_code=500,
            detail="Unable to load scan history."
        )
