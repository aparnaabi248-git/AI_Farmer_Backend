import os
from pymongo import MongoClient
from dotenv import load_dotenv

load_dotenv()

MONGO_URL = os.getenv("MONGO_URL", "mongodb://localhost:27017/ai_farmer_db")

try:
    client = MongoClient(MONGO_URL, serverSelectionTimeoutMS=1500)
    # Try quick ping to confirm connection
    client.admin.command('ping')
    db_mode = "MongoDB Live Server"
except Exception:
    import mongomock
    client = mongomock.MongoClient()
    db_mode = "In-Memory Database Fallback"

db = client["ai_farmer_db"]
db.db_mode = db_mode