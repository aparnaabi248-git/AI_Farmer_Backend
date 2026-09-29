from fastapi import APIRouter, Depends, HTTPException
from datetime import datetime
from database import db
from schemas.crops import CropRecommendationRequest, CropRecommendationResponse
from utils.auth_utils import get_current_user
from typing import List

router = APIRouter(prefix="/crops", tags=["Crop Recommendation"])

def recommend_crop_algorithm(temp: float, humidity: float, rainfall: float, soil: str) -> tuple:
    soil_l = soil.lower()
    if "black" in soil_l and temp >= 25 and humidity >= 60 and rainfall >= 80:
        return "Cotton", "Kharif", "Urea + DAP (NPK 4:2:1)"
    elif "red" in soil_l:
        return "Groundnut", "Kharif", "NPK Fertilizer (10:26:26)"
    elif "clay" in soil_l or "marshy" in soil_l:
        return "Rice", "Monsoon", "Nitrogen Fertilizer & Ammonium Sulfate"
    elif "loamy" in soil_l and temp <= 22:
        return "Wheat", "Rabi", "Compost + NPK (12:32:16)"
    elif "sandy" in soil_l:
        return "Millets (Bajra)", "Kharif / Summer", "Organic Compost & Neem Cake"
    elif "alluvial" in soil_l:
        return "Sugarcane", "Annual", "Nitrogen & Potash Rich Fertilizer"
    else:
        # Default fallback
        return "Maize", "All Seasons", "Organic Compost & NPK (20:20:20)"

@router.post("/recommend", response_model=CropRecommendationResponse)
def recommend_crop(req: CropRecommendationRequest, current_user: dict = Depends(get_current_user)):
    crop, season, fertilizer = recommend_crop_algorithm(
        req.temperature, req.humidity, req.rainfall, req.soil_type
    )
    
    recommendation_record = {
        "user_id": current_user["id"],
        "crop": crop,
        "season": season,
        "fertilizer": fertilizer,
        "temperature": req.temperature,
        "humidity": req.humidity,
        "rainfall": req.rainfall,
        "soil_type": req.soil_type,
        "created_at": datetime.utcnow().isoformat()
    }
    
    result = db["recommendations"].insert_one(recommendation_record)
    recommendation_record["id"] = str(result.inserted_id)
    
    return recommendation_record

@router.get("/history", response_model=List[CropRecommendationResponse])
def get_recommendation_history(current_user: dict = Depends(get_current_user)):
    cursor = db["recommendations"].find({"user_id": current_user["id"]}).sort("created_at", -1)
    history = []
    for doc in cursor:
        doc["id"] = str(doc["_id"])
        history.append(doc)
    return history
