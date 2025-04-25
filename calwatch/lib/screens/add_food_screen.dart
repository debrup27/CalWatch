import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
import '../services/api_service.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({Key? key}) : super(key: key);

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  String _selectedMealType = 'Breakfast';
  bool _isLoading = false;
  bool _isSearching = false;
  
  // Timer for debouncing search
  Timer? _debounce;
  
  // Food search results
  List<Map<String, dynamic>> _searchResults = [];
  
  // Selected food details
  Map<String, dynamic>? _selectedFood;
  
  // Store the selected food ID or index
  String? _selectedFoodId;
  int? _selectedFoodIndex;
  
  // Recent food entries (will be fetched from API in a real implementation)
  List<Map<String, dynamic>> _recentFoods = [];

  // Meal type options
  final List<String> _mealTypes = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snack',
    'Water'
  ];
  
  @override
  void initState() {
    super.initState();
    _loadRecentFoods();
    
    // Add listener for search input
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  // Load recent foods
  Future<void> _loadRecentFoods() async {
    // In a real implementation, this would fetch from the API
    setState(() {
      _recentFoods = [
        {'name': 'Apple', 'meal': 'Snack', 'icon': Icons.apple, 'id': 'sample1'},
        {'name': 'Coffee', 'meal': 'Breakfast', 'icon': Icons.coffee, 'id': 'sample2'},
        {'name': 'Chicken Salad', 'meal': 'Lunch', 'icon': Icons.lunch_dining, 'id': 'sample3'},
        {'name': 'Water', 'meal': 'Water', 'icon': Icons.water_drop, 'id': 'sample4'},
        {'name': 'Pasta', 'meal': 'Dinner', 'icon': Icons.dinner_dining, 'id': 'sample5'},
      ];
    });
  }

  // Debounced search implementation
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchFoods(_searchController.text);
    });
  }
  
  // Search foods with API
  Future<void> _searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final apiService = ApiService();
      final results = await apiService.getFoodAutocomplete(query);
      
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching foods: $e');
      setState(() {
        _isSearching = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error searching foods: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Get food details and store food ID
  Future<void> _getFoodDetails(String foodId, {int? foodIndex}) async {
    // Store the ID or index for later use
    setState(() {
      _selectedFoodId = foodId;
      _selectedFoodIndex = foodIndex;
      _isLoading = true;
    });
    
    try {
      final apiService = ApiService();
      // Get the nutritional information
      final foodDetails = await apiService.getFoodDetails(foodId);
      
      setState(() {
        // Only store the nutritional data and name, not the ID
        _selectedFood = {
          'food_name': foodDetails['food_name'] ?? 'Unknown Food',
          'nutrients': foodDetails['nutrients'] ?? {},
        };
        _searchController.text = foodDetails['food_name'] ?? '';
        _searchResults = []; // Clear search results
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting food details: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error getting food details: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // Select food from search results
  void _selectFood(Map<String, dynamic> food) {
    // Store the ID or index if available
    if (food.containsKey('food_id')) {
      _selectedFoodId = food['food_id'].toString();
      _selectedFoodIndex = null;
    } else if (food.containsKey('id')) {
      _selectedFoodId = food['id'].toString();
      _selectedFoodIndex = null;
    } else if (food.containsKey('food_index')) {
      _selectedFoodId = null;
      _selectedFoodIndex = food['food_index'] as int;
    } else if (food.containsKey('index')) {
      _selectedFoodId = null;
      _selectedFoodIndex = food['index'] as int;
    }
    
    // Get the details
    if (_selectedFoodId != null) {
      _getFoodDetails(_selectedFoodId!);
    } else if (_selectedFoodIndex != null) {
      // Get details using index
      _getFoodDetails('', foodIndex: _selectedFoodIndex);
    } else {
      // No ID or index available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not identify the selected food',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Add food entry
  Future<void> _addFoodEntry() async {
    if (_selectedFood == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select a food item first',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Validate that we have either ID or index
    if (_selectedFoodId == null && _selectedFoodIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid food selection. Please try selecting a different food.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final apiService = ApiService();
      
      // Use either ID or index to add the food
      final result = await apiService.addFoodConsumption(
        foodId: _selectedFoodId,
        foodIndex: _selectedFoodIndex,
      );
      
      setState(() {
        _isLoading = false;
        _selectedFood = null;
        _selectedFoodId = null;
        _selectedFoodIndex = null;
        _searchController.text = '';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Food added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error adding food: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error adding food: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Food Entry',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.green))
        : SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFoodSearchForm(),
                  
                  if (_selectedFood != null) ...[
                    const SizedBox(height: 20),
                    _buildSelectedFoodDetails(),
                  ],
                  
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildSearchResults(),
                  ],
                  
                  const SizedBox(height: 20),
                  _buildRecentFoodsList(),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildFoodSearchForm() {
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.withOpacity(0.2),
                  Colors.grey.shade900.withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Search Food',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Food Name',
                    labelStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                    hintText: 'Search for a food item...',
                    hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[700]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                    filled: true,
                    fillColor: Colors.grey[800]!.withOpacity(0.5),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _isSearching 
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(
                            color: Colors.green,
                            strokeWidth: 2,
                          ),
                        )
                      : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                  ),
                ),
                
                if (_selectedFood != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Meal Type',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _mealTypes.length,
                      itemBuilder: (context, index) {
                        final mealType = _mealTypes[index];
                        final isSelected = _selectedMealType == mealType;
                        
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ChoiceChip(
                            label: Text(
                              mealType,
                              style: GoogleFonts.poppins(
                                color: isSelected ? Colors.white : Colors.grey[400],
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: Colors.green,
                            backgroundColor: Colors.grey[800],
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedMealType = mealType;
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addFoodEntry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Add Food Entry',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectedFoodDetails() {
    final nutrients = _selectedFood!['nutrients'];
    
    return Card(
      color: Colors.grey[900],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Food Details',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedFood = null;
                      _searchController.text = '';
                    });
                  },
                ),
              ],
            ),
            
            const Divider(color: Colors.grey),
            
            Text(
              _selectedFood!['food_name'] ?? 'Unknown Food',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Nutrition info
            if (nutrients != null) ...[
              _buildNutrientRow('Calories', '${nutrients['calories'] ?? 0} kcal', Colors.orange),
              const SizedBox(height: 10),
              _buildNutrientRow('Protein', '${nutrients['protein'] ?? 0} g', Colors.red),
              const SizedBox(height: 10),
              _buildNutrientRow('Carbs', '${nutrients['carbs'] ?? 0} g', Colors.blue),
              const SizedBox(height: 10),
              _buildNutrientRow('Fat', '${nutrients['fat'] ?? 0} g', Colors.yellow),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildNutrientRow(String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.grey[300],
            fontSize: 16,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Search Results',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _searchResults.length,
            itemBuilder: (context, index) {
              final food = _searchResults[index];
              return ListTile(
                title: Text(
                  food['name'] ?? food['food_name'] ?? 'Unknown Food',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
                onTap: () {
                  _selectFood(food);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentFoodsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Foods',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _recentFoods.length,
          itemBuilder: (context, index) {
            final food = _recentFoods[index];
            return Card(
              color: Colors.grey[850],
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(
                  food['name'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  food['meal'] as String,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                  ),
                ),
                leading: CircleAvatar(
                  backgroundColor: food['meal'] == 'Water' ? Colors.blue : Colors.orange,
                  child: Icon(
                    food['icon'] as IconData,
                    color: Colors.white,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () {
                    // Select food and get details
                    _selectFood(food);
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
} 