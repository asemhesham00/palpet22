import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import '../add_post/add_post_screen.dart';
import 'widgets/lost_found_card.dart';
import 'lost_found_details_screen.dart';
import 'widgets/lost_found_card_skeleton.dart';

class LostFoundScreen extends StatefulWidget {
  const LostFoundScreen({super.key});

  @override
  State<LostFoundScreen> createState() => _LostFoundScreenState();
}

class _LostFoundScreenState extends State<LostFoundScreen> {
  int _selectedFilterIndex = 0;
  String? _selectedPetType;
  String _searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  late Stream<List<Pet>> _petsStream;

  @override
  void initState() {
    super.initState();
    _petsStream = DatabaseService().getPets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Unknown Date";
    return "${date.day}/${date.month}/${date.year}";
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
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.bannerGradientStart, AppColors.bannerGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          const Text(
            "Lost & Found",
            style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark),
          ),
          const SizedBox(height: 8),
          Text(
            "Report lost pets or help reunite\nfound animals with their owners",
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark.withOpacity(0.7),
                height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  context,
                  "Report Lost Pet",
                  AppColors.lostRed,
                  Icons.warning_amber_rounded,
                  'Lost',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  context,
                  "Report Found Pet",
                  AppColors.foundGreen,
                  Icons.check_circle_outline,
                  'Found',
                ),
              ),
            ],
          )
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
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                _buildTabItem("All Alerts", 0),
                _buildTabItem("Lost Pets", 1, activeColor: AppColors.lostRed),
                _buildTabItem("Found Pets", 2,
                    activeColor: AppColors.foundGreen),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
                hint: const Text("Pet Type"),
                icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                items: [
                  "All Pet Types",
                  "Dog",
                  "Cat",
                  "Bird",
                  "Rabbit",
                  "Other"
                ]
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
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
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
      stream: _petsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 3,
            itemBuilder: (context, index) => const LostFoundCardSkeleton(),
          );
        }

        List<Pet> displayList = [];
        if (snapshot.hasData) {
          final allPets = snapshot.data!;
          displayList = allPets.where((pet) {
            if (!['Lost', 'Found', 'lost', 'found'].contains(pet.postType)) {
              return false;
            }

            if (_selectedFilterIndex == 1 &&
                pet.postType.toLowerCase() != 'lost') return false;
            if (_selectedFilterIndex == 2 &&
                pet.postType.toLowerCase() != 'found') return false;

            if (_selectedPetType != null &&
                _selectedPetType != "All Pet Types" &&
                pet.type != _selectedPetType) return false;

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
                Container(
                  height: 200,
                  width: 200,
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
                      errorBuilder: (ctx, _, __) => const Icon(Icons.search_off,
                          size: 60, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "No Posts Yet!",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Great news! No missing pets reported\nin this category.",
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
              final bool isLost = pet.postType.toLowerCase() == 'lost';
              final String formattedDate = _formatDate(pet.createdAt);

              return LostFoundCard(
                name: pet.name,
                ownerId: pet.ownerId,
                date: formattedDate,
                location: pet.location,
                imageUrl: pet.imageUrl,
                isLost: isLost,
                onViewDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LostFoundDetailsScreen(pet: pet),
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

  Widget _buildActionButton(BuildContext context, String label, Color color,
      IconData icon, String postType) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPostScreen(initialPostType: postType),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 6),
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int index,
      {Color activeColor = AppColors.textDark}) {
    final bool isSelected = _selectedFilterIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilterIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 4)
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isSelected ? activeColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
