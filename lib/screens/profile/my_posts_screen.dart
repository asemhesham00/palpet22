import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';
import '../add_post/add_post_screen.dart';
import '../adoption/pet_details_screen.dart';
import '../lost_found/lost_found_details_screen.dart';
import '../hotel/hotel_details_screen.dart';

import '../adoption/widgets/adoption_pet_card.dart';
import '../lost_found/widgets/lost_found_card.dart';
import '../hotel/widgets/hotel_card.dart';

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final _databaseService = DatabaseService();
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  void _deletePost(String petId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _databaseService.deletePet(petId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Post deleted successfully")),
                );
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editPost(Pet pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPostScreen(
          petToEdit: pet,
        ),
      ),
    );
  }

  void _openPostDetails(Pet pet) {
    if (pet.postType == 'Adoption') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => PetDetailsScreen(pet: pet)),
      );
    } else if (pet.postType == 'Lost' || pet.postType == 'Found') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => LostFoundDetailsScreen(pet: pet)),
      );
    } else if (pet.postType == 'Hotel') {
      Map<String, dynamic> hotelData = pet.toMap();
      hotelData['id'] = pet.id;
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => HotelDetailsScreen(data: hotelData)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: Text("Please log in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("My Posts",
            style: TextStyle(
                color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
      ),
      body: StreamBuilder<List<Pet>>(
        stream: _databaseService.getUserPets(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          final pets = snapshot.data ?? [];

          if (pets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.post_add, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("You haven't posted anything yet.",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pets.length,
            itemBuilder: (context, index) {
              final pet = pets[index];
              return _buildWrapperCard(pet);
            },
          );
        },
      ),
    );
  }

  Widget _buildWrapperCard(Pet pet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    pet.postType.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz,
                      color: Colors.grey, size: 28),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editPost(pet);
                    } else if (value == 'delete') {
                      _deletePost(pet.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _getOriginalCardWidget(pet),
        ],
      ),
    );
  }

  Widget _getOriginalCardWidget(Pet pet) {
    if (pet.postType == 'Adoption') {
      return AdoptionPetCard(
        ownerId: pet.ownerId,
        name: pet.name,
        age: pet.age,
        gender: pet.gender,
        breed: pet.breed,
        description: pet.description,
        imageUrl: pet.imageUrl,
        tags: pet.healthTags,
        onViewDetails: () => _openPostDetails(pet),
      );
    } else if (pet.postType == 'Lost' || pet.postType == 'Found') {
      String formattedDate = pet.createdAt != null
          ? DateFormat('yyyy-MM-dd').format(pet.createdAt!)
          : 'Unknown Date';

      return LostFoundCard(
        name: pet.name,
        ownerId: pet.ownerId,
        date: formattedDate,
        location: pet.location,
        imageUrl: pet.imageUrl,
        isLost: pet.postType == 'Lost',
        onViewDetails: () => _openPostDetails(pet),
      );
    } else if (pet.postType == 'Hotel') {
      List<String> supported =
          pet.type.split(',').map((e) => e.trim()).toList();
      return HotelCard(
        petId: pet.id,
        name: pet.name,
        address: pet.location,
        imageUrl: pet.imageUrl,
        description: pet.description,
        supportedPets: supported,
        ownerId: pet.ownerId,
        onTap: () => _openPostDetails(pet),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      height: 100,
      color: Colors.white,
      child: Center(child: Text("Unknown Post Type: ${pet.postType}")),
    );
  }
}
