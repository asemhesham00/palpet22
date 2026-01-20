import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import 'widgets/hotel_card.dart';
import 'hotel_details_screen.dart';
import 'widgets/hotel_card_skeleton.dart';

class PetHotelsScreen extends StatefulWidget {
  const PetHotelsScreen({super.key});

  @override
  State<PetHotelsScreen> createState() => _PetHotelsScreenState();
}

class _PetHotelsScreenState extends State<PetHotelsScreen> {
  String? _selectedPetType;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late Stream<List<Pet>> _hotelsStream;

  @override
  void initState() {
    super.initState();
    _hotelsStream = DatabaseService().getPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildFilters(),
            _buildListStream(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(50),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFEF6C00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Pet Hotels",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Find the perfect stay for your furry friend",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedPetType,
                hint: const Text(" Pet Type"),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: ["All Types", "Dog", "Cat", "Bird", "Rabbit", "Other"]
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {
                  setState(() => _selectedPetType = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
            decoration: InputDecoration(
              hintText: "Search by name or location...",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.white,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListStream() {
    return StreamBuilder<List<Pet>>(
      stream: _hotelsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) => const HotelCardSkeleton(),
          );
        }

        List<Pet> displayList = [];
        if (snapshot.hasData) {
          final allPets = snapshot.data!;
          displayList = allPets.where((pet) {
            if (pet.postType != 'Hotel') return false;

            if (_selectedPetType != null && _selectedPetType != "All Types") {
              final List<String> supportedTypes =
                  pet.type.split(',').map((e) => e.trim()).toList();
              if (!supportedTypes.contains(_selectedPetType)) {
                return false;
              }
            }

            if (_searchQuery.isNotEmpty) {
              final query = _searchQuery.toLowerCase();
              final name = pet.name.toLowerCase();
              final location = pet.location.toLowerCase();

              if (!name.contains(query) && !location.contains(query)) {
                return false;
              }
            }
            return true;
          }).toList();
        }

        if (displayList.isEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 40, bottom: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hotel_class, size: 60, color: Colors.grey),
                const SizedBox(height: 24),
                const Text(
                  "No Hotels Found",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Try adjusting your filters to find\nthe perfect stay.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayList.length,
            itemBuilder: (context, index) {
              final pet = displayList[index];
              List<String> supported =
                  pet.type.split(',').map((e) => e.trim()).toList();
              return HotelCard(
                petId: pet.id,
                name: pet.name,
                address: pet.location,
                ownerId: pet.ownerId,
                imageUrl: pet.imageUrl,
                description: pet.description,
                supportedPets: supported,
                onTap: () {
                  Map<String, dynamic> hotelData = pet.toMap();
                  hotelData['id'] = pet.id;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HotelDetailsScreen(data: hotelData),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}
