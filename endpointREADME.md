- /food/addFood/ - Add food consumption endpoint

  - POST Request: `{"food_id": string}` or `{"food_index": int}`
    Optional fields: `{"calories": float, "protein": float, "carbohydrates": float, "fat": float}`
  - POST Response: `{"id": int, "food_index": int, "food_name": string, "calories": float, "protein": float, "carbohydrates": float, "fat": float, "timestamp": datetime}`

- /food/listFood/ - List food consumption by date range endpoint
