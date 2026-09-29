from fastapi import APIRouter, Depends
from pydantic import BaseModel
from utils.auth_utils import get_current_user

router = APIRouter(prefix="/calculator", tags=["Agri Dosage & Irrigation Calculator"])

class FertilizerReq(BaseModel):
    crop: str
    acres: float
    target_yield_ton: float = 2.0

class FertilizerRes(BaseModel):
    crop: str
    acres: float
    nitrogen_kg: float
    phosphorus_kg: float
    potassium_kg: float
    urea_bags_50kg: float
    dap_bags_50kg: float
    mop_bags_50kg: float
    recommendation: str

class IrrigationReq(BaseModel):
    crop: str
    acres: float
    soil_type: str
    current_temp: float = 30.0

class IrrigationRes(BaseModel):
    crop: str
    acres: float
    water_req_liters_per_day: float
    irrigation_duration_hours: float
    irrigation_method: str
    schedule_advice: str

@router.post("/fertilizer", response_model=FertilizerRes)
def calculate_fertilizer(req: FertilizerReq, current_user: dict = Depends(get_current_user)):
    crop_lower = req.crop.lower()
    acres = max(0.1, req.acres)
    
    # NPK per acre standards (kg/acre)
    if "wheat" in crop_lower:
        base_n, base_p, base_k = 50.0, 25.0, 20.0
    elif "rice" in crop_lower or "paddy" in crop_lower:
        base_n, base_p, base_k = 48.0, 24.0, 24.0
    elif "cotton" in crop_lower:
        base_n, base_p, base_k = 60.0, 30.0, 30.0
    elif "tomato" in crop_lower:
        base_n, base_p, base_k = 55.0, 35.0, 40.0
    elif "potato" in crop_lower:
        base_n, base_p, base_k = 70.0, 40.0, 50.0
    elif "corn" in crop_lower or "maize" in crop_lower:
        base_n, base_p, base_k = 50.0, 25.0, 25.0
    else:
        base_n, base_p, base_k = 45.0, 22.0, 22.0
        
    tot_n = round(base_n * acres, 1)
    tot_p = round(base_p * acres, 1)
    tot_k = round(base_k * acres, 1)
    
    # Convert NPK to standard commercial fertilizer bags (50kg each)
    # DAP provides 18% N, 46% P
    # Urea provides 46% N
    # MOP provides 60% K
    dap_bags = round((tot_p / 0.46) / 50.0, 1)
    n_from_dap = (dap_bags * 50) * 0.18
    rem_n = max(0.0, tot_n - n_from_dap)
    urea_bags = round((rem_n / 0.46) / 50.0, 1)
    mop_bags = round((tot_k / 0.60) / 50.0, 1)
    
    advice = (
        f"Apply 100% DAP ({dap_bags} bags) and MOP ({mop_bags} bags) as basal dose during sowing. "
        f"Split Urea ({urea_bags} bags) into 2-3 equal top dressings at 25 and 45 days after sowing."
    )
    
    return FertilizerRes(
        crop=req.crop,
        acres=acres,
        nitrogen_kg=tot_n,
        phosphorus_kg=tot_p,
        potassium_kg=tot_k,
        urea_bags_50kg=urea_bags,
        dap_bags_50kg=dap_bags,
        mop_bags_50kg=mop_bags,
        recommendation=advice
    )

@router.post("/irrigation", response_model=IrrigationRes)
def calculate_irrigation(req: IrrigationReq, current_user: dict = Depends(get_current_user)):
    acres = max(0.1, req.acres)
    crop_lower = req.crop.lower()
    temp = req.current_temp
    
    # Base water requirement in Liters per acre per day
    base_l = 18000.0 if "rice" in crop_lower else 10000.0
    if temp > 35:
        base_l *= 1.25  # 25% extra due to heat evaporation
        
    if "clay" in req.soil_type.lower():
        base_l *= 0.9  # Clay holds moisture better
    elif "sandy" in req.soil_type.lower():
        base_l *= 1.15 # Sandy soil loses water faster
        
    tot_liters = round(base_l * acres, 0)
    
    # Assuming standard 5 HP drip/pump motor flow rate (~15,000 L/hour)
    duration = round(tot_liters / 15000.0, 1)
    
    method = "Drip / Micro-Irrigation" if "tomato" in crop_lower or "cotton" in crop_lower else "Border Strip / Drip Irrigation"
    schedule = "Irrigate early in the morning (6:00 AM - 9:00 AM) or late evening to minimize evaporation losses."
    
    return IrrigationRes(
        crop=req.crop,
        acres=acres,
        water_req_liters_per_day=tot_liters,
        irrigation_duration_hours=duration,
        irrigation_method=method,
        schedule_advice=schedule
    )
