import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/pages/my_rentals_page.dart';
import 'package:kreisel_frontend/services/api_service.dart';
import 'package:kreisel_frontend/widgets/rent_item_dialog.dart';
import 'package:kreisel_frontend/widgets/snow_fall_widget.dart';
import 'package:kreisel_frontend/widgets/hover_button.dart';
import 'package:kreisel_frontend/pages/item_detail_page.dart';
import 'package:kreisel_frontend/pages/my_account_page.dart';

class HomePage extends StatefulWidget {
  final String selectedLocation;
  final String locationDisplayName;

  const HomePage({
    super.key,
    required this.selectedLocation,
    required this.locationDisplayName,
  });

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> _items = [];
  List<Item> _filteredItems = [];
  bool _isLoading = true;
  bool _showOnlyAvailable = true;
  String? _selectedGender;
  String? _selectedCategory;
  String? _selectedSubcategory;

  // Remove AudioService line

  // Add this map at the class level
  final Map<String, List<String>> categorySubcategories = {
    'KLEIDUNG': ['HOSEN', 'JACKEN'],
    'SCHUHE': ['STIEFEL', 'WANDERSCHUHE'],
    'ACCESSOIRES': ['MÜTZEN', 'HANDSCHUHE', 'SCHALS', 'BRILLEN', 'FLASCHEN'],
    'EQUIPMENT': ['SKI', 'SNOWBOARDS', 'HELME'],
    'TASCHEN': [], // No subcategories
  };

  @override
  void initState() {
    super.initState();
    _loadItems();
    // Remove music initialization
  }

  Future<void> _loadItems() async {
    try {
      setState(() => _isLoading = true);
      print('DEBUG: Loading items for location: ${widget.selectedLocation}');
      print('DEBUG: Display name: ${widget.locationDisplayName}');

      final items = await ApiService.getItems(
        location: widget.selectedLocation,
      );

      print('DEBUG: Loaded ${items.length} items');

      if (mounted) {
        setState(() {
          _items = items;
          _filteredItems = items; // Initialize filtered items
          _isLoading = false;
        });
        _filterItems();
      }
    } catch (e) {
      print('DEBUG: Error loading items: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showAlert(
          'Fehler beim Laden',
          'Items konnten nicht geladen werden.\nDetails: ${e.toString()}',
        );
      }
    }
  }

  void _filterItems([String query = '']) {
    setState(() {
      _filteredItems =
          _items.where((item) {
            // Availability filter
            if (_showOnlyAvailable && !item.available) return false;

            // Search filter
            if (query.isNotEmpty) {
              final searchQuery = query.toLowerCase();
              if (!item.name.toLowerCase().contains(searchQuery) &&
                  !(item.brand?.toLowerCase().contains(searchQuery) ?? false) &&
                  !(item.description?.toLowerCase().contains(searchQuery) ??
                      false)) {
                return false;
              }
            }

            // Gender Filter - case insensitive
            if (_selectedGender != null &&
                item.gender?.toUpperCase() != _selectedGender) {
              return false;
            }

            // Category Filter - case insensitive
            if (_selectedCategory != null &&
                item.category?.toUpperCase() != _selectedCategory) {
              return false;
            }

            // Subcategory Filter - case insensitive
            if (_selectedSubcategory != null &&
                item.subcategory?.toUpperCase() != _selectedSubcategory) {
              return false;
            }

            return true;
          }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Snow effect background
          SnowFallWidget(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header with buttons
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      HoverButton(
                        tooltip: 'Zurück',
                        onPressed: () => Navigator.pop(context),
                        child: Icon(CupertinoIcons.back),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.locationDisplayName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      HoverButton(
                        tooltip: 'Mein Account',
                        onPressed: _navigateToAccount,
                        child: Icon(
                          CupertinoIcons.person,
                          color: Color(0xFF007AFF),
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      HoverButton(
                        tooltip: 'Meine Ausleihen',
                        onPressed: _navigateToRentals,
                        child: Icon(
                          CupertinoIcons.cube_box,
                          color: Color(0xFF007AFF),
                          size: 28,
                        ),
                      ),
                      // Remove MusicButton
                    ],
                  ),
                ),

                // Search bar
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      CupertinoSearchTextField(
                        controller: _searchController,
                        onChanged: _filterItems,
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        placeholder: 'Suche nach Gegenstand, Marke,...',
                        placeholderStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        prefixIcon: Icon(
                          CupertinoIcons.search,
                          color: Colors.grey,
                        ),
                        suffixIcon: Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Colors.grey,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      SizedBox(height: 12),
                      // Availability toggle
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showOnlyAvailable = !_showOnlyAvailable;
                            _filterItems();
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color:
                                  _showOnlyAvailable
                                      ? Color(0xFF32D74B).withOpacity(0.5)
                                      : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _showOnlyAvailable
                                    ? CupertinoIcons.check_mark_circled_solid
                                    : CupertinoIcons.circle,
                                color:
                                    _showOnlyAvailable
                                        ? Color(0xFF32D74B)
                                        : Colors.grey,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Nur verfügbare Items anzeigen',
                                style: TextStyle(
                                  color:
                                      _showOnlyAvailable
                                          ? Colors.white
                                          : Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16),

                // Filter chips
                _buildFilterChips(),

                // Items list
                Expanded(child: _buildItemsList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Update the _buildFilterChips method
  Widget _buildFilterChips() {
    return SizedBox(
      height: 120,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gender Filter
            Row(
              children: [
                _buildFilterChip('DAMEN', _selectedGender, (value) {
                  setState(
                    () =>
                        _selectedGender =
                            _selectedGender == value ? null : value,
                  );
                  _filterItems();
                }),
                SizedBox(width: 8),
                _buildFilterChip('HERREN', _selectedGender, (value) {
                  setState(
                    () =>
                        _selectedGender =
                            _selectedGender == value ? null : value,
                  );
                  _filterItems();
                }),
                SizedBox(width: 8),
                _buildFilterChip('UNISEX', _selectedGender, (value) {
                  setState(
                    () =>
                        _selectedGender =
                            _selectedGender == value ? null : value,
                  );
                  _filterItems();
                }),
              ],
            ),
            SizedBox(height: 8),
            // Category Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    categorySubcategories.keys.map((category) {
                      return Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: _buildFilterChip(category, _selectedCategory, (
                          value,
                        ) {
                          setState(() {
                            _selectedCategory =
                                _selectedCategory == value ? null : value;
                            _selectedSubcategory = null; // Reset subcategory
                          });
                          _filterItems();
                        }),
                      );
                    }).toList(),
              ),
            ),
            SizedBox(height: 8),
            // Subcategory Filter
            if (_selectedCategory != null &&
                categorySubcategories[_selectedCategory]!.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      categorySubcategories[_selectedCategory]!.map((
                        subcategory,
                      ) {
                        return Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            subcategory,
                            _selectedSubcategory,
                            (value) {
                              setState(
                                () =>
                                    _selectedSubcategory =
                                        _selectedSubcategory == value
                                            ? null
                                            : value,
                              );
                              _filterItems();
                            },
                          ),
                        );
                      }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isLoading) {
      return Center(child: CupertinoActivityIndicator());
    }

    if (_filteredItems.isEmpty) {
      return Center(
        child: Text(
          'Keine Items gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) => _buildItemCard(_filteredItems[index]),
    );
  }

  Widget _buildItemCard(Item item) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => ItemDetailPage(item: item)),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                item.available
                    ? Color(0xFF32D74B).withOpacity(0.3)
                    : Color(0xFFFF453A).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          item.available
                              ? Color(0xFF32D74B)
                              : Color(0xFFFF453A),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.available ? 'Verfügbar' : 'Ausgeliehen',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              if (item.brand != null)
                Text(
                  item.brand!,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              if (item.size != null)
                Text(
                  'Größe: ${item.size}',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              if (item.description != null)
                Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    item.description!,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ),
              SizedBox(height: 12),
              Row(
                children: [
                  _buildInfoChip(item.gender),
                  _buildInfoChip(item.category),
                  _buildInfoChip(item.subcategory),
                  if (item.zustand != null) _buildInfoChip(item.zustand),
                ],
              ),
              if (item.available)
                Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: StatefulBuilder(
                    builder: (context, setState) {
                      bool isHovered = false;
                      return MouseRegion(
                        onEnter: (_) => setState(() => isHovered = true),
                        onExit: (_) => setState(() => isHovered = false),
                        child: AnimatedContainer(
                          duration: Duration(milliseconds: 200),
                          transform:
                              Matrix4.identity()..scale(isHovered ? 1.05 : 1.0),
                          width: double.infinity,
                          child: CupertinoButton(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            color: Color(0xFF007AFF),
                            borderRadius: BorderRadius.circular(12),
                            onPressed: () {
                              showCupertinoDialog(
                                context: context,
                                builder:
                                    (context) => RentItemDialog(
                                      item: item,
                                      onRented: _loadItems,
                                    ),
                              );
                            },
                            child: Text(
                              'Ausleihen',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String? label) {
    if (label == null) return SizedBox.shrink();
    return Container(
      margin: EdgeInsets.only(right: 8),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toLowerCase(),
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  // Update the filter chip widget
  Widget _buildFilterChip(
    String label,
    String? selectedValue,
    Function(String) onSelected,
  ) {
    final bool isSelected = selectedValue == label;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(label),
      selectedColor: Color(0xFF007AFF),
      backgroundColor: Color(0xFF1C1C1E),
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.grey,
        fontSize: 13,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Color(0xFF007AFF) : Colors.grey.withOpacity(0.3),
        ),
      ),
    );
  }

  void _showAlert(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              CupertinoDialogAction(
                child: Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _navigateToRentals() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => MyRentalsPage()),
    );
  }

  void _navigateToAccount() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => MyAccountPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: Duration(milliseconds: 300),
      ),
    );
  }
}
