import requests
import time
import os
from PIL import Image

BASE_URL = "http://127.0.0.1:8000"

def test_backend_e2e():
    print("==================================================")
    print("Starting AI Farmer Assistant Backend E2E Test Suite v2.0")
    print("==================================================")

    # 1. Test database connectivity
    print("\n[Step 1] Checking DB connectivity...")
    try:
        res = requests.get(f"{BASE_URL}/test-db")
        print(f"Status Code: {res.status_code}")
        print(f"Response: {res.json()}")
        assert res.status_code == 200, "Failed to connect to /test-db"
        assert "MongoDB Connected" in res.json().get("status", ""), "MongoDB not running/connected"
        print("DB Connectivity check: PASSED [OK]")
    except Exception as e:
        print(f"Error during DB connectivity check: {e}")
        return

    # Generate unique email for this run
    test_email = f"farmer_{int(time.time())}@example.com"
    test_password = "SecurePassword123"
    test_name = "Kishan Kumar"

    # 2. User Registration
    print("\n[Step 2] Testing User Registration (/auth/signup)...")
    signup_payload = {
        "name": test_name,
        "email": test_email,
        "password": test_password
    }
    res = requests.post(f"{BASE_URL}/auth/signup", json=signup_payload)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 201, f"Signup failed: {res.text}"
    token_data = res.json()
    assert "access_token" in token_data, "Token missing in response"
    token = token_data["access_token"]
    print("User Registration: PASSED [OK]")

    headers = {"Authorization": f"Bearer {token}"}

    # 3. User Login
    print("\n[Step 3] Testing User Login (/auth/login)...")
    login_payload = {
        "email": test_email,
        "password": test_password
    }
    res = requests.post(f"{BASE_URL}/auth/login", json=login_payload)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Login failed: {res.text}"
    assert "access_token" in res.json(), "Token missing in login response"
    print("User Login: PASSED [OK]")

    # 4. Fetch Profile details
    print("\n[Step 4] Testing Profile details (/auth/me)...")
    res = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Profile fetch failed: {res.text}"
    profile = res.json()
    print(f"Profile: {profile}")
    assert profile["email"] == test_email, "Email mismatch"
    assert profile["name"] == test_name, "Name mismatch"
    print("Profile Fetch: PASSED [OK]")

    # 5. Mandi Prices
    print("\n[Step 5] Testing Real-Time Mandi Prices (/mandi/prices)...")
    res = requests.get(f"{BASE_URL}/mandi/prices?search=Wheat", headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Mandi prices fetch failed: {res.text}"
    mandi_items = res.json()
    print(f"Wheat Mandi count: {len(mandi_items)}")
    assert len(mandi_items) >= 1, "Expected at least 1 Wheat Mandi record"
    assert "Wheat" in mandi_items[0]["commodity"], "Expected Wheat commodity"
    print("Mandi Prices: PASSED [OK]")

    # 6. Agri News & Subsidies
    print("\n[Step 6] Testing Agri News & Subsidies (/news/latest)...")
    res = requests.get(f"{BASE_URL}/news/latest", headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"News fetch failed: {res.text}"
    news = res.json()
    print(f"News count: {len(news)}")
    assert len(news) >= 3, "Expected at least 3 news articles"
    print("Agri News: PASSED [OK]")

    # 7. Fertilizer Dosage Calculator
    print("\n[Step 7] Testing Fertilizer Calculator (/calculator/fertilizer)...")
    fert_payload = {"crop": "Wheat", "acres": 2.0}
    res = requests.post(f"{BASE_URL}/calculator/fertilizer", json=fert_payload, headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Fertilizer calc failed: {res.text}"
    fert = res.json()
    print(f"Fertilizer Result: {fert}")
    assert fert["urea_bags_50kg"] > 0, "Expected urea bags calculation"
    print("Fertilizer Calculator: PASSED [OK]")

    # 8. Water Irrigation Calculator
    print("\n[Step 8] Testing Water Irrigation Calculator (/calculator/irrigation)...")
    irrig_payload = {"crop": "Tomato", "acres": 1.5, "soil_type": "Loamy", "current_temp": 32.0}
    res = requests.post(f"{BASE_URL}/calculator/irrigation", json=irrig_payload, headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Irrigation calc failed: {res.text}"
    irrig = res.json()
    print(f"Irrigation Result: {irrig}")
    assert irrig["water_req_liters_per_day"] > 0, "Expected water calculation"
    print("Water Irrigation Calculator: PASSED [OK]")

    # 9. Crop Recommendation
    print("\n[Step 9] Testing Crop Recommendation (/crops/recommend)...")
    crop_payload = {
        "temperature": 27.5,
        "humidity": 72.0,
        "rainfall": 95.0,
        "soil_type": "Black soil"
    }
    res = requests.post(f"{BASE_URL}/crops/recommend", json=crop_payload, headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Crop recommendation failed: {res.text}"
    recommendation = res.json()
    print(f"Recommendation: {recommendation}")
    assert recommendation["crop"] == "Cotton", "Expected Cotton crop recommendation"
    print("Crop Recommendation: PASSED [OK]")

    # 10. Weather Forecast
    print("\n[Step 10] Testing Weather Forecast (/weather)...")
    res = requests.get(f"{BASE_URL}/weather?city=Chennai", headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Weather forecast failed: {res.text}"
    weather = res.json()
    print(f"Weather: city={weather['city']}, temp={weather['temperature']}, condition={weather['condition']}")
    assert weather["city"] == "Chennai", "Expected city Chennai"
    print("Weather Forecast: PASSED [OK]")

    # 11. AgriBot Chat
    print("\n[Step 11] Testing AgriBot Chat (/bot/chat)...")
    chat_payload = {
        "message": "tell me about tomato early blight"
    }
    res = requests.post(f"{BASE_URL}/bot/chat", json=chat_payload, headers=headers)
    print(f"Status Code: {res.status_code}")
    assert res.status_code == 200, f"Chat failed: {res.text}"
    chat = res.json()
    print(f"Bot Response: {chat['bot_response']}")
    assert "Early Blight" in chat["bot_response"], "Expected early blight details"
    print("AgriBot Chat: PASSED [OK]")

    # 12. Plant Leaf Diagnosis (Image Upload)
    print("\n[Step 12] Testing Plant Leaf Diagnosis (/scans/analyze)...")
    dummy_img_path = "test_tomato_leaf.jpg"
    img = Image.new('RGB', (200, 200), color = (120, 180, 100))
    img.save(dummy_img_path)
    
    try:
        with open(dummy_img_path, 'rb') as f:
            files = {'file': (dummy_img_path, f, 'image/jpeg')}
            res = requests.post(f"{BASE_URL}/scans/analyze", files=files, headers=headers)
            
        print(f"Status Code: {res.status_code}")
        assert res.status_code == 200, f"Image upload / analysis failed: {res.text}"
        diagnosis = res.json()
        print(f"Diagnosis: {diagnosis}")
        assert "Tomato Early Blight" in diagnosis["disease"], "Expected early blight diagnosis"
        print("Plant Leaf Diagnosis (Upload & Analysis): PASSED [OK]")
    finally:
        if os.path.exists(dummy_img_path):
            os.remove(dummy_img_path)

    print("\n==================================================")
    print("ALL E2E TESTS PASSED SUCCESSFULLY! (12/12 Steps OK)")
    print("==================================================")

if __name__ == "__main__":
    test_backend_e2e()
