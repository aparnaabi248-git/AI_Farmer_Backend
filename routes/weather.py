import requests
from fastapi import APIRouter, Depends
from pydantic import BaseModel
from utils.auth_utils import get_current_user
from database import db
from datetime import datetime
from typing import List, Optional

router = APIRouter(prefix="/weather", tags=["Weather Forecast"])

class DailyForecastItem(BaseModel):
    day: str
    temp_max: float
    temp_min: float
    condition: str
    rain_probability: int

class WeatherAlertResponse(BaseModel):
    city: str
    temperature: float
    humidity: int
    wind_speed: float
    pressure: int
    visibility: int
    condition: str
    farming_advice: str
    spraying_window_safe: bool
    spraying_advice: str
    forecast: List[DailyForecastItem]
    created_at: str

CITY_COORDINATES = {
    "chennai": (13.0827, 80.2707),
    "mumbai": (19.0760, 72.8777),
    "delhi": (28.6139, 77.2090),
    "bengaluru": (12.9716, 77.5946),
    "hyderabad": (17.3850, 78.4867),
    "kolkata": (22.5726, 88.3639),
    "pune": (18.5204, 73.8567),
    "ahmedabad": (23.0225, 72.5714),
    "jaipur": (26.9124, 75.7873),
    "lucknow": (26.8467, 80.9462),
    "chandigarh": (30.7333, 76.7794)
}

def get_live_weather_openmeteo(city: str) -> Optional[dict]:
    city_key = city.strip().lower()
    lat, lon = CITY_COORDINATES.get(city_key, (None, None))
    
    if lat is None:
        try:
            geo_res = requests.get(
                f"https://geocoding-api.open-meteo.com/v1/search?name={city}&count=1",
                timeout=2.5
            )
            if geo_res.status_code == 200:
                results = geo_res.json().get("results", [])
                if results:
                    lat = results[0]["latitude"]
                    lon = results[0]["longitude"]
        except Exception:
            pass
            
    if lat is None:
        return None
        
    try:
        url = (
            f"https://api.open-meteo.com/v1/forecast?"
            f"latitude={lat}&longitude={lon}&current_weather=true&"
            f"hourly=relativehumidity_2m,surface_pressure,visibility,precipitation_probability&"
            f"daily=weathercode,temperature_2m_max,temperature_2m_min,precipitation_probability_max&"
            f"timezone=auto"
        )
        res = requests.get(url, timeout=3.0)
        if res.status_code == 200:
            return res.json()
    except Exception:
        pass
        
    return None

def code_to_condition(code: int) -> str:
    if code == 0:
        return "Sunny"
    elif code in [1, 2, 3]:
        return "Partly Cloudy"
    elif code in [45, 48]:
        return "Foggy"
    elif code in [51, 53, 55, 61, 63, 65]:
        return "Rain"
    elif code in [80, 81, 82]:
        return "Heavy Rain"
    elif code in [95, 96, 99]:
        return "Thunderstorm"
    else:
        return "Clear"

@router.get("", response_model=WeatherAlertResponse)
def get_weather_forecast(city: str = "Chennai", current_user: dict = Depends(get_current_user)):
    live_data = get_live_weather_openmeteo(city)
    
    if live_data and "current_weather" in live_data:
        curr = live_data["current_weather"]
        temp = float(curr.get("temperature", 30.0))
        wind = float(curr.get("windspeed", 12.0))
        w_code = int(curr.get("weathercode", 0))
        condition = code_to_condition(w_code)
        
        hourly = live_data.get("hourly", {})
        humidity_list = hourly.get("relativehumidity_2m", [65])
        humidity = int(humidity_list[0]) if humidity_list else 65
        pressure_list = hourly.get("surface_pressure", [1012])
        pressure = int(pressure_list[0]) if pressure_list else 1012
        visibility_list = hourly.get("visibility", [10000])
        visibility = int(visibility_list[0] / 1000) if visibility_list else 10
        
        daily = live_data.get("daily", {})
        time_list = daily.get("time", [])
        max_temps = daily.get("temperature_2m_max", [])
        min_temps = daily.get("temperature_2m_min", [])
        w_codes = daily.get("weathercode", [])
        rain_probs = daily.get("precipitation_probability_max", [])
        
        forecast = []
        days_label = ["Today", "Tomorrow", "Day 3", "Day 4", "Day 5"]
        for i in range(min(5, len(time_list))):
            forecast.append(DailyForecastItem(
                day=days_label[i] if i < len(days_label) else time_list[i],
                temp_max=float(max_temps[i]) if i < len(max_temps) else temp + 2,
                temp_min=float(min_temps[i]) if i < len(min_temps) else temp - 4,
                condition=code_to_condition(int(w_codes[i])) if i < len(w_codes) else "Clear",
                rain_probability=int(rain_probs[i]) if i < len(rain_probs) and rain_probs[i] is not None else 10
            ))
    else:
        # Fallback dataset
        city_lower = city.lower()
        if "chennai" in city_lower:
            temp, humidity, wind, condition = 32.5, 74, 14.2, "Sunny"
        elif "mumbai" in city_lower:
            temp, humidity, wind, condition = 28.0, 88, 22.0, "Heavy Rain"
        elif "delhi" in city_lower:
            temp, humidity, wind, condition = 38.5, 35, 10.5, "Dry Heat"
        elif "bengaluru" in city_lower:
            temp, humidity, wind, condition = 26.2, 60, 18.1, "Partly Cloudy"
        else:
            temp, humidity, wind, condition = 30.0, 65, 12.0, "Clear"
            
        pressure, visibility = 1012, 10
        forecast = [
            DailyForecastItem(day="Today", temp_max=temp+2, temp_min=temp-3, condition=condition, rain_probability=20),
            DailyForecastItem(day="Tomorrow", temp_max=temp+3, temp_min=temp-2, condition="Partly Cloudy", rain_probability=30),
            DailyForecastItem(day="Day 3", temp_max=temp+1, temp_min=temp-4, condition="Sunny", rain_probability=10),
            DailyForecastItem(day="Day 4", temp_max=temp, temp_min=temp-3, condition="Clear", rain_probability=5),
            DailyForecastItem(day="Day 5", temp_max=temp+4, temp_min=temp-1, condition="Sunny", rain_probability=15),
        ]

    # Compute agricultural advice and spraying window
    is_rainy = "rain" in condition.lower() or "thunder" in condition.lower()
    is_high_wind = wind > 20.0
    
    spraying_safe = not is_rainy and not is_high_wind
    if is_rainy:
        spray_advice = "Unsafe for pesticide/fertilizer spraying due to rain wash-off risk."
    elif is_high_wind:
        spray_advice = "Unsafe due to strong winds (>20 km/h) causing chemical drift."
    else:
        spray_advice = "Ideal spraying window! Low wind speed and clear sky."
        
    if is_rainy:
        advice = "Monsoon/Rain expected. Suspend pesticide spraying and ensure drainage channels are open to prevent root rot."
    elif temp > 36.0:
        advice = "High evaporation rate. Schedule shallow evening irrigation to prevent heat shock in young crops."
    elif humidity > 75:
        advice = "High atmospheric moisture. Inspect leaf undersides for early fungal rust or blight spots."
    else:
        advice = "Weather conditions are optimal for weeding, top-dress fertilizer application, and harvesting."

    weather_log = {
        "user_id": current_user["id"],
        "city": city,
        "temperature": temp,
        "humidity": humidity,
        "wind_speed": wind,
        "condition": condition,
        "farming_advice": advice,
        "created_at": datetime.utcnow().isoformat()
    }
    
    try:
        db["weather_history"].insert_one(weather_log)
    except Exception:
        pass
        
    return WeatherAlertResponse(
        city=city,
        temperature=temp,
        humidity=humidity,
        wind_speed=wind,
        pressure=pressure,
        visibility=visibility,
        condition=condition,
        farming_advice=advice,
        spraying_window_safe=spraying_safe,
        spraying_advice=spray_advice,
        forecast=forecast,
        created_at=weather_log["created_at"]
    )
