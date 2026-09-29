from pydantic import BaseModel
from typing import Optional, List

class PlantScanResponse(BaseModel):
    id: Optional[str] = None
    disease: str
    confidence: str
    pest: str
    medicine: str
    prevention: str
    image_url: str
    created_at: str
