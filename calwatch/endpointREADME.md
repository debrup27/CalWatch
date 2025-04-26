# CalWatch Backend URLs

## Main URLs (backend/backend/urls.py)
- /admin/ - Django admin interface
- /image/ - Image API endpoints
- /data/ - Data API endpoints
- /auth/ - Authentication endpoints (Djoser)
- /token/ - JWT token obtain
- /token/refresh/ - JWT token refresh
- /users/ - User API endpoints
- /food/ - Food API endpoints

## Users URLs (backend/users/urls.py)
- /users/me/ - User detail endpoint
  - Response: `{"id": int, "username": string, "email": string, "first_name": string, "last_name": string, "profile": {"id": int, "bio": string, "profile_image": string, "date_joined": datetime}}`

- /users/profile/ - User profile endpoint
  - GET Response: `{"id": int, "bio": string, "profile_image": string, "date_joined": datetime}`
  - PUT/PATCH Request: `{"bio": string, "profile_image": file}`

- /users/userDetails/ - User details endpoint
  - GET Response: `{"id": int, "age": int, "height": float, "current_weight": float, "gender": string, "activity_level": string, "goal_weight": float}`
  - POST Request: `{"age": int, "height": float, "current_weight": float, "gender": string, "activity_level": string, "goal_weight": float}`
  - POST Response: `{"user_details": {"id": int, "age": int, "height": float, "current_weight": float, "gender": string, "activity_level": string, "goal_weight": float}, "daily_goals": {"id": int, "calories": float, "protein": float, "carbohydrates": float, "fat": float}}`
  - PATCH Request: `{"age": int, "height": float, "current_weight": float, "gender": string, "activity_level": string, "goal_weight": float}` (any subset of fields)

## Food URLs (backend/food/urls.py)
- /food/dailyGoal/ - Daily goal endpoint
  - GET Response: `{"id": int, "calories": float, "protein": float, "carbohydrates": float, "fat": float}`

- /food/waterIntake/ - Water intake endpoint
  - GET Response: `[{"id": int, "amount": float, "timestamp": datetime}, ...]`
  - POST Request: `{"amount": float}`
  - POST Response: `{"id": int, "amount": float, "timestamp": datetime}`

- /food/foodAutocomplete/ - Food autocomplete endpoint
  - GET Request Parameters: `?q=search_term`
  - GET Response: `{"results": [{"food_id": string, "food_name": string, ...}, ...]}`

- /food/getFood/ - Get food details endpoint
  - GET Request Parameters: `?id=food_id` or `?index=food_index`
  - GET Response: `{"food_id": string, "food_name": string, "nutrients": {"calories": float, "protein": float, "carbs": float, "fat": float, ...}}`
  - Error Response: `{"error": string}`

- /food/addFood/ - Add food consumption endpoint
  - POST Request: `{"food_id": string}` or `{"food_index": int}`
  - POST Response: `{"id": int, "food_index": int, "food_name": string, "calories": float, "protein": float, "carbohydrates": float, "fat": float, "timestamp": datetime}`

- /food/listFood/ - List food consumption by date range endpoint
  - GET Request Parameters: `?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`
  - GET Response: `[{"id": int, "food_index": int, "food_id": string, "food_name": string, "calories": float, "protein": float, "carbohydrates": float, "fat": float, "timestamp": datetime}, ...]`
  - Error Response: `{"detail": "Both start_date and end_date are required query parameters"}` or `{"detail": "Invalid date format. Use YYYY-MM-DD or YYYY-MM-DDThh:mm:ss format"}`

## Image API URLs (backend/image_api/urls.py)
- /image/upload/ - Image upload endpoint
  - POST Request: `{"image": file}`
  - POST Response: `{"id": int, "image": string, "image_url": string, "timestamp": datetime, "prediction": string, "prediction_id": string, "prediction_detail": {"class": string, "confidence": float, ...}}`

- /image/feedback/ - Prediction feedback endpoint
  - POST Request: `{"feedback_data": object}`
  - POST Response: Nutrition data based on feedback

- /image/my-images/ - User image list endpoint
  - GET Response: `[{"id": int, "image": string, "image_url": string, "timestamp": datetime, "prediction": string, "prediction_id": string}, ...]`

## Data API URLs (backend/data_api/urls.py)
- /data/submit/ - Data entry submission endpoint
  - POST Request: `{"protein": float, "carbs": float, "fat": float, "vitamins": float, "minerals": float}`
  - POST Response: `{"id": int, "user": int, "timestamp": datetime, "protein": float, "carbs": float, "fat": float, "vitamins": float, "minerals": float}`

- /data/list/ - Data entry list by date endpoint
  - GET Request Parameters: `?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD`
  - GET Response: `[{"id": int, "user": int, "timestamp": datetime, "protein": float, "carbs": float, "fat": float, "vitamins": float, "minerals": float}, ...]` 