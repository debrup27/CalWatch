"""
Functions to handle food data from the CSV file
"""
import csv
import os
from pathlib import Path

# Get the absolute path to the food_details.csv file
BASE_DIR = Path(__file__).resolve().parent.parent
FOOD_CSV_PATH = os.path.join(BASE_DIR, 'food', 'food_details.csv')

def search_food(query, limit=10):
    """
    Search for foods containing the query string in their name
    
    Parameters:
    - query: The search string
    - limit: Maximum number of results to return
    
    Returns:
    - List of food items with their indices
    """
    results = []
    
    try:
        with open(FOOD_CSV_PATH, 'r', encoding='utf-8') as csv_file:
            reader = csv.reader(csv_file)
            # Skip header row
            next(reader)
            
            for i, row in enumerate(reader, 1):  # Start from 1 to match row numbers
                if len(row) > 1 and query.lower() in row[1].lower():  # food_name is in index 1
                    results.append({
                        'id': row[0],  # food_code
                        'name': row[1],  # food_name
                        'index': i
                    })
                    
                    if len(results) >= limit:
                        break
    except Exception as e:
        print(f"Error searching food data: {e}")
        
    return results

def get_food_by_index(index):
    """
    Get food details by its index in the CSV file
    
    Parameters:
    - index: Index of the food in the CSV (1-based, accounting for header)
    
    Returns:
    - Dictionary of food details or None if not found
    """
    try:
        with open(FOOD_CSV_PATH, 'r', encoding='utf-8') as csv_file:
            reader = csv.reader(csv_file)
            header = next(reader)
            
            for i, row in enumerate(reader, 1):  # Start from 1 to match row numbers
                if i == index and len(row) > 0:
                    # Create a dictionary with header keys and row values
                    food_data = {
                        header[j]: value for j, value in enumerate(row) if j < len(header)
                    }
                    
                    # Add nutritional information in a structured format
                    nutrients = {
                        'calories': food_data.get('energy_kcal', '0'),
                        'carbs': food_data.get('carb_g', '0'),
                        'protein': food_data.get('protein_g', '0'),
                        'fat': food_data.get('fat_g', '0'),
                        'fiber': food_data.get('fibre_g', '0'),
                        'sugar': food_data.get('freesugar_g', '0'),
                        'calcium': food_data.get('calcium_mg', '0'),
                        'iron': food_data.get('iron_mg', '0'),
                        'sodium': food_data.get('sodium_mg', '0'),
                        'vitaminC': food_data.get('vitc_mg', '0'),
                        'servingSize': food_data.get('servings_unit', 'serving')
                    }
                    
                    food_data['nutrients'] = nutrients
                    return food_data
                    
        return None
    except Exception as e:
        print(f"Error getting food by index: {e}")
        return None

def get_food_by_id(food_id):
    """
    Get food details by its food_code
    
    Parameters:
    - food_id: The food_code to search for
    
    Returns:
    - Dictionary of food details or None if not found
    """
    try:
        with open(FOOD_CSV_PATH, 'r', encoding='utf-8') as csv_file:
            reader = csv.reader(csv_file)
            header = next(reader)
            
            for row in reader:
                if len(row) > 0 and row[0] == food_id:
                    # Create a dictionary with header keys and row values
                    food_data = {
                        header[j]: value for j, value in enumerate(row) if j < len(header)
                    }
                    
                    # Add nutritional information in a structured format
                    nutrients = {
                        'calories': food_data.get('energy_kcal', '0'),
                        'carbs': food_data.get('carb_g', '0'),
                        'protein': food_data.get('protein_g', '0'),
                        'fat': food_data.get('fat_g', '0'),
                        'fiber': food_data.get('fibre_g', '0'),
                        'sugar': food_data.get('freesugar_g', '0'),
                        'calcium': food_data.get('calcium_mg', '0'),
                        'iron': food_data.get('iron_mg', '0'),
                        'sodium': food_data.get('sodium_mg', '0'),
                        'vitaminC': food_data.get('vitc_mg', '0'),
                        'servingSize': food_data.get('servings_unit', 'serving')
                    }
                    
                    food_data['nutrients'] = nutrients
                    return food_data
                    
        return None
    except Exception as e:
        print(f"Error getting food by ID: {e}")
        return None 