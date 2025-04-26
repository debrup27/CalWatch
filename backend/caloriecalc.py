def calculate_bmr(weight_kg, height_cm, age, gender='male'):
    # Mifflin-St Jeor Equation
    if gender == 'male':
        return 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
    else:
        return 10 * weight_kg + 6.25 * height_cm - 5 * age - 161

def get_activity_multiplier(activity_level):
    level = activity_level.lower()
    return {
        'sedentary': 1.2,
        'moderate': 1.55,
        'high': 1.725
    }.get(level, 1.2)  # default to sedentary

def calculate_calorie_goal(current_weight, goal_weight, bmr, activity_multiplier):
    # Adjust based on weight goal
    calorie_needs = bmr * activity_multiplier
    if goal_weight < current_weight:
        calorie_needs -= 500  # roughly 0.5 kg loss per week
    elif goal_weight > current_weight:
        calorie_needs += 300  # slight surplus for muscle gain
    return calorie_needs

def calculate_macros(calories):
    # Macro distribution: 40% carbs, 30% protein, 30% fat
    protein_cal = 0.3 * calories
    carb_cal = 0.4 * calories
    fat_cal = 0.3 * calories

    protein_grams = protein_cal / 4  # 4 kcal/g
    carb_grams = carb_cal / 4       # 4 kcal/g
    fat_grams = fat_cal / 9         # 9 kcal/g

    return round(protein_grams), round(carb_grams), round(fat_grams)

def main():
    print("Enter your details below:")
    weight = float(input("Current weight (kg): "))
    height = float(input("Height (cm): "))
    age = int(input("Age (years): "))
    gender = input("Gender (male/female): ").strip().lower()
    activity_level = input("Activity level (sedentary, moderate, high): ").strip().lower()
    goal_weight = float(input("Goal weight (kg): "))

    bmr = calculate_bmr(weight, height, age, gender)
    multiplier = get_activity_multiplier(activity_level)
    calorie_goal = calculate_calorie_goal(weight, goal_weight, bmr, multiplier)
    protein, carbs, fat = calculate_macros(calorie_goal)

    print("\nYour Daily Goals:")
    print(f"Calories: {round(calorie_goal)} kcal")
    print(f"Protein: {protein} g")
    print(f"Carbohydrates: {carbs} g")
    print(f"Fat: {fat} g")

if __name__ == "__main__":
    main()

