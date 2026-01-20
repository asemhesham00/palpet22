import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:palpet/core/constants/app_colors.dart';
import 'package:palpet/data/models/pet.dart';
import 'package:palpet/services/auth_service.dart';
import 'package:palpet/services/database_service.dart';

class AddPostScreen extends StatefulWidget {
  final Function(int)? onNavigate;
  final Pet? petToEdit;
  final String? initialPostType;

  const AddPostScreen({
    super.key,
    this.onNavigate,
    this.petToEdit,
    this.initialPostType,
  });

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  bool _isLoading = false;
  bool _isGettingLocation = false;

  bool _showErrors = false;

  bool _isEditing = false;
  String? _existingImageUrl;

  File? _selectedImage;
  String _selectedType = 'Adoption';
  final List<String> _postTypes = ['Adoption', 'Lost', 'Found', 'Hotel'];
  final List<String> _speciesList = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Hamster',
    'Turtle',
    'Other'
  ];
  final List<String> _genderList = ['Male', 'Female'];

  // UPDATED PATHS HERE: removed 'lib/' prefix
  final Map<String, String> _defaultSpeciesImages = {
    'Dog': 'assets/imgs/dog.png',
    'Cat': 'assets/imgs/cat.png',
    'Bird': 'assets/imgs/bird.png',
    'Rabbit': 'assets/imgs/rabbit.png',
    'Hamster': 'assets/imgs/hamster.png',
    'Turtle': 'assets/imgs/turtle.png',
    'Other': 'https://cdn-icons-png.flaticon.com/512/12/12638.png',
  };

  // UPDATED PATH HERE: removed 'lib/' prefix
  final String _defaultHotelImage = 'assets/imgs/dog-house.png';

  final List<String> _jordanAreas = [
    'Amman',
    'Zarqa',
    'Irbid',
    'Aqaba',
    'Salt',
    'Madaba',
    'Jerash',
    'Ajloun',
    'Mafraq',
    'Karak',
    'Tafilah',
    'Ma\'an',
    'Abdoun',
    'Dabouq',
    'Khalda',
    'Sweifieh',
    'Jubaiha',
    'Tla\' Al-Ali'
  ];

  String? _selectedSpecies;
  List<String> _selectedHotelSpecies = [];
  String? _selectedGender;
  String? _selectedArea;

  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _ageController = TextEditingController();

  final _healthTagController = TextEditingController();
  List<String> _healthTags = [];

  final _phoneController = TextEditingController();
  final _rewardController = TextEditingController();

  final _priceController = TextEditingController();
  final _capacityController = TextEditingController();

  final _amenitiesInputController = TextEditingController();
  List<String> _amenities = [];

  final String _genericFallbackImage =
      'https://via.placeholder.com/300?text=No+Image';

  @override
  void initState() {
    super.initState();
    if (widget.petToEdit != null) {
      _loadPetData(widget.petToEdit!);
    } else if (widget.initialPostType != null) {
      _selectedType = widget.initialPostType!;
    }
  }

  void _loadPetData(Pet pet) {
    _isEditing = true;
    _selectedType = pet.postType;
    _nameController.text = pet.name;
    _breedController.text = pet.breed;
    _descriptionController.text = pet.description;
    _phoneController.text = pet.contactPhone;
    _existingImageUrl = pet.imageUrl;

    if (_jordanAreas.contains(pet.location)) {
      _selectedArea = pet.location;
    } else {
      _locationController.text = pet.location;
    }

    if (pet.postType == 'Hotel') {
      _selectedHotelSpecies =
          pet.type.split(',').where((e) => e.isNotEmpty).toList();
      _priceController.text = pet.price ?? '';
      _capacityController.text = pet.capacity ?? '';
      if (pet.amenities != null && pet.amenities!.isNotEmpty) {
        _amenities = pet.amenities!.split(',');
      }
    } else {
      if (_speciesList.contains(pet.type)) {
        _selectedSpecies = pet.type;
      } else {
        _selectedSpecies = 'Other';
      }

      if (pet.postType == 'Adoption') {
        _ageController.text = pet.age;
        if (_genderList.contains(pet.gender)) _selectedGender = pet.gender;
        _healthTags = List.from(pet.healthTags);
      } else {
        _rewardController.text = pet.reward ?? '';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _ageController.dispose();
    _healthTagController.dispose();
    _phoneController.dispose();
    _rewardController.dispose();
    _priceController.dispose();
    _capacityController.dispose();
    _amenitiesInputController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied';
      }

      Position position = await Geolocator.getCurrentPosition();

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String address =
            "${place.subLocality ?? place.locality}, ${place.administrativeArea}";

        setState(() {
          _locationController.text = address;
          _selectedArea = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _addHealthTag() {
    final text = _healthTagController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _healthTags.add(text);
        _healthTagController.clear();
      });
    }
  }

  void _removeHealthTag(String tag) {
    setState(() {
      _healthTags.remove(tag);
    });
  }

  void _addAmenity() {
    final text = _amenitiesInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _amenities.add(text);
        _amenitiesInputController.clear();
      });
    }
  }

  void _removeAmenity(String item) {
    setState(() {
      _amenities.remove(item);
    });
  }

  void _showMultiSelectDialog() async {
    final List<String> tempSelected = List.from(_selectedHotelSpecies);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Select Accepted Species"),
              content: SingleChildScrollView(
                child: ListBody(
                  children: _speciesList.map((item) {
                    return CheckboxListTile(
                      value: tempSelected.contains(item),
                      title: Text(item),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (bool? checked) {
                        setState(() {
                          if (checked == true) {
                            tempSelected.add(item);
                          } else {
                            tempSelected.remove(item);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () {
                    this.setState(() {
                      _selectedHotelSpecies = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text("OK",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPost() async {
    FocusScope.of(context).unfocus();
    setState(() => _showErrors = true);

    bool isNameValid = _nameController.text.trim().isNotEmpty;
    bool isLocationValid =
        _selectedArea != null || _locationController.text.trim().isNotEmpty;
    bool isPhoneValid = _phoneController.text.trim().isNotEmpty;
    bool isSpeciesValid = _selectedSpecies != null;
    bool isHotelSpeciesValid = _selectedHotelSpecies.isNotEmpty;
    bool isBreedValid = _breedController.text.trim().isNotEmpty;
    bool isAgeValid = _ageController.text.trim().isNotEmpty;
    bool isGenderValid = _selectedGender != null;
    bool isDescriptionValid = _descriptionController.text.trim().isNotEmpty;
    bool isHealthInfoValid = _healthTags.isNotEmpty;
    bool isPriceValid = _priceController.text.trim().isNotEmpty;
    bool isCapacityValid = _capacityController.text.trim().isNotEmpty;
    bool isAmenitiesValid = _amenities.isNotEmpty;

    bool isValid = false;

    switch (_selectedType) {
      case 'Adoption':
        isValid = isNameValid &&
            isSpeciesValid &&
            isBreedValid &&
            isLocationValid &&
            isPhoneValid &&
            isAgeValid &&
            isGenderValid &&
            isDescriptionValid &&
            isHealthInfoValid;
        break;
      case 'Lost':
        isValid =
            isNameValid && isSpeciesValid && isPhoneValid && isLocationValid;
        break;
      case 'Found':
        isValid = isSpeciesValid && isPhoneValid && isLocationValid;
        break;
      case 'Hotel':
        isValid = isNameValid &&
            isHotelSpeciesValid &&
            isLocationValid &&
            isPhoneValid &&
            isPriceValid &&
            isCapacityValid &&
            isAmenitiesValid &&
            isDescriptionValid;
        break;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields marked in red.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = AuthService().currentUser;
      if (user == null) throw Exception("User not logged in");

      String imageUrl;

      if (_selectedImage != null) {
        imageUrl = await DatabaseService().uploadImage(_selectedImage!);
      } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
        imageUrl = _existingImageUrl!;
      } else {
        if (_selectedType == 'Hotel') {
          imageUrl = _defaultHotelImage;
        } else {
          String species = _selectedSpecies ?? 'Other';
          imageUrl =
              _defaultSpeciesImages[species] ?? _defaultSpeciesImages['Other']!;
        }
      }

      String? amenitiesString;
      if (_amenities.isNotEmpty) {
        amenitiesString = _amenities.join(',');
      }

      String finalTypeValue = '';
      if (_selectedType == 'Hotel') {
        finalTypeValue = _selectedHotelSpecies.join(',');
      } else {
        finalTypeValue = _selectedSpecies!;
      }

      String finalLocation = _selectedArea ?? _locationController.text;

      String finalName = _nameController.text;
      if (_selectedType == 'Found' && finalName.isEmpty) {
        finalName = 'Found Pet';
      }

      String? finalReward;
      if (_selectedType == 'Lost' && _rewardController.text.isNotEmpty) {
        finalReward = _rewardController.text;
      } else {
        finalReward = null;
      }

      Pet petData = Pet(
        id: widget.petToEdit?.id ?? '',
        ownerId: user.uid,
        postType: _selectedType,
        name: finalName,
        type: finalTypeValue,
        breed: _breedController.text,
        gender: _selectedGender ?? '',
        age: _ageController.text,
        description: _descriptionController.text,
        imageUrl: imageUrl,
        location: finalLocation,
        contactPhone: _phoneController.text,
        healthTags: _healthTags,
        reward: finalReward,
        price: _priceController.text.isNotEmpty ? _priceController.text : null,
        capacity: _capacityController.text.isNotEmpty
            ? _capacityController.text
            : null,
        amenities: amenitiesString,
      );

      if (_isEditing) {
        await DatabaseService().updatePet(petData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post updated successfully!')),
          );
          Navigator.pop(context, true);
        }
      } else {
        String newPetId = await DatabaseService().addPet(petData);
        await DatabaseService().checkAndSendNotifications(petData, newPetId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post created successfully!')),
          );
          await Future.delayed(const Duration(milliseconds: 100));

          if (mounted) {
            int targetIndex = 0;
            if (_selectedType == 'Adoption') {
              targetIndex = 3;
            } else if (_selectedType == 'Lost' || _selectedType == 'Found') {
              targetIndex = 4;
            } else if (_selectedType == 'Hotel') {
              targetIndex = 5;
            }

            if (widget.onNavigate != null) {
              widget.onNavigate!(targetIndex);
            } else {
              Navigator.of(context).pop();
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          _isEditing ? "Edit Post" : "Create New Post",
          style: const TextStyle(
              color: AppColors.textDark, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: _buildImagePicker(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Post Type",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  AbsorbPointer(
                    absorbing: _isEditing,
                    child: Opacity(
                      opacity: _isEditing ? 0.6 : 1.0,
                      child: _buildTypeSelector(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Basic Info",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: "Name (Pet/Hotel)",
                    controller: _nameController,
                    icon: Icons.pets,
                    isRequired: _selectedType != 'Found',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _selectedType == 'Hotel'
                            ? _buildMultiSelectDropdownField()
                            : _buildDropdownField(
                                label: "Species",
                                value: _selectedSpecies,
                                items: _speciesList,
                                icon: Icons.category,
                                onChanged: (val) {
                                  setState(() => _selectedSpecies = val);
                                },
                                isRequired: true,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildTextField(
                        label: "Breed/Details",
                        controller: _breedController,
                        icon: Icons.style,
                        isRequired: _selectedType == 'Adoption',
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _buildDynamicFields(),
                  ),
                  const SizedBox(height: 24),
                  const Text("Location",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildLocationSection(),
                  const SizedBox(height: 12),
                  _buildTextField(
                    label: "Description / Caption",
                    controller: _descriptionController,
                    icon: Icons.description,
                    maxLines: 4,
                    isRequired:
                        _selectedType == 'Adoption' || _selectedType == 'Hotel',
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _submitPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                      child: Text(_isEditing ? "Update Post" : "Post Now",
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      children: [
        InkWell(
          onTap: _getCurrentLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _isGettingLocation
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.my_location, color: AppColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Use Current Location (GPS)",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: Divider()),
          Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("OR", style: TextStyle(color: Colors.grey))),
          Expanded(child: Divider())
        ]),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _selectedArea,
                decoration: InputDecoration(
                  labelText: "Select Area (Recommended)",
                  prefixIcon: const Icon(Icons.map, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                items: _jordanAreas.map((area) {
                  return DropdownMenuItem(value: area, child: Text(area));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedArea = val;
                    if (val != null) {
                      _locationController.text = val;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTextField(
          label: "Selected Location (Editable)",
          controller: _locationController,
          icon: Icons.pin_drop,
          isRequired: true,
        ),
      ],
    );
  }

  Widget _buildMultiSelectDropdownField() {
    String displayText = _selectedHotelSpecies.isEmpty
        ? "Select Species"
        : _selectedHotelSpecies.join(", ");

    Color borderColor = (_showErrors && _selectedHotelSpecies.isEmpty)
        ? Colors.red
        : Colors.grey[200]!;

    return InkWell(
      onTap: _showMultiSelectDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: "Accepted Species",
          prefixIcon: const Icon(Icons.category, color: Colors.grey, size: 22),
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary)),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          errorText: (_showErrors && _selectedHotelSpecies.isEmpty)
              ? "Required"
              : null,
        ),
        child: Text(displayText,
            style: const TextStyle(fontSize: 16, color: Colors.black87),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ),
    );
  }

  Widget _buildDropdownField(
      {required String label,
      required String? value,
      required List<String> items,
      required Function(String?) onChanged,
      IconData? icon,
      bool isRequired = false}) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.grey, size: 22) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        errorText:
            (_showErrors && isRequired && value == null) ? "Required" : null,
      ),
    );
  }

  Widget _buildImagePicker() {
    ImageProvider? imageProvider;
    bool isDefault = false;

    // Check if image is local asset
    bool isLocalAsset = false;
    if (_existingImageUrl != null) {
      if (_existingImageUrl!.startsWith('assets/') ||
          _existingImageUrl!.startsWith('lib/')) {
        isLocalAsset = true;
      }
    }

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_existingImageUrl != null &&
        _existingImageUrl != _genericFallbackImage) {
      if (isLocalAsset) {
        imageProvider = AssetImage(_existingImageUrl!);
      } else {
        imageProvider = NetworkImage(_existingImageUrl!);
      }
    } else {
      isDefault = true;
      String placeholderUrl;
      if (_selectedType == 'Hotel') {
        placeholderUrl = _defaultHotelImage;
      } else {
        String species = _selectedSpecies ?? 'Other';
        placeholderUrl =
            _defaultSpeciesImages[species] ?? _defaultSpeciesImages['Other']!;
      }

      // Check if placeholder is local or network
      if (placeholderUrl.startsWith('assets/')) {
        imageProvider = AssetImage(placeholderUrl);
      } else {
        imageProvider = NetworkImage(placeholderUrl);
      }
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.5),
        image: (imageProvider != null && !isDefault)
            ? DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isDefault && imageProvider != null)
            Image(
              image: imageProvider,
              height: 120,
              width: 120,
              fit: BoxFit.contain,
            ),
          if (_selectedImage == null &&
              (_existingImageUrl == null ||
                  _existingImageUrl == _genericFallbackImage ||
                  isDefault))
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1), blurRadius: 4)
                  ],
                ),
                child: const Icon(Icons.add_a_photo,
                    size: 20, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _postTypes.map((type) {
          final isSelected = _selectedType == type;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.grey[300]!),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4))
                      ]
                    : [],
              ),
              child: Text(type,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDynamicFields() {
    switch (_selectedType) {
      case 'Adoption':
        return Column(
          key: const ValueKey('Adoption'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Adoption Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        label: "Age",
                        controller: _ageController,
                        icon: Icons.cake,
                        isRequired: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdownField(
                  label: "Gender",
                  value: _selectedGender,
                  items: _genderList,
                  icon: Icons.male,
                  onChanged: (val) => setState(() => _selectedGender = val),
                  isRequired: true,
                )),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
                label: "Contact Phone",
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isRequired: true),
            const SizedBox(height: 12),
            _buildHealthTagsInput(),
          ],
        );
      case 'Lost':
      case 'Found':
        bool isLost = _selectedType == 'Lost';
        return Column(
          key: const ValueKey('LostFound'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isLost ? "Contact & Reward" : "Contact Details",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildTextField(
                label: "Contact Phone Number",
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isRequired: true),
            if (isLost) ...[
              const SizedBox(height: 12),
              _buildTextField(
                  label: "Reward (Optional)",
                  controller: _rewardController,
                  icon: Icons.monetization_on_outlined),
            ],
          ],
        );
      case 'Hotel':
        return Column(
          key: const ValueKey('Hotel'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hotel Details",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _buildTextField(
                        label: "Price / Night",
                        controller: _priceController,
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                        isRequired: true)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildTextField(
                        label: "Capacity",
                        controller: _capacityController,
                        icon: Icons.home_work,
                        isRequired: true)),
              ],
            ),
            const SizedBox(height: 12),
            _buildAmenitiesInput(),
            const SizedBox(height: 12),
            _buildTextField(
                label: "Contact Phone",
                controller: _phoneController,
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                isRequired: true),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHealthTagsInput() {
    bool hasError =
        _showErrors && _selectedType == 'Adoption' && _healthTags.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTextField(
                    label: "Health Info (e.g. Vaccinated)",
                    controller: _healthTagController,
                    icon: Icons.local_hospital)),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addHealthTag,
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white)),
            ),
          ],
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 12),
            child: Text("Required: Add at least one health tag",
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        if (_healthTags.isNotEmpty)
          Wrap(
              spacing: 8,
              children: _healthTags
                  .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeHealthTag(tag)))
                  .toList()),
      ],
    );
  }

  Widget _buildAmenitiesInput() {
    bool hasError =
        _showErrors && _selectedType == 'Hotel' && _amenities.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: _buildTextField(
                    label: "Amenities (e.g. Wifi, Pool)",
                    controller: _amenitiesInputController,
                    icon: Icons.star_border)),
            const SizedBox(width: 8),
            InkWell(
              onTap: _addAmenity,
              child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add, color: Colors.white)),
            ),
          ],
        ),
        if (hasError)
          const Padding(
            padding: EdgeInsets.only(top: 6, left: 12),
            child: Text("Required: Add at least one amenity",
                style: TextStyle(color: Colors.red, fontSize: 12)),
          ),
        const SizedBox(height: 8),
        if (_amenities.isNotEmpty)
          Wrap(
              spacing: 8,
              children: _amenities
                  .map((item) => Chip(
                      label: Text(item),
                      backgroundColor: Colors.orange.withOpacity(0.1),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeAmenity(item)))
                  .toList()),
      ],
    );
  }

  Widget _buildTextField(
      {required String label,
      IconData? icon,
      TextEditingController? controller,
      int maxLines = 1,
      TextInputType keyboardType = TextInputType.text,
      bool isRequired = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.grey, size: 22) : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        errorText:
            (_showErrors && isRequired && (controller?.text.isEmpty ?? true))
                ? "Required"
                : null,
      ),
    );
  }
}