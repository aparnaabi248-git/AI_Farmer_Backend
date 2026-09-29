from fastapi import APIRouter, Depends
from pydantic import BaseModel
from typing import List
from utils.auth_utils import get_current_user

router = APIRouter(prefix="/news", tags=["Agri News & Government Schemes"])

class NewsItem(BaseModel):
    id: str
    title: str
    category: str
    summary: str
    date: str
    tag: str
    link_url: str

NEWS_DATABASE = [
    {
        "id": "n1",
        "title": "PM-Kisan 19th Installment Released for 9.5 Crore Farmers",
        "category": "Govt Scheme",
        "summary": "Direct benefit transfer of ₹2,000 per farmer dispatched. Check your bank account status or Aadhaar registration on PM-Kisan portal.",
        "date": "Today",
        "tag": "PM-KISAN",
        "link_url": "https://pmkisan.gov.in"
    },
    {
        "id": "n2",
        "title": "Cabinet Approves Higher MSP for Wheat and Mustard Crops",
        "category": "MSP Update",
        "summary": "Minimum Support Price for Wheat increased by ₹150 to ₹2,425/quintal. Mustard MSP fixed at ₹5,950/quintal for upcoming procurement season.",
        "date": "Yesterday",
        "tag": "MSP 2026",
        "link_url": "https://agricoop.gov.in"
    },
    {
        "id": "n3",
        "title": "50% Subsidy Announced on Solar Agriculture Pumps (PM-KUSUM)",
        "category": "Subsidy",
        "summary": "Farmers can apply for standalone off-grid solar pumps up to 7.5 HP with 50% central subsidy and 30% state loan assistance.",
        "date": "2 Days Ago",
        "tag": "SOLAR PUMP",
        "link_url": "https://pmkusum.mnre.gov.in"
    },
    {
        "id": "n4",
        "title": "Weather Advisory: Early Spurt in Night Humidity across Northern Plains",
        "category": "Agronomy Alert",
        "summary": "High night moisture increases risk of Powdery Mildew in pulses and vegetables. Farmers advised to spray Sulfur 80% WP early morning.",
        "date": "Live Alert",
        "tag": "CROP ADVISORY",
        "link_url": ""
    },
    {
        "id": "n5",
        "title": "Kisan Credit Card (KCC) Limit Extended with 4% Interest Subvention",
        "category": "Credit & Finance",
        "summary": "Short-term crop loans up to ₹3 Lakh available at effective 4% interest per annum upon prompt repayment.",
        "date": "3 Days Ago",
        "tag": "KCC LOAN",
        "link_url": ""
    }
]

@router.get("/latest", response_model=List[NewsItem])
def get_latest_news(current_user: dict = Depends(get_current_user)):
    return [NewsItem(**item) for item in NEWS_DATABASE]
