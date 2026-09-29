from fastapi import APIRouter, Depends
from pydantic import BaseModel
from datetime import datetime
from database import db
from utils.auth_utils import get_current_user
from typing import List

router = APIRouter(prefix="/bot", tags=["AgriBot - AI Farm Assistant"])

class ChatMessageRequest(BaseModel):
    message: str

class ChatMessageResponse(BaseModel):
    id: str
    user_message: str
    bot_response: str
    created_at: str

def get_agribot_response(msg: str) -> str:
    msg_l = msg.lower()
    
    if "hello" in msg_l or "hi" in msg_l or "hey" in msg_l:
        return "Hello! I am AgriBot, your real-time AI farming assistant. 🌾 Ask me about Mandi prices, crop diseases, fertilizer NPK dosages, weather spraying windows, or government schemes like PM-Kisan!"
    elif "mandi" in msg_l or "price" in msg_l or "rate" in msg_l:
        return "📊 Live Mandi Market Highlights Today:\n• Wheat: ₹2,350/quintal (Khanna Mandi - UP ⬆️)\n• Rice (Basmati): ₹4,400/quintal (Karnal Mandi - UP ⬆️)\n• Cotton: ₹7,450/quintal (Rajkot Mandi - STABLE ➡️)\n• Tomato: ₹2,200/quintal (Kolar Mandi)\n• Onion: ₹2,500/quintal (Lasalgaon Mandi - UP ⬆️)\nCheck our 'Mandi Prices' section for full state-wise market breakdown!"
    elif "pm-kisan" in msg_l or "kisan" in msg_l or "scheme" in msg_l or "subsidy" in msg_l or "pm kisan" in msg_l:
        return "🏛️ Government Scheme Alert:\n• PM-Kisan 19th installment of ₹2,000 has been credited via direct DBT transfer.\n• PM-KUSUM Scheme provides 50% central subsidy on solar agriculture water pumps up to 7.5 HP.\n• Kisan Credit Card (KCC) offers crop loans up to ₹3 Lakh at an effective 4% interest rate."
    elif "tomato" in msg_l and ("blight" in msg_l or "disease" in msg_l or "spot" in msg_l):
        return "🍅 Tomato Early Blight Treatment:\nCaused by fungus Alternaria solani. Dark target-spot lesions appear on lower leaves.\n• Cure: Spray Mancozeb 75% WP (2.5g/L water) or Copper Oxychloride.\n• Prevention: Avoid overhead watering, prune lower yellowing foliage, and rotate crops every season."
    elif "potato" in msg_l and ("blight" in msg_l or "disease" in msg_l):
        return "🥔 Potato Late Blight Alert:\nFast-spreading fungal infection caused by Phytophthora infestans.\n• Remedy: Spray Cymoxanil + Mancozeb or Ridomil Gold at first sign.\n• Ensure proper earthing up of soil around tubers to prevent spore contamination."
    elif "fertilizer" in msg_l or "npk" in msg_l or "urea" in msg_l or "dap" in msg_l:
        return "🧪 Fertilizer NPK Guidance:\n• Rice & Wheat: Standard requirement per acre is ~50 kg N, 25 kg P, 20 kg K (~1.5 bags DAP, 1 bag MOP basal + 2 bags Urea top-dressed).\n• Leafy Vegetables: High Nitrogen for green vegetative growth.\n• Use our built-in 'Dosage & Water Calculator' to get precise bag calculations for your exact farm acreage!"
    elif "pest" in msg_l or "insect" in msg_l or "bug" in msg_l or "worm" in msg_l:
        return "🐛 Pest Control Recommendation:\n• Organic Spray: Mix 5ml Neem oil + 1ml liquid soap per Liter of warm water. Spray every 7-10 days.\n• Sucking Pests (Aphids/Whiteflies): Spray Imidacloprid 17.8% SL (0.5 ml/L).\n• Caterpillars/Borers: Apply Emamectin Benzoate 5% SG."
    elif "weather" in msg_l or "rain" in msg_l or "spray" in msg_l:
        return "🌤️ Real-Time Weather Spraying Tip:\nOnly spray when wind speed is under 15 km/h and rain probability is below 30% for the next 4 hours. Morning (7 AM - 10 AM) is the best time for maximum foliar absorption."
    elif "water" in msg_l or "irrigation" in msg_l:
        return "💧 Efficient Irrigation:\nDrip irrigation saves up to 50% water compared to flood irrigation. Water early morning to reduce surface evaporation. Use soil moisture sensors or clay checks."
    elif "thank" in msg_l or "thanks" in msg_l:
        return "You're very welcome! I'm always here 24/7 to help you achieve bountiful harvests. Happy farming! 🌾🚜"
    else:
        return "I am here to help with your farm! You can ask me about:\n1. Live Mandi Market Prices 📈\n2. PM-Kisan & Subsidy Details 🏛️\n3. Crop Disease Cures & Leaf Diagnosis 🌿\n4. Fertilizer & Water Calculation 💧\n5. Spraying Weather Conditions ☀️"

@router.post("/chat", response_model=ChatMessageResponse)
def chat_with_bot(req: ChatMessageRequest, current_user: dict = Depends(get_current_user)):
    bot_reply = get_agribot_response(req.message)
    
    chat_record = {
        "user_id": current_user["id"],
        "user_message": req.message,
        "bot_response": bot_reply,
        "created_at": datetime.utcnow().isoformat()
    }
    
    try:
        result = db["chats"].insert_one(chat_record)
        chat_record["id"] = str(result.inserted_id)
    except Exception:
        chat_record["id"] = "temp_id"
        
    return chat_record

@router.get("/history", response_model=List[ChatMessageResponse])
def get_chat_history(current_user: dict = Depends(get_current_user)):
    try:
        cursor = db["chats"].find({"user_id": current_user["id"]}).sort("created_at", 1)
        history = []
        for doc in cursor:
            doc["id"] = str(doc["_id"])
            history.append(doc)
        return history
    except Exception:
        return []
