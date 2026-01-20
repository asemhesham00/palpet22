import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import 'pet_details_screen.dart';
import 'widgets/adoption_pet_card.dart';
import 'widgets/adoption_pet_card_skeleton.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key});

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  late Stream<List<Pet>> _petsStream;
  String _searchQuery = "";
  String? _selectedType;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _petsStream = DatabaseService().getPets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.only(
                  top: 60, bottom: 30, left: 24, right: 24),
              decoration: const BoxDecoration(
                color: AppColors.adoptionHeader,
               
              ),
              child: Column(
                children: [
                  const Text(
                    "Find Your Perfect\nCompanion",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Browse pets looking for a forever\nhome",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textDark.withOpacity(0.7),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown(
                          hint: "Pet Type",
                          value: _selectedType,
                          items: ["All", "Dog", "Cat", "Bird", "Other"],
                          onChanged: (val) =>
                              setState(() => _selectedType = val),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown(
                          hint: "Gender",
                          value: _selectedGender,
                          items: ["All", "Male", "Female"],
                          onChanged: (val) =>
                              setState(() => _selectedGender = val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: "Search by name, breed...",
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.inputBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<List<Pet>>(
            stream: _petsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 0),
                      child: AdoptionPetCardSkeleton(),
                    ),
                    childCount: 3,
                  ),
                );
              }

              List<Pet> filteredPets = [];
              if (snapshot.hasData) {
                final allPets = snapshot.data!;
                filteredPets = allPets.where((pet) {
                  if (pet.postType.toLowerCase() != 'adoption') {
                    return false;
                  }
                  final matchesSearch = _searchQuery.isEmpty ||
                      pet.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()) ||
                      pet.breed
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase());
                  final matchesType = _selectedType == null ||
                      _selectedType == "All" ||
                      pet.type == _selectedType;
                  final matchesGender = _selectedGender == null ||
                      _selectedGender == "All" ||
                      pet.gender == _selectedGender;
                  return matchesSearch && matchesType && matchesGender;
                }).toList();
              }

              if (filteredPets.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 250,
                          width: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://i.pinimg.com/1200x/85/d6/fe/85d6fe2e402686d661019df7e4c09a30.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, _, __) => const Icon(
                                  Icons.pets,
                                  size: 80,
                                  color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          "No Friends Found!",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try adjusting your filters to find\nmore furry friends.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.textDark.withOpacity(0.6),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final pet = filteredPets[index];
                      return AdoptionPetCard(
                        ownerId: pet.ownerId,
                        name: pet.name,
                        age: pet.age,
                        gender: pet.gender,
                        breed: pet.breed,
                        description: pet.description,
                        imageUrl: pet.imageUrl,
                        tags: pet.healthTags,
                        onViewDetails: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    PetDetailsScreen(pet: pet)),
                          );
                        },
                      );
                    },
                    childCount: filteredPets.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint,
              style: const TextStyle(color: AppColors.textDark, fontSize: 14)),
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          value: value,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(item, style: const TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
