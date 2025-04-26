"""
Calculate daily caloric needs and macronutrient distribution for a user
based on their details (age, gender, weight, height, activity level, and goals).
"""

def calculate_bmr(gender, weight, height, age):
    """
    Calculate Basal Metabolic Rate (BMR) using the Mifflin-St Jeor equation
    
    Parameters:
    - gender: 'M' for male, 'F' for female
    - weight: in kilograms
    - height: in centimeters
    - age: in years
    
    Returns:
    - BMR: Basal Metabolic Rate in calories
    """
    if gender == 'M':
        bmr = 10 * weight + 6.25 * height - 5 * age + 5
    else:  # 'F'
        bmr = 10 * weight + 6.25 * height - 5 * age - 161
    
    return bmr

def calculate_tdee(bmr, activity_level):
    """
    Calculate Total Daily Energy Expenditure (TDEE) based on BMR and activity level
    
    Parameters:
    - bmr: Basal Metabolic Rate
    - activity_level: 'sedentary', 'medium', or 'high'
    
    Returns:
    - TDEE: Total Daily Energy Expenditure in calories
    """
    activity_multipliers = {
        'sedentary': 1.2,  # Little or no exercise
        'medium': 1.55,    # Moderate exercise (3-5 days/week)
        'high': 1.725      # Very active (6-7 days/week)
    }
    
    return bmr * activity_multipliers.get(activity_level, 1.2)

def calculate_goal_calories(tdee, current_weight, goal_weight):
    """
    Calculate goal calories based on weight goals
    
    Parameters:
    - tdee: Total Daily Energy Expenditure
    - current_weight: in kilograms
    - goal_weight: in kilograms
    
    Returns:
    - goal_calories: Adjusted caloric intake goal
    """
    weight_difference = goal_weight - current_weight
    
    # If goal weight is lower, create a deficit (about 500 calories/day for 1 pound/week)
    if weight_difference < 0:
        return max(tdee - 500, 1200)  # Don't go below 1200 calories
    # If goal weight is higher, create a surplus (about 300-500 calories/day)
    elif weight_difference > 0:
        return tdee + 300
    # If maintaining weight
    else:
        return tdee

def calculate_macros(goal_calories):
    """
    Calculate macronutrient distribution based on goal calories
    
    Parameters:
    - goal_calories: Daily caloric goal
    
    Returns:
    - macros: Dictionary with protein, carbs, and fat in grams
    """
    # Standard distribution: 30% protein, 40% carbs, 30% fat
    protein_calories = goal_calories * 0.3
    carbs_calories = goal_calories * 0.4
    fat_calories = goal_calories * 0.3
    
    # Convert calories to grams (4 cal/g for protein and carbs, 9 cal/g for fat)
    protein_grams = protein_calories / 4
    carbs_grams = carbs_calories / 4
    fat_grams = fat_calories / 9
    
    return {
        'protein': round(protein_grams, 1),
        'carbohydrates': round(carbs_grams, 1),
        'fat': round(fat_grams, 1)
    }

def calculate_daily_goals(gender, age, weight, height, activity_level, goal_weight):
    """
    Calculate daily caloric and macronutrient goals
    
    Parameters:
    - gender: 'M' for male, 'F' for female
    - age: in years
    - weight: current weight in kilograms
    - height: in centimeters
    - activity_level: 'sedentary', 'medium', or 'high'
    - goal_weight: target weight in kilograms
    
    Returns:
    - daily_goals: Dictionary with calories and macronutrients
    """
    bmr = calculate_bmr(gender, weight, height, age)
    tdee = calculate_tdee(bmr, activity_level)
    goal_calories = calculate_goal_calories(tdee, weight, goal_weight)
    macros = calculate_macros(goal_calories)
    
    return {
        'calories': round(goal_calories),
        'protein': macros['protein'],
        'carbohydrates': macros['carbohydrates'],
        'fat': macros['fat']
    } 