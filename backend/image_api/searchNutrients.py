import csv
import json

def get_row_as_json(search_value, csv_file_path=r"backend\image_api\nutrient_values.csv",search_column="dish_name"):
    try:
        with open(csv_file_path, 'r', newline='', encoding='utf-8') as file:
            reader = csv.DictReader(file)
            
            # Check if the search column exists in the CSV headers
            if search_column not in reader.fieldnames:
                return None
            
            # Search for the row
            for row in reader:
                if row[search_column] == search_value:
                    return row
            
            # If no matching row is found
            return None
                
    except Exception as e:
        print(f"Error: {e}")
        return None

# Example usage:
# result = get_row_as_json('data.csv', 'name', 'John')
# json_string = json.dumps(result, indent=4)  # Convert to JSON string if needed