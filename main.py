import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from database import db

# Import routers
from routes import auth, crops, scans, weather, bot, mandi, news, calculator

app = FastAPI(
    title="AI Farmer Assistant API",
    description="Backend services for disease detection, crop recommendations, weather alerts, mandi rates, news & chatbot.",
    version="2.0.0"
)

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Create uploads directory if not exists and mount static files route
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

# Include routers
app.include_router(auth.router)
app.include_router(crops.router)
app.include_router(scans.router)
app.include_router(weather.router)
app.include_router(bot.router)
app.include_router(mandi.router)
app.include_router(news.router)
app.include_router(calculator.router)

@app.get("/")
def home():
    return {
        "message": "AI Farmer Assistant Backend v2.0 is running successfully 🚀",
        "api_docs": "/docs"
    }

@app.get("/test-db")
def test_db():
    try:
        collections = db.list_collection_names()
        mode = getattr(db, "db_mode", "MongoDB Connected")
        return {
            "status": f"MongoDB Connected ✅ ({mode})",
            "database_name": db.name,
            "collections": collections
        }
    except Exception as e:
        return {
            "status": "MongoDB Connection Failed ❌",
            "error": str(e)
        }