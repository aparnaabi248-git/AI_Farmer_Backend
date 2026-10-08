import io
import os
import json
import uuid
import time
from datetime import datetime, timezone

from fastapi import (
    APIRouter,
    Depends,
    File,
    UploadFile,
    HTTPException
)

from fastapi.responses import StreamingResponse

from PIL import Image
from google import genai
from dotenv import load_dotenv

from database import db
from schemas.scans import PlantScanResponse
from utils.auth_utils import get_current_user


# =========================================================
# ENVIRONMENT
# =========================================================

load_dotenv()


# =========================================================
# ROUTER
# =========================================================

router = APIRouter(
    prefix="/scans",
    tags=["Plant Scanning & Diagnosis"]
)


# =========================================================
# GEMINI CONFIGURATION
# =========================================================

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Try models in this order.
# If one model is temporarily unavailable,
# the next model will be tried automatically.
GEMINI_MODELS = [
    "gemini-3.8-flash",
    "gemini-3.7-flash",
    "gemini-3.6-flash"
]

gemini_client = None


if not GEMINI_API_KEY:

    print(
        "WARNING: GEMINI_API_KEY is not configured"
    )

else:

    try:

        gemini_client = genai.Client(
            api_key=GEMINI_API_KEY
        )

        print(
            "Gemini client initialized successfully"
        )

        print(
            "Gemini models:",
            GEMINI_MODELS
        )

    except Exception as e:

        print(
            "GEMINI CLIENT INIT ERROR:",
            repr(e)
        )


# =========================================================
# GEMINI PLANT ANALYSIS
# =========================================================

def analyze_plant_with_gemini(
    image_bytes: bytes
):

    """
    Analyze plant image using Gemini AI.

    Tries multiple Gemini models automatically.

    Returns:

        disease
        confidence
        pest
        medicine
        prevention
    """

    # -----------------------------------------------------
    # CHECK GEMINI CLIENT
    # -----------------------------------------------------

    if gemini_client is None:

        print(
            "GEMINI ERROR: Client is not initialized"
        )

        raise HTTPException(

            status_code=503,

            detail=(
                "Gemini AI is not configured "
                "on the server."
            )

        )

    try:

        # =================================================
        # OPEN IMAGE
        # =================================================

        image = Image.open(
            io.BytesIO(image_bytes)
        )

        print(
            "IMAGE INFO:",
            "format=", image.format,
            "size=", image.size,
            "mode=", image.mode
        )

        # =================================================
        # CONVERT IMAGE TO RGB
        # =================================================

        if image.mode != "RGB":

            image = image.convert("RGB")

        # =================================================
        # RESIZE IMAGE
        # =================================================

        image.thumbnail(
            (1024, 1024)
        )

        print(
            "IMAGE AFTER RESIZE:",
            image.size
        )

        # =================================================
        # GEMINI PROMPT
        # =================================================

        prompt = """
You are an expert agricultural plant disease detection AI.

Analyze the provided plant or leaf image carefully.

Your first task is to determine whether the image contains
a plant or leaf.

=========================================================
CASE 1 - NOT A PLANT
=========================================================

If the image is NOT a plant or leaf, return exactly:

{
  "disease": "Invalid Plant Image",
  "confidence": "0%",
  "pest": "None",
  "medicine": "None",
  "prevention": "Please upload a clear image of a plant or leaf."
}

=========================================================
CASE 2 - UNCLEAR IMAGE
=========================================================

If the image contains a plant but the disease cannot
be determined clearly, return:

{
  "disease": "Uncertain - Image Not Clear",
  "confidence": "0%",
  "pest": "Unknown",
  "medicine": "Please upload a clearer image.",
  "prevention": "Take a clear photo of the affected leaf in good lighting."
}

=========================================================
CASE 3 - HEALTHY PLANT
=========================================================

If the plant appears healthy, return:

{
  "disease": "Healthy Plant",
  "confidence": "95%",
  "pest": "None",
  "medicine": "No treatment required.",
  "prevention": "Continue proper watering, sunlight, nutrition and regular monitoring."
}

=========================================================
CASE 4 - DISEASED PLANT
=========================================================

If disease symptoms are visible:

1. Identify the most likely plant disease.
2. Base the diagnosis only on visible symptoms.
3. Do not invent a disease.
4. Give a realistic confidence percentage.
5. Mention a likely pest only when appropriate.
6. Give practical and safe treatment advice.
7. Give practical prevention advice.

If you are not reasonably sure about the disease,
return:

"Uncertain - Image Not Clear"

instead of guessing.

=========================================================
IMPORTANT AGRICULTURAL SAFETY
=========================================================

Do not recommend dangerous chemical usage.

Do not give unsafe pesticide mixing instructions.

If a chemical treatment is suggested, keep the advice
general and recommend following the product label and
local agricultural guidance.

=========================================================
RESPONSE FORMAT
=========================================================

Return ONLY valid JSON.

Use exactly this structure:

{
  "disease": "Disease name or Healthy Plant",
  "confidence": "95%",
  "pest": "Pest name or None",
  "medicine": "Recommended treatment",
  "prevention": "Prevention advice"
}

=========================================================
STRICT RULES
=========================================================

1. Analyze the actual image.
2. Do not use the filename.
3. Do not invent a disease.
4. Do not claim high confidence when the image is unclear.
5. Confidence must be a percentage string.
6. If no pest is visible or reasonably indicated, use "None".
7. Give practical and safe agricultural advice.
8. Do not recommend dangerous chemical usage.
9. Return JSON only.
10. Do not use Markdown.
11. Do not return ```json.
12. Do not add explanations outside the JSON.
13. Do not return extra fields.
"""

        # =================================================
        # GEMINI REQUEST
        # =================================================

        response = None
        successful_model = None
        last_error = None

        # Try every model
        for model_index, model_name in enumerate(
            GEMINI_MODELS
        ):

            # ---------------------------------------------
            # TRY CURRENT MODEL UP TO 2 TIMES
            # ---------------------------------------------

            max_retries = 2

            for attempt in range(max_retries):

                try:

                    print(
                        "========================================"
                    )

                    print(
                        "GEMINI REQUEST"
                    )

                    print(
                        "Model:",
                        model_name
                    )

                    print(
                        f"Model {model_index + 1}/"
                        f"{len(GEMINI_MODELS)}"
                    )

                    print(
                        f"Attempt {attempt + 1}/"
                        f"{max_retries}"
                    )

                    print(
                        "========================================"
                    )

                    start_time = time.time()

                    response = (
                        gemini_client.models.generate_content(

                            model=model_name,

                            contents=[
                                prompt,
                                image
                            ]

                        )
                    )

                    elapsed = (
                        time.time()
                        - start_time
                    )

                    print(
                        "GEMINI RESPONSE RECEIVED "
                        f"in {elapsed:.2f} seconds"
                    )

                    successful_model = model_name

                    break

                except Exception as e:

                    error_text = str(e)

                    last_error = e

                    print(
                        "========================================"
                    )

                    print(
                        "GEMINI REQUEST ERROR"
                    )

                    print(
                        "Model:",
                        model_name
                    )

                    print(
                        "ERROR TYPE:",
                        type(e).__name__
                    )

                    print(
                        "ERROR:",
                        repr(e)
                    )

                    print(
                        "========================================"
                    )

                    # =====================================
                    # TEMPORARY ERROR CHECK
                    # =====================================

                    temporary_error = (

                        "503" in error_text

                        or

                        "UNAVAILABLE"
                        in error_text

                        or

                        "429" in error_text

                        or

                        "RESOURCE_EXHAUSTED"
                        in error_text

                        or

                        "high demand"
                        in error_text.lower()

                        or

                        "rate limit"
                        in error_text.lower()

                    )

                    # =====================================
                    # RETRY SAME MODEL
                    # =====================================

                    if (
                        temporary_error
                        and
                        attempt < max_retries - 1
                    ):

                        wait_time = (
                            2 ** attempt
                        )

                        print(
                            "Temporary Gemini error."
                        )

                        print(
                            f"Retrying {model_name} "
                            f"in {wait_time} seconds..."
                        )

                        time.sleep(
                            wait_time
                        )

                        continue

                    # =====================================
                    # MOVE TO NEXT MODEL
                    # =====================================

                    if temporary_error:

                        print(
                            "Model",
                            model_name,
                            "is temporarily unavailable."
                        )

                        print(
                            "Trying next Gemini model..."
                        )

                        break

                    # =====================================
                    # NON-TEMPORARY ERROR
                    # =====================================

                    raise HTTPException(

                        status_code=503,

                        detail={

                            "message":
                                "Gemini AI analysis failed.",

                            "error_type":
                                type(e).__name__,

                            "error":
                                error_text,

                            "model":
                                model_name

                        }

                    )

            # ---------------------------------------------
            # STOP IF MODEL SUCCEEDED
            # ---------------------------------------------

            if response is not None:

                break

        # =================================================
        # ALL MODELS FAILED
        # =================================================

        if response is None:

            print(
                "========================================"
            )

            print(
                "ALL GEMINI MODELS FAILED"
            )

            print(
                "Models tried:",
                GEMINI_MODELS
            )

            print(
                "========================================"
            )

            raise HTTPException(

                status_code=503,

                detail={

                    "message":
                        "All Gemini models are temporarily unavailable.",

                    "models_tried":
                        GEMINI_MODELS,

                    "last_error":
                        str(last_error)
                        if last_error
                        else "Unknown error"

                }

            )

        # =================================================
        # GET RESPONSE TEXT
        # =================================================

        response_text = response.text

        if not response_text:

            raise HTTPException(

                status_code=503,

                detail=(
                    "Gemini returned an empty response."
                )

            )

        print(
            "========================================"
        )

        print(
            "GEMINI RAW RESPONSE"
        )

        print(
            "Successful model:",
            successful_model
        )

        print(
            response_text[:3000]
        )

        print(
            "========================================"
        )

        # =================================================
        # CLEAN GEMINI RESPONSE
        # =================================================

        cleaned_text = response_text.strip()

        # Remove ```json
        if cleaned_text.startswith(
            "```json"
        ):

            cleaned_text = cleaned_text[
                len("```json"):
            ].strip()

        # Remove ```
        elif cleaned_text.startswith(
            "```"
        ):

            cleaned_text = cleaned_text[
                len("```"):
            ].strip()

        # Remove ending ```
        if cleaned_text.endswith(
            "```"
        ):

            cleaned_text = cleaned_text[
                :-len("```")
            ].strip()

        # =================================================
        # PARSE JSON
        # =================================================

        try:

            result = json.loads(
                cleaned_text
            )

        except json.JSONDecodeError as e:

            print(
                "========================================"
            )

            print(
                "GEMINI JSON ERROR:",
                repr(e)
            )

            print(
                "INVALID GEMINI RESPONSE:"
            )

            print(
                cleaned_text[:3000]
            )

            print(
                "========================================"
            )

            raise HTTPException(

                status_code=503,

                detail={

                    "message":
                        "Gemini returned invalid JSON.",

                    "error_type":
                        "JSONDecodeError",

                    "error":
                        str(e),

                    "gemini_response":
                        cleaned_text[:1000],

                    "model":
                        successful_model

                }

            )

        # =================================================
        # VALIDATE RESULT
        # =================================================

        if not isinstance(
            result,
            dict
        ):

            raise HTTPException(

                status_code=503,

                detail=(
                    "Gemini returned an invalid "
                    "response structure."
                )

            )

        # =================================================
        # GET VALUES
        # =================================================

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
                "Please consult an agricultural expert."
            )
        )

        prevention = str(
            result.get(
                "prevention",
                "Upload a clear plant image."
            )
        )

        # =================================================
        # FINAL RESULT LOG
        # =================================================

        print(
            "========================================"
        )

        print(
            "GEMINI ANALYSIS SUCCESS"
        )

        print(
            "Successful model:",
            successful_model
        )

        print(
            "Disease:",
            disease
        )

        print(
            "Confidence:",
            confidence
        )

        print(
            "Pest:",
            pest
        )

        print(
            "========================================"
        )

        return (
            disease,
            confidence,
            pest,
            medicine,
            prevention
        )

    # =====================================================
    # HTTP EXCEPTION
    # =====================================================

    except HTTPException:

        raise

    # =====================================================
    # UNEXPECTED ERROR
    # =====================================================

    except Exception as e:

        print(
            "========================================"
        )

        print(
            "UNEXPECTED GEMINI ERROR"
        )

        print(
            "ERROR TYPE:",
            type(e).__name__
        )

        print(
            "ERROR:",
            repr(e)
        )

        print(
            "========================================"
        )

        raise HTTPException(

            status_code=503,

            detail={

                "message":
                    "Unexpected Gemini error.",

                "error_type":
                    type(e).__name__,

                "error":
                    str(e)

            }

        )


# =========================================================
# POST /scans/analyze
# =========================================================

@router.post(
    "/analyze",
    response_model=PlantScanResponse
)
async def analyze_plant(

    file: UploadFile = File(...),

    current_user: dict = Depends(
        get_current_user
    )

):

    print(
        "========================================"
    )

    print(
        "NEW PLANT SCAN REQUEST"
    )

    print(
        "Filename:",
        file.filename
    )

    print(
        "Content Type:",
        file.content_type
    )

    print(
        "========================================"
    )

    # =====================================================
    # VALID FILE TYPES
    # =====================================================

    allowed_types = {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    }

    if file.content_type not in allowed_types:

        raise HTTPException(

            status_code=400,

            detail=(
                "Invalid image format. "
                "Only JPG, JPEG, PNG and WEBP are allowed."
            )

        )

    # =====================================================
    # READ IMAGE
    # =====================================================

    try:

        image_bytes = await file.read()

    except Exception as e:

        print(
            "IMAGE READ ERROR:",
            repr(e)
        )

        raise HTTPException(

            status_code=400,

            detail="Could not read uploaded image."

        )

    finally:

        await file.close()

    # =====================================================
    # EMPTY IMAGE CHECK
    # =====================================================

    if len(image_bytes) == 0:

        raise HTTPException(

            status_code=400,

            detail="Uploaded image is empty."

        )

    # =====================================================
    # FILE SIZE CHECK
    # =====================================================

    max_size = 4 * 1024 * 1024

    if len(image_bytes) > max_size:

        raise HTTPException(

            status_code=413,

            detail=(
                "Image size must be less than 4 MB."
            )

        )

    print(
        "IMAGE SIZE:",
        f"{len(image_bytes) / 1024:.2f} KB"
    )

    # =====================================================
    # IMAGE VALIDATION
    # =====================================================

    try:

        image = Image.open(
            io.BytesIO(image_bytes)
        )

        image.verify()

        print(
            "IMAGE VALIDATION: SUCCESS"
        )

    except Exception as e:

        print(
            "IMAGE VALIDATION ERROR:",
            repr(e)
        )

        raise HTTPException(

            status_code=400,

            detail="Invalid or corrupted image."

        )

    # =====================================================
    # GEMINI ANALYSIS
    # =====================================================

    (
        disease,
        confidence,
        pest,
        medicine,
        prevention

    ) = analyze_plant_with_gemini(
        image_bytes
    )

    # =====================================================
    # USER ID
    # =====================================================

    user_id = str(
        current_user.get(
            "_id",
            current_user.get(
                "id",
                ""
            )
        )
    )

    if not user_id:

        raise HTTPException(

            status_code=401,

            detail="User ID not found."

        )

    # =====================================================
    # CREATE IMAGE ID
    # =====================================================

    image_id = str(
        uuid.uuid4()
    )

    # =====================================================
    # CREATE TIMESTAMP
    # =====================================================

    created_at = datetime.now(
        timezone.utc
    ).isoformat()

    # =====================================================
    # MONGODB DOCUMENT
    # =====================================================

    scan_document = {

        "user_id":
            user_id,

        "disease":
            disease,

        "confidence":
            confidence,

        "pest":
            pest,

        "medicine":
            medicine,

        "prevention":
            prevention,

        "image_id":
            image_id,

        "image_url":
            f"/scans/image/{image_id}",

        "created_at":
            created_at,

        "image_data":
            image_bytes,

        "image_content_type":
            file.content_type

    }

    # =====================================================
    # SAVE TO MONGODB
    # =====================================================

    try:

        result = db["scans"].insert_one(
            scan_document
        )

        scan_id = str(
            result.inserted_id
        )

        print(
            "SCAN SAVED:",
            scan_id
        )

    except Exception as e:

        print(
            "MONGODB SCAN SAVE ERROR:",
            repr(e)
        )

        raise HTTPException(

            status_code=500,

            detail="Could not save scan result."

        )

    # =====================================================
    # RESPONSE
    # =====================================================

    return {

        "id":
            scan_id,

        "disease":
            disease,

        "confidence":
            confidence,

        "pest":
            pest,

        "medicine":
            medicine,

        "prevention":
            prevention,

        "image_url":
            f"/scans/image/{image_id}",

        "created_at":
            created_at

    }


# =========================================================
# GET /scans/image/{image_id}
# =========================================================

@router.get(
    "/image/{image_id}"
)
async def get_scan_image(

    image_id: str,

    current_user: dict = Depends(
        get_current_user
    )

):

    # =====================================================
    # USER ID
    # =====================================================

    user_id = str(
        current_user.get(
            "_id",
            current_user.get(
                "id",
                ""
            )
        )
    )

    # =====================================================
    # FIND IMAGE
    # =====================================================

    try:

        scan = db["scans"].find_one({

            "image_id":
                image_id,

            "user_id":
                user_id

        })

    except Exception as e:

        print(
            "IMAGE DATABASE ERROR:",
            repr(e)
        )

        raise HTTPException(

            status_code=500,

            detail="Database error."

        )

    # =====================================================
    # NOT FOUND
    # =====================================================

    if not scan:

        raise HTTPException(

            status_code=404,

            detail="Scan image not found."

        )

    # =====================================================
    # GET IMAGE DATA
    # =====================================================

    image_data = scan.get(
        "image_data"
    )

    content_type = scan.get(
        "image_content_type",
        "image/jpeg"
    )

    if not image_data:

        raise HTTPException(

            status_code=404,

            detail="Image data not found."

        )

    # =====================================================
    # RETURN IMAGE
    # =====================================================

    return StreamingResponse(

        io.BytesIO(image_data),

        media_type=content_type

    )


# =========================================================
# GET /scans/history
# =========================================================

@router.get(
    "/history",
    response_model=list[PlantScanResponse]
)
async def get_scan_history(

    current_user: dict = Depends(
        get_current_user
    )

):

    # =====================================================
    # USER ID
    # =====================================================

    user_id = str(
        current_user.get(
            "_id",
            current_user.get(
                "id",
                ""
            )
        )
    )

    if not user_id:

        raise HTTPException(

            status_code=401,

            detail="User ID not found."

        )

    # =====================================================
    # GET SCANS
    # =====================================================

    try:

        scans = list(

            db["scans"].find(

                {
                    "user_id":
                        user_id
                }

            ).sort(

                "created_at",
                -1

            )

        )

        history = []

        for scan in scans:

            history.append({

                "id":
                    str(
                        scan.get(
                            "_id",
                            ""
                        )
                    ),

                "disease":
                    scan.get(
                        "disease",
                        ""
                    ),

                "confidence":
                    scan.get(
                        "confidence",
                        ""
                    ),

                "pest":
                    scan.get(
                        "pest",
                        ""
                    ),

                "medicine":
                    scan.get(
                        "medicine",
                        ""
                    ),

                "prevention":
                    scan.get(
                        "prevention",
                        ""
                    ),

                "image_url":
                    scan.get(
                        "image_url",
                        ""
                    ),

                "created_at":
                    scan.get(
                        "created_at",
                        ""
                    )

            })

        return history

    except Exception as e:

        print(
            "SCAN HISTORY ERROR:",
            repr(e)
        )

        raise HTTPException(

            status_code=500,

            detail="Unable to load scan history."

        )