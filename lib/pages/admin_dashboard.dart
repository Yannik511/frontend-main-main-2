import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kreisel_frontend/services/admin_service.dart';
import 'package:kreisel_frontend/models/item_model.dart';
import 'package:kreisel_frontend/models/rental_model.dart';
import 'package:kreisel_frontend/models/user_model.dart';
import 'package:kreisel_frontend/pages/login_page.dart';
import 'package:image_picker/image_picker.dart';

// Interface definition for dependency injection - updated for ApiResponse pattern
abstract class AdminServiceInterface {
  Future<List<Item>> getAllItems(String location);
  Future<List<Rental>> getAllRentals();
  Future<List<User>> getAllUsers();
  Future<Item> createItem(Item item);
  Future<Item> updateItem(int id, Item item);
  Future<void> deleteItem(int id);
  Future<bool> isAdminAuthenticated();
  Future<bool> ensureAuthenticated();
  Future<bool> canCreateItems();
  Future<void> logout();
  Future<String?> uploadItemImageBytes(
    int itemId,
    Uint8List imageBytes,
    String filename,
  );
}

// Default implementation that adapts the new ApiResponse-based AdminService
class DefaultAdminService implements AdminServiceInterface {
  final AdminService _adminService = AdminService.instance;

  @override
  Future<List<Item>> getAllItems(String location) async {
    final response = await _adminService.getAllItems(location);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw Exception(response.errorMessage ?? "Failed to fetch items");
  }

  @override
  Future<List<Rental>> getAllRentals() async {
    final response = await _adminService.getAllRentals();
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw Exception(response.errorMessage ?? "Failed to fetch rentals");
  }

  @override
  Future<List<User>> getAllUsers() async {
    final response = await _adminService.getAllUsers();
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw Exception(response.errorMessage ?? "Failed to fetch users");
  }

  @override
  Future<Item> createItem(Item item) async {
    final response = await _adminService.createItem(item);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw Exception(response.errorMessage ?? "Failed to create item");
  }

  @override
  Future<Item> updateItem(int id, Item item) async {
    final response = await _adminService.updateItem(id, item);
    if (response.isSuccess && response.data != null) {
      return response.data!;
    }
    throw Exception(response.errorMessage ?? "Failed to update item");
  }

  @override
  Future<void> deleteItem(int id) async {
    final response = await _adminService.deleteItem(id);
    if (!response.isSuccess) {
      throw Exception(response.errorMessage ?? "Failed to delete item");
    }
  }

  @override
  Future<bool> isAdminAuthenticated() async {
    return _adminService.isAdminAuthenticated();
  }

  @override
  Future<bool> ensureAuthenticated() async {
    return _adminService.ensureAuthenticated();
  }

  @override
  Future<bool> canCreateItems() async {
    return _adminService.canCreateItems();
  }

  @override
  Future<void> logout() async {
    await _adminService.logout();
  }

  @override
  Future<String?> uploadItemImageBytes(
    int itemId,
    Uint8List imageBytes,
    String filename,
  ) async {
    final response = await _adminService.uploadItemImageBytes(
      itemId,
      imageBytes,
      filename,
    );
    if (response.isSuccess) {
      return response.data;
    }
    throw Exception(response.errorMessage ?? "Failed to upload image");
  }
}

class AdminDashboard extends StatefulWidget {
  final AdminServiceInterface adminService;

  AdminDashboard({super.key, AdminServiceInterface? adminService})
    : adminService = adminService ?? DefaultAdminService();

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  static const List<String> LOCATIONS = [
    'PASING',
    'KARLSTRASSE',
    'LOTHSTRASSE',
  ];
  static const List<String> GENDERS = ['UNISEX', 'HERREN', 'DAMEN'];
  static const List<String> CATEGORIES = ['EQUIPMENT', 'KLEIDUNG'];
  static const Map<String, List<String>> SUBCATEGORIES = {
    'EQUIPMENT': ['HELME', 'SKI', 'SNOWBOARDS', 'BRILLEN', 'FLASCHEN'],
    'KLEIDUNG': [
      'JACKEN',
      'HOSEN',
      'HANDSCHUHE',
      'MUETZEN',
      'SCHALS',
      'STIEFEL',
      'WANDERSCHUHE',
    ],
  };
  static const List<String> CONDITIONS = ['NEU', 'GEBRAUCHT'];

  int _selectedTab = 0;
  String _selectedLocation = 'PASING'; // Default location
  bool _isLoading = false;
  List<Item> _items = [];
  List<Rental> _rentals = [];
  List<User> _users = [];
  final _searchController = TextEditingController();
  bool _canCreateItems = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadData();
    _loadPermissions();
  }

  Future<void> _checkAuthAndLoadData() async {
    // Check if admin is still authenticated
    final isAuthenticated = await widget.adminService.isAdminAuthenticated();
    if (!isAuthenticated) {
      _logout();
      return;
    }
    _loadData();
  }

  Future<void> _loadPermissions() async {
    try {
      _canCreateItems = await widget.adminService.canCreateItems();
      if (mounted) {
        setState(() {}); // Update UI with new permissions
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load permissions')));
      }
    }
  }

  Widget _buildLocationSelector() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: CupertinoSegmentedControl<String>(
        children: {
          'PASING': Padding(padding: EdgeInsets.all(8), child: Text('Pasing')),
          'KARLSTRASSE': Padding(
            padding: EdgeInsets.all(8),
            child: Text('Karlstraße'),
          ),
          'LOTHSTRASSE': Padding(
            padding: EdgeInsets.all(8),
            child: Text('Lothstraße'),
          ),
        },
        onValueChanged: (String value) {
          setState(() {
            _selectedLocation = value;
          });
          _loadData(); // Reload items with new location
        },
        groupValue: _selectedLocation,
      ),
    );
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      // Ensure we're still authenticated before making requests
      final isAuth = await widget.adminService.ensureAuthenticated();
      if (!isAuth) {
        _logout();
        return;
      }

      switch (_selectedTab) {
        case 0:
          _items = await widget.adminService.getAllItems(_selectedLocation);
          break;
        case 1:
          _rentals = await widget.adminService.getAllRentals();
          break;
        case 2:
          _users = await widget.adminService.getAllUsers();
          break;
      }
    } catch (e) {
      print('DEBUG: Load data error: $e');
      // Check if it's an authentication error
      if (e.toString().contains('Token') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        _logout();
        return;
      }
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Navigation Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                _buildNavButton('Items', 0),
                SizedBox(width: 8),
                _buildNavButton('Rentals', 1),
                SizedBox(width: 8),
                _buildNavButton('Users', 2),
              ],
            ),
          ),

          // Location Selector (only show for items tab)
          if (_selectedTab == 0) _buildLocationSelector(),

          // Search Bar (only show for rentals and users)
          if (_selectedTab > 0)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                onChanged: (value) {
                  // Debounce search to avoid too many requests
                  Future.delayed(Duration(milliseconds: 500), () {
                    if (_searchController.text == value) {
                      _handleSearch(value);
                    }
                  });
                },
                onSubmitted: _handleSearch,
                placeholder: 'Suche...',
                style: TextStyle(color: Colors.white),
              ),
            ),

          Expanded(
            child:
                _isLoading
                    ? Center(child: CupertinoActivityIndicator())
                    : _buildContent(),
          ),
        ],
      ),
      floatingActionButton:
          _selectedTab ==
                  0 // When Items tab is selected
              ? FloatingActionButton(
                backgroundColor: Color(0xFF007AFF),
                onPressed: _createItem,
                child: Icon(Icons.add, color: Colors.white),
              )
              : null,
    );
  }

  Widget _buildNavButton(String title, int index) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.all(12),
        color: _selectedTab == index ? Color(0xFF007AFF) : Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
        onPressed: () {
          setState(() => _selectedTab = index);
          _searchController.clear();
          _loadData();
        },
        child: Text(title, style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return _buildItemsList();
      case 1:
        return _buildRentalsList();
      case 2:
        return _buildUsersList();
      default:
        return Container();
    }
  }

  Widget _buildItemsList() {
    if (_items.isEmpty) {
      return Center(
        child: Text(
          'Keine Items für $_selectedLocation gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _items.length,
        itemBuilder:
            (context, index) => Card(
              color: Color(0xFF1C1C1E),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading:
                    _items[index].imageUrl != null
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            _items[index].imageUrl!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 24,
                                  ),
                                ),
                          ),
                        )
                        : Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey[800],
                          child: Icon(Icons.image, size: 24),
                        ),
                title: Text(
                  _items[index].name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      'Standort: ${_items[index].location}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    Text(
                      'Status: ${_items[index].available ? "Verfügbar" : "Nicht verfügbar"}',
                      style: TextStyle(
                        color:
                            _items[index].available ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      'Kategorie: ${_items[index].category} - ${_items[index].subcategory}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    if (_items[index].brand?.isNotEmpty ?? false)
                      Text(
                        'Marke: ${_items[index].brand}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    if (_items[index].size?.isNotEmpty ?? false)
                      Text(
                        'Größe: ${_items[index].size}',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                    SizedBox(height: 4),
                  ],
                ),
                trailing: SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Color(0xFF007AFF)),
                        onPressed: () => _showItemDialog(_items[index]),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(_items[index].id),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _buildRentalsList() {
    if (_rentals.isEmpty) {
      return Center(
        child: Text(
          'Keine Rentals gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _rentals.length,
        itemBuilder: (context, index) {
          final rental = _rentals[index];

          return Card(
            color: Color(0xFF1C1C1E),
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              title: Text(
                rental.item.name,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Text(
                    'User ID: ${rental.userId}', // Changed to show user ID
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    'Status: ${rental.status}',
                    style: TextStyle(
                      color: _getStatusColor(rental.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatStatus(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return 'Aktiv';
      case 'OVERDUE':
        return 'Überfällig';
      case 'RETURNED':
        return 'Zurückgegeben';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        return Colors.green;
      case 'OVERDUE':
        return Colors.red;
      case 'RETURNED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Widget _buildUsersList() {
    if (_users.isEmpty) {
      return Center(
        child: Text(
          'Keine Users gefunden',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _users.length,
        itemBuilder:
            (context, index) => Card(
              color: Color(0xFF1C1C1E),
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(
                  _users[index].fullName,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  _users[index].email,
                  style: TextStyle(color: Colors.grey[400]),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.info_outline, color: Color(0xFF007AFF)),
                  onPressed: () => _showUserDetails(_users[index]),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _createItem() async {
    await _showItemDialog(null);
  }

  Future<void> _showItemDialog(Item? item) async {
    final isCreating = item == null;

    final nameController = TextEditingController(text: item?.name ?? '');
    final descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    final brandController = TextEditingController(text: item?.brand ?? '');
    final sizeController = TextEditingController(text: item?.size ?? '');

    // For location, use current selected location for new items
    String selectedLocation =
        isCreating ? _selectedLocation : (item.location ?? LOCATIONS.first);
    String selectedGender = item?.gender ?? GENDERS.first;
    String selectedCategory = item?.category ?? CATEGORIES.first;
    String selectedSubcategory =
        item?.subcategory ?? SUBCATEGORIES[CATEGORIES.first]!.first;
    String selectedZustand = item?.zustand ?? CONDITIONS.first;

    // Image picker variables
    final ImagePicker picker = ImagePicker();
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    String? existingImageUrl = item?.imageUrl;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Color(0xFF1C1C1E),
              title: Text(
                isCreating ? 'Neues Item erstellen' : 'Item bearbeiten',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image picker section
                    Text(
                      'Bild:',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final XFile? image = await picker.pickImage(
                          source: ImageSource.gallery,
                          maxWidth: 1200,
                          maxHeight: 1200,
                          imageQuality: 90,
                        );
                        if (image != null) {
                          selectedImageName = image.name;

                          if (kIsWeb) {
                            // Web platform
                            selectedImageBytes = await image.readAsBytes();
                            setDialogState(() {});
                          } else {
                            // Mobile/desktop platforms
                            selectedImageBytes = await image.readAsBytes();
                            setDialogState(() {});
                          }
                        }
                      },
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(0xFF3C3C3E),
                            width: 1,
                          ),
                        ),
                        child:
                            selectedImageBytes != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.memory(
                                    selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : existingImageUrl != null
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: Image.network(
                                    existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.broken_image,
                                              color: Colors.grey,
                                              size: 40,
                                            ),
                                            SizedBox(height: 8),
                                            Text(
                                              'Bild konnte nicht geladen werden',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Klicken Sie hier, um ein Bild hinzuzufügen',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                      ),
                    ),
                    if (selectedImageBytes != null || existingImageUrl != null)
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            selectedImageBytes = null;
                            selectedImageName = null;
                            existingImageUrl = null;
                          });
                        },
                        child: Text(
                          'Bild entfernen',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                    _buildLabeledTextField('Name:', nameController),
                    _buildLabeledTextField(
                      'Beschreibung:',
                      descriptionController,
                      maxLines: 3,
                    ),
                    _buildLabeledTextField('Marke:', brandController),
                    _buildLabeledTextField('Größe:', sizeController),

                    // Location Dropdown
                    _buildLabeledDropdown(
                      'Standort:',
                      selectedLocation,
                      LOCATIONS,
                      (value) =>
                          setDialogState(() => selectedLocation = value!),
                    ),

                    // Gender Dropdown
                    _buildLabeledDropdown(
                      'Gender:',
                      selectedGender,
                      GENDERS,
                      (value) => setDialogState(() => selectedGender = value!),
                    ),

                    // Category Dropdown
                    _buildLabeledDropdown(
                      'Kategorie:',
                      selectedCategory,
                      CATEGORIES,
                      (value) {
                        setDialogState(() {
                          selectedCategory = value!;
                          // Reset subcategory when category changes
                          selectedSubcategory = SUBCATEGORIES[value]!.first;
                        });
                      },
                    ),

                    // Subcategory Dropdown
                    _buildLabeledDropdown(
                      'Unterkategorie:',
                      selectedSubcategory,
                      SUBCATEGORIES[selectedCategory]!,
                      (value) =>
                          setDialogState(() => selectedSubcategory = value!),
                    ),

                    // Zustand Dropdown
                    _buildLabeledDropdown(
                      'Zustand:',
                      selectedZustand,
                      CONDITIONS,
                      (value) => setDialogState(() => selectedZustand = value!),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: Text(
                    'Abbrechen',
                    style: TextStyle(color: Colors.grey),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  onPressed:
                      isUploading
                          ? null
                          : () async {
                            // Validate required fields
                            if (nameController.text.trim().isEmpty) {
                              _showError('Name ist erforderlich');
                              return;
                            }

                            try {
                              setDialogState(() => isUploading = true);

                              final updatedItem = Item(
                                id: item?.id ?? 0,
                                name: nameController.text.trim(),
                                description: descriptionController.text.trim(),
                                brand: brandController.text.trim(),
                                size: sizeController.text.trim(),
                                available: item?.available ?? true,
                                location: selectedLocation,
                                gender: selectedGender,
                                category: selectedCategory,
                                subcategory: selectedSubcategory,
                                zustand: selectedZustand,
                                imageUrl: existingImageUrl ?? '',
                              );

                              if (isCreating) {
                                // Create item
                                final createdItem = await widget.adminService
                                    .createItem(updatedItem);

                                // Upload image if selected
                                if (selectedImageBytes != null &&
                                    selectedImageName != null) {
                                  final imageUrl = await widget.adminService
                                      .uploadItemImageBytes(
                                        createdItem.id,
                                        selectedImageBytes!,
                                        selectedImageName!,
                                      );

                                  if (imageUrl != null) {
                                    // Update item with image URL
                                    await widget.adminService.updateItem(
                                      createdItem.id,
                                      createdItem.copyWith(imageUrl: imageUrl),
                                    );
                                  }
                                }
                              } else {
                                // Update item
                                await widget.adminService.updateItem(
                                  item.id,
                                  updatedItem,
                                );

                                // Upload image if selected
                                if (selectedImageBytes != null &&
                                    selectedImageName != null) {
                                  final imageUrl = await widget.adminService
                                      .uploadItemImageBytes(
                                        item.id,
                                        selectedImageBytes!,
                                        selectedImageName!,
                                      );

                                  if (imageUrl != null) {
                                    // Update item with image URL
                                    await widget.adminService.updateItem(
                                      item.id,
                                      updatedItem.copyWith(imageUrl: imageUrl),
                                    );
                                  }
                                }
                              }
                              Navigator.pop(context, true);
                            } catch (e) {
                              print('DEBUG: Item save error: $e');
                              setDialogState(() => isUploading = false);
                              if (e.toString().contains('Token') ||
                                  e.toString().contains('401') ||
                                  e.toString().contains('403')) {
                                Navigator.pop(context, false);
                                _logout();
                                return;
                              }
                              _showError(e.toString());
                            }
                          },
                  child:
                      isUploading
                          ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF007AFF),
                            ),
                          )
                          : Text(
                            isCreating ? 'Erstellen' : 'Speichern',
                            style: TextStyle(color: Color(0xFF007AFF)),
                          ),
                ),
              ],
            );
          },
        );
      },
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }

  Widget _buildLabeledTextField(
    String label,
    TextEditingController controller, {
    bool enabled = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            enabled: enabled,
            maxLines: maxLines,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Color(0xFF2C2C2E) : Color(0xFF1C1C1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabeledDropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    // Ensure value exists in options
    if (!options.contains(value)) {
      print(
        'DEBUG: Invalid value "$value" for $label. Defaulting to first option.',
      );
      value = options.first;
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey, fontSize: 12)),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              onChanged: onChanged,
              items:
                  options.map((String option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(
                        option,
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }).toList(),
              dropdownColor: Color(0xFF2C2C2E),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearch(String query) async {
    if (query.isEmpty) {
      _loadData();
      return;
    }

    setState(() => _isLoading = true);
    try {
      switch (_selectedTab) {
        case 1: // Rentals
          _rentals = await widget.adminService.getAllRentals();
          _rentals =
              _rentals
                  .where(
                    (rental) =>
                        rental.id.toString().contains(query) ||
                        rental.user.fullName.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        rental.user.email.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        rental.item.name.toLowerCase().contains(
                          query.toLowerCase(),
                        ),
                  )
                  .toList();
          break;
        case 2: // Users
          _users = await widget.adminService.getAllUsers();
          _users =
              _users
                  .where(
                    (user) =>
                        user.fullName.toLowerCase().contains(
                          query.toLowerCase(),
                        ) ||
                        user.email.toLowerCase().contains(query.toLowerCase()),
                  )
                  .toList();
          break;
      }
    } catch (e) {
      print('DEBUG: Search error: $e');
      if (e.toString().contains('Token') ||
          e.toString().contains('401') ||
          e.toString().contains('403')) {
        _logout();
        return;
      }
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    try {
      await widget.adminService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      print('DEBUG: Logout error: $e');
      // Force navigation even if logout fails
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          CupertinoPageRoute(builder: (context) => LoginPage()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _deleteItem(int id) async {
    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Item löschen'),
            content: Text('Möchten Sie dieses Item wirklich löschen?'),
            actions: [
              CupertinoDialogAction(
                child: Text('Abbrechen'),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text('Löschen'),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await widget.adminService.deleteItem(id);
                    _loadData();
                  } catch (e) {
                    print('DEBUG: Delete item error: $e');
                    if (e.toString().contains('Token') ||
                        e.toString().contains('401') ||
                        e.toString().contains('403')) {
                      _logout();
                      return;
                    }
                    _showError(e.toString());
                  }
                },
              ),
            ],
          ),
    );
  }

  Future<void> _showUserDetails(User user) async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Color(0xFF1C1C1E),
            title: Text('User Details', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${user.fullName}',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'Email: ${user.email}',
                  style: TextStyle(color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  'ID: ${user.userId}',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text(
                  'Schließen',
                  style: TextStyle(color: Color(0xFF007AFF)),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  void _showError(String message) {
    if (!mounted) return;

    showCupertinoDialog(
      context: context,
      builder:
          (context) => CupertinoAlertDialog(
            title: Text('Fehler'),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Extension to support copyWith for Item model
extension ItemExtension on Item {
  Item copyWith({
    int? id,
    String? name,
    String? size,
    bool? available,
    String? description,
    String? brand,
    String? imageUrl,
    double? averageRating,
    int? reviewCount,
    String? location,
    String? gender,
    String? category,
    String? subcategory,
    String? zustand,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      size: size ?? this.size,
      available: available ?? this.available,
      description: description ?? this.description,
      brand: brand ?? this.brand,
      imageUrl: imageUrl ?? this.imageUrl,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      location: location ?? this.location,
      gender: gender ?? this.gender,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      zustand: zustand ?? this.zustand,
    );
  }
}
