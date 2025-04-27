import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:async';
import '../services/api_service.dart';
import 'dart:math' as math;

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

  // Editable nutrition values
  double? _editedCalories;
  double? _editedProtein;
  double? _editedCarbs;
  double? _editedFat;
  
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
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ApiService();
      final foods = await apiService.getFoodList(limit: 10);
      
      setState(() {
        _recentFoods = foods;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recent foods: $e');
      setState(() {
        _recentFoods = [];
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error loading recent foods: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      Map<String, dynamic> foodDetails;
      
      if (foodIndex != null) {
        print('Getting food details with index: $foodIndex');
        final dummyFood = {'food_index': foodIndex};
        foodDetails = await apiService.getFoodDetailsWithIndexFallback(dummyFood);
      } else {
        print('Getting food details with ID: $foodId');
        foodDetails = await apiService.getFoodDetails(foodId);
      }
      
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
    print('Selected food: $food');
    if (food.containsKey('food_id') && food['food_id'] != null && (food['food_id'].toString().contains("ASC") || food['food_id'].toString().contains("BFP") || food['food_id'].toString().contains("OSR"))) {
      _selectedFoodId = food['food_id'].toString();
      _selectedFoodIndex = null;
    } else if (food.containsKey('id') && food['id'] != null && (food['id'].toString().contains("ASC") || food['id'].toString().contains("BFP") || food['id'].toString().contains("OSR"))) {
      _selectedFoodId = food['id'].toString();
      _selectedFoodIndex = null;
    } else if (food.containsKey('food_index') && food['food_index'] != null) {
      _selectedFoodId = null;
      _selectedFoodIndex = food['food_index'] as int;
    } else if (food.containsKey('index') && food['index'] != null) {
      _selectedFoodId = null;
      _selectedFoodIndex = food['index'] as int;
    }

    print('Selected food ID: $_selectedFoodId');
    print('Selected food Index: $_selectedFoodIndex');
    
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
      
      // Use either ID or index to add the food, including any edited values
      final result = await apiService.addFoodConsumption(
        foodId: _selectedFoodId,
        foodIndex: _selectedFoodIndex,
        calories: _editedCalories,
        protein: _editedProtein,
        carbohydrates: _editedCarbs,
        fat: _editedFat,
      );
      
      setState(() {
        _isLoading = false;
        _selectedFood = null;
        _selectedFoodId = null;
        _selectedFoodIndex = null;
        _searchController.text = '';
        // Reset edited values
        _editedCalories = null;
        _editedProtein = null;
        _editedCarbs = null;
        _editedFat = null;
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

  // Add a method to show the nutrition value editor
  void _showNutritionEditor(String nutrient, double currentValue, Function(double) onSaved) {
    final controller = TextEditingController(text: currentValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          'Edit $nutrient',
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter custom value:',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Value',
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
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey[400]),
            ),
          ),
          TextButton(
            onPressed: () {
              // Try to parse the value
              try {
                final value = double.parse(controller.text);
                onSaved(value);
                Navigator.of(context).pop();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Please enter a valid number',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              'Save',
              style: GoogleFonts.poppins(color: Colors.green),
            ),
          ),
        ],
      ),
    );
  }

  // Add a debug method to show which nutrient is being edited
  void _onEditNutrient(String nutrient, double currentValue, Function(double) onSaved) {
    print('Edit button tapped for $nutrient with value $currentValue');
    _showNutritionEditor(nutrient, currentValue, onSaved);
  }

  // Add a method to safely parse numeric values
  double _parseNutrientValue(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing nutrient value: $e');
        return 0.0;
      }
    }
    return 0.0;
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
      body: Stack(
        children: [
          // Nebula effect background
          ..._buildNebulaBackground(),
          
          // Main content
          _isLoading
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
                    
                    if (_searchResults.isNotEmpty && _selectedFood == null) ...[
                      const SizedBox(height: 20),
                      _buildSearchResults(),
                    ],
                    
              const SizedBox(height: 20),
              _buildRecentFoodsList(),
                    
                    // Add motivational message if no food selected and no search results
                    if (_selectedFood == null && _searchResults.isEmpty)
                      _buildMotivationalMessage(),
            ],
          ),
        ),
      ),
        ],
      ),
    );
  }

  // Create nebula background
  List<Widget> _buildNebulaBackground() {
    final Size size = MediaQuery.of(context).size;
    final List<Widget> nebulaElements = [];
    
    // Background color
    nebulaElements.add(
      Container(
        width: size.width,
        height: size.height,
        color: Colors.black,
      ),
    );
    
    // Nebula clouds
    for (int i = 0; i < 15; i++) {
      final random = math.Random(i);
      final xCenter = random.nextDouble() * size.width;
      final yCenter = random.nextDouble() * size.height;
      final radius = size.width * (0.1 + 0.15 * random.nextDouble());
      
      // Use multiple overlapping gradients for a richer effect
      final hue = (220 + 80 * random.nextDouble()) % 360;
      
      nebulaElements.add(
        Positioned(
          left: xCenter - radius,
          top: yCenter - radius,
          child: Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  HSLColor.fromAHSL(0.3, hue, 0.8, 0.5).toColor(),
                  Colors.transparent,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      );
    }
    
    // Stars
    for (int i = 0; i < 100; i++) {
      final random = math.Random(i + 20);
      final size = random.nextDouble() * 2;
      
      nebulaElements.add(
        Positioned(
          left: random.nextDouble() * MediaQuery.of(context).size.width,
          top: random.nextDouble() * MediaQuery.of(context).size.height,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(random.nextDouble() * 0.5 + 0.5),
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    
    return nebulaElements;
  }
  
  // Build motivational message
  Widget _buildMotivationalMessage() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 40),
      padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.purpleAccent.withOpacity(0.3),
          width: 1,
        ),
          boxShadow: [
            BoxShadow(
            color: Colors.purpleAccent.withOpacity(0.1),
            blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
      child: Column(
        children: [
          const Icon(
            Icons.restaurant_menu,
            color: Colors.green,
            size: 50,
          ),
          const SizedBox(height: 20),
          Text(
            "Your Nutrition Journey Awaits",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Search for foods to add to your daily log and track your progress toward a healthier you.",
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodSearchForm() {
    return Card(
      color: Colors.transparent,
      elevation: 0,
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
                  Colors.purpleAccent.withOpacity(0.1),
                  Colors.grey.shade900.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
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
                        borderSide: BorderSide(color: Colors.purpleAccent.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Colors.green),
                      ),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
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
                            backgroundColor: Colors.black.withOpacity(0.3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: BorderSide(
                                color: isSelected ? Colors.green : Colors.purpleAccent.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
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
      color: Colors.transparent,
      elevation: 0,
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
                  Colors.purpleAccent.withOpacity(0.1),
                  Colors.grey.shade900.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.purpleAccent.withOpacity(0.3), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
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
                          _searchResults = []; // Clear search results immediately
                          // Reset edited values
                          _editedCalories = null;
                          _editedProtein = null;
                          _editedCarbs = null;
                          _editedFat = null;
                        });
                      },
                    ),
                  ],
                ),
                
                Divider(color: Colors.purpleAccent.withOpacity(0.3)),
                
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
                  _buildNutrientRow(
                    'Calories', 
                    _editedCalories != null 
                      ? '${_editedCalories!} kcal (edited)'
                      : '${_parseNutrientValue(nutrients['calories'])} kcal', 
                    Colors.orange,
                    () => _onEditNutrient(
                      'Calories',
                      _editedCalories ?? _parseNutrientValue(nutrients['calories']),
                      (value) => setState(() => _editedCalories = value)
                    ),
                    isEdited: _editedCalories != null
                  ),
                  const SizedBox(height: 10),
                  _buildNutrientRow(
                    'Protein', 
                    _editedProtein != null 
                      ? '${_editedProtein!} g (edited)' 
                      : '${_parseNutrientValue(nutrients['protein'])} g', 
                    Colors.red,
                    () => _onEditNutrient(
                      'Protein',
                      _editedProtein ?? _parseNutrientValue(nutrients['protein']),
                      (value) => setState(() => _editedProtein = value)
                    ),
                    isEdited: _editedProtein != null
                  ),
                  const SizedBox(height: 10),
                  _buildNutrientRow(
                    'Carbs', 
                    _editedCarbs != null 
                      ? '${_editedCarbs!} g (edited)' 
                      : '${_parseNutrientValue(nutrients['carbs'])} g', 
                    Colors.blue,
                    () => _onEditNutrient(
                      'Carbs',
                      _editedCarbs ?? _parseNutrientValue(nutrients['carbs']),
                      (value) => setState(() => _editedCarbs = value)
                    ),
                    isEdited: _editedCarbs != null
                  ),
                  const SizedBox(height: 10),
                  _buildNutrientRow(
                    'Fat', 
                    _editedFat != null 
                      ? '${_editedFat!} g (edited)' 
                      : '${_parseNutrientValue(nutrients['fat'])} g', 
                    Colors.yellow,
                    () => _onEditNutrient(
                      'Fat',
                      _editedFat ?? _parseNutrientValue(nutrients['fat']),
                      (value) => setState(() => _editedFat = value)
                    ),
                    isEdited: _editedFat != null
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Tap the edit buttons to customize nutrition values',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
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
  
  Widget _buildNutrientRow(String label, String value, Color color, VoidCallback onTap, {bool isEdited = false}) {
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
            color: isEdited ? Colors.green : Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        // Separate edit button with Material for proper touch feedback
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.edit,
                color: isEdited ? Colors.green : Colors.grey[400],
                size: 20,
              ),
            ),
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
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.purpleAccent.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purpleAccent.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
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
        const SizedBox(height: 4),
        Text(
          'Type these in the search box above',
          style: GoogleFonts.poppins(
            color: Colors.grey[400],
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: 16),
        _recentFoods.isEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'No common foods available',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.purpleAccent.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purpleAccent.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      padding: const EdgeInsets.all(10),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.0,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _recentFoods.length,
                      itemBuilder: (context, index) {
                        final food = _recentFoods[index];
                        String foodName = food['food_name'] ?? food['name'] ?? 'Unknown Food';
                        
                        // Determine icon color based on food name
                        Color chipColor;
                        if (foodName.toLowerCase().contains('water')) {
                          chipColor = Colors.blue.withOpacity(0.7);
                        } else if (foodName.toLowerCase().contains('fruit') || 
                                  foodName.toLowerCase().contains('apple')) {
                          chipColor = Colors.red.withOpacity(0.7);
                        } else if (foodName.toLowerCase().contains('coffee') ||
                                  foodName.toLowerCase().contains('tea')) {
                          chipColor = Colors.brown.withOpacity(0.7);
                        } else if (foodName.toLowerCase().contains('chicken') ||
                                  foodName.toLowerCase().contains('meat')) {
                          chipColor = Colors.orange.withOpacity(0.7);
                        } else if (foodName.toLowerCase().contains('veggie') ||
                                  foodName.toLowerCase().contains('salad')) {
                          chipColor = Colors.green.withOpacity(0.7);
                        } else {
                          chipColor = Colors.purpleAccent.withOpacity(0.7);
                        }
                        
                        // Trim the name if it's too long
                        if (foodName.length > 15) {
                          foodName = foodName.substring(0, 13) + '...';
                        }
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              _selectFood(food);
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: chipColor,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: chipColor.withOpacity(0.5),
                                    blurRadius: 4,
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        foodName,
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.add_circle,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                ),
              ),
            );
          },
                    ),
                  ),
                ),
        ),
      ],
    );
  }
} 