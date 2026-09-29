from pydantic import BaseModel
from typing import Optional

class CropRecommendationRequest(BaseModel):
    temperature: float
    humidity: float
    rainfall: float
    soil_type: str

class CropRecommendationResponse(BaseModel):
    id: Optional[str] = None
    crop: str
    season: str
    fertilizer: str
    temperature: float
    humidity: float
    rainfall: float
    soil_type: str
    created_at: str
