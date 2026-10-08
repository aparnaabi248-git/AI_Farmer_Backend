import io
import os
import uuid
import json
from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from PIL import Image

from dotenv import load_dotenv
from google import genai

from database import db
from schemas.scans import PlantScanResponse
from utils.auth_utils import get_current_user


# ============================================================
# ENVIRONMENT
# ============================================================

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

if not GEMINI_API_KEY:
    raise RuntimeError(
        "GEMINI_API_KEY is not configured. "
        "Please add GEMINI_API_KEY to your .env file."
    )

# Gemini client
gemini_client = genai.Client(api_key=GEMINI_API_KEY)


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/scans",
    tags=["Plant Scanning & Diagnosis"]
)


# ============================================================
# GEMINI PLANT DISEASE ANALYSIS
# ============================================================

def analyze_leaf_image_from_bytes(
    image_bytes: bytes,
    original_filename: str = ""
) -> tuple:

    try:
        # ----------------------------------------------------
        # Open uploaded image
        # ----------------------------------------------------

        image = Image.open(
            io.BytesIO(image_bytes)
        ).convert("RGB")

        # Resize large images to reduce API payload
        image.thumbnail((1024, 1024))

        # ----------------------------------------------------
        # Prompt for Gemini
        # ----------------------------------------------------

        prompt = """
You are an expert agricultural plant disease analysis assistant.

Analyze the uploaded plant or leaf image carefully.

Your task is to identify:
1. Plant disease
2. Confidence percentage
3. Visible or likely pest
4. Recommended treatment
5. Prevention advice

Return ONLY valid JSON.

Use exactly this format:

{
    "disease": "Disease name or Healthy Plant",
    "confidence": "95%",
    "pest": "Pest name or None",
    "medicine": "Recommended treatment",
    "prevention": "Prevention advice"
}

IMPORTANT RULES:

- Analyze the IMAGE itself.
- Do NOT use the filename to identify the disease.
- Do NOT guess based only on the filename.
- If the image clearly shows a healthy plant, return:
  "Healthy Plant"
- If the image is not a plant or leaf image, return:
  "Invalid Plant Image"
- If the image is unclear, do not confidently invent a disease.
- In unclear cases, use:
  "Uncertain - Image Not Clear"
- Only mention a pest if there are visible signs or a reasonable agricultural indication.
- If no pest is identified, return:
  "None"
- Give practical and safe agricultural treatment advice.
- Do not recommend dangerous or excessive chemical usage.
- Mention the appropriate fungicide, pesticide, organic treatment, or cultural practice when appropriate.
- Prevention advice should be short and practical.
- Confidence must be a percentage such as "92%".
- Keep all values as strings.
- Return JSON only.
"""

        # ----------------------------------------------------
        # Send image + prompt to Gemini
        # ----------------------------------------------------

        response = gemini_client.models.generate_content(
            model="gemini-3.8-flash",
            contents=[
                prompt,
                image
            ]
        )

        # ----------------------------------------------------
        # Get Gemini response
        # ----------------------------------------------------

        if not response.text:
            raise ValueError(
                "Gemini returned an empty response."
            )

        response_text = response.text.strip()

        print("Gemini response:")
        print(response_text)

        # ----------------------------------------------------
        # Remove Markdown code block if Gemini adds it
        # ----------------------------------------------------

        if response_text.startswith("```json"):
            response_text = response_text[7:]

        elif response_text.startswith("```"):
            response_text = response_text[3:]

        if response_text.endswith("```"):
            response_text = response_text[:-3]

        response_text = response_text.strip()

        # ----------------------------------------------------
        # Convert JSON string to Python dictionary
        # ----------------------------------------------------

        result = json.loads(response_text)

        # ----------------------------------------------------
        # Extract values safely
        # ----------------------------------------------------

        disease = str(
            result.get(
                "disease",
                "Uncertain - Image Not Clear"
            )
        )

        confidence = str(
            result.get(
                "confidence",
                "0%"
            )
        )

        pest = str(
            result.get(
                "pest",
                "None"
            )
        )

        medicine = str(
            result.get(
                "medicine",
                "No treatment recommendation available."
            )
        )

        prevention = str(
            result.get(
                "prevention",
                "Please consult a local agricultural expert."
            )
        )

        # ----------------------------------------------------
        # Return same format expected by Flutter
        # ----------------------------------------------------

        return (
            disease,
            confidence,
            pest,
            medicine,
            prevention
        )

    except Exception as e:

        print(
            f"Gemini plant analysis error: {str(e)}"
        )

        # Do not crash the entire API.
        # Flutter will receive a clear failure result.

        return (
            "AI Analysis Failed",
            "0%",
            "Unknown",
            "Please try again with a clear plant image.",
            "Upload a clear image of the affected leaf."
        )


# ============================================================
# ANALYZE PLANT
# ============================================================

@router.post(
    "/analyze",
    response_model=PlantScanResponse
)
async def analyze_plant(
    file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user)
):

    # --------------------------------------------------------
    # Check file extension
    # --------------------------------------------------------

    original_filename = file.filename or ""

    ext = os.path.splitext(
        original_filename
    )[1].lower()

    allowed_extensions = [
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    ]

    if ext not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail=(
                "Invalid image format. "
                "Use JPG, JPEG, PNG or WEBP."
            )
        )

    # --------------------------------------------------------
    # Read image
    # --------------------------------------------------------

    try:

        image_bytes = await file.read()

    except Exception as e:

        raise HTTPException(
            status_code=400,
            detail=(
                f"Could not read the uploaded image: {str(e)}"
            )
        )

    finally:

        await file.close()

    # --------------------------------------------------------
    # Check image size
    # --------------------------------------------------------

    max_size = 4 * 1024 * 1024

    if len(image_bytes) > max_size:

        raise HTTPException(
            status_code=413,
            detail=(
                "Image is too large. "
                "Please compress or resize before uploading "
                "(max 4 MB)."
            )
        )

    # --------------------------------------------------------
    # Check empty image
    # --------------------------------------------------------

    if len(image_bytes) == 0:

        raise HTTPException(
            status_code=400,
            detail="Uploaded image is empty."
        )

    # --------------------------------------------------------
    # Validate image
    # --------------------------------------------------------

    try:

        test_image = Image.open(
            io.BytesIO(image_bytes)
        )

        test_image.verify()

    except Exception:

        raise HTTPException(
            status_code=400,
            detail=(
                "The uploaded file is not a valid image."
            )
        )

    # --------------------------------------------------------
    # Gemini AI analysis
    # --------------------------------------------------------

    try:

        (
            disease,
            confidence,
            pest,
            medicine,
            prevention
        ) = analyze_leaf_image_from_bytes(
            image_bytes,
            original_filename
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=(
                f"Image analysis failed: {str(e)}"
            )
        )

    # --------------------------------------------------------
    # Generate image ID
    # --------------------------------------------------------

    file_id = str(
        uuid.uuid4()
    )

    image_url = (
        f"/scan-image/{file_id}"
    )

    # --------------------------------------------------------
    # Create database record
    # --------------------------------------------------------

    scan_record = {

        "user_id": current_user["id"],

        "disease": disease,

        "confidence": confidence,

        "pest": pest,

        "medicine": medicine,

        "prevention": prevention,

        "image_url": image_url,

        "created_at": datetime.utcnow().isoformat()
    }

    # --------------------------------------------------------
    # Save scan result
    # --------------------------------------------------------

    try:

        result = db["scans"].insert_one(
            scan_record
        )

        scan_record["id"] = str(
            result.inserted_id
        )

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=(
                f"Could not save scan result: {str(e)}"
            )
        )

    # --------------------------------------------------------
    # Return result to Flutter
    # --------------------------------------------------------

    return scan_record


# ============================================================
# SCAN HISTORY
# ============================================================

@router.get(
    "/history",
    response_model=List[PlantScanResponse]
)
def get_scan_history(
    current_user: dict = Depends(get_current_user)
):

    try:

        cursor = db["scans"].find(
            {
                "user_id": current_user["id"]
            }
        ).sort(
            "created_at",
            -1
        )

        history = []

        for doc in cursor:

            doc["id"] = str(
                doc["_id"]
            )

            del doc["_id"]

            history.append(doc)

        return history

    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=(
                f"Could not load scan history: {str(e)}"
            )
        )