import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/pet.dart';
import '../../services/database_service.dart';

class LostFoundDetailsScreen extends StatefulWidget {
  final Pet pet;

  const LostFoundDetailsScreen({super.key, required this.pet});

  @override
  State<LostFoundDetailsScreen> createState() => _LostFoundDetailsScreenState();
}

class _LostFoundDetailsScreenState extends State<LostFoundDetailsScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isFavorite = false;
  bool _isCallClicked = false;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      bool isFav = await _dbService.isFavorite(user.uid, widget.pet.id);
      if (mounted) {
        setState(() {
          _isFavorite = isFav;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please login to add favorites")),
      );
      return;
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });

    try {
      await _dbService.toggleFavorite(user.uid, widget.pet.id);
    } catch (e) {
      setState(() {
        _isFavorite = !_isFavorite;
      });
      print("Error toggling favorite: $e");
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    setState(() {
      _isCallClicked = true;
    });
    try {
      await launchUrl(launchUri);
    } catch (e) {
      print("Error making call: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isCallClicked = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    
    String dateStr = "";
    if (pet.createdAt != null) {
        dateStr = DateFormat.yMMMd().format(pet.createdAt!);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back,
                color: AppColors.textDark, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.grey,
                size: 20,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
           
            SizedBox(
              height: 350,
              width: double.infinity,
              child: Image.network(
                pet.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),
            ),
            
           
            Container(
              transform: Matrix4.translationValues(0.0, -30.0, 0.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pet.type, 
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: pet.postType == 'Found' 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: pet.postType == 'Found' ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          pet.postType.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: pet.postType == 'Found' ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (dateStr.isNotEmpty)
                    Text(
                      "Posted on $dateStr",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  
                  const SizedBox(height: 24),

                  const Text("Description",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Text(
                    pet.description,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.textGrey, height: 1.5),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Row(
                    children: [
                      Expanded(child: _buildInfoItem("Breed", pet.breed)),
                     
                      Expanded(child: _buildInfoItem("Location Area", pet.location)),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                 
                  const Text("Exact Location",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(pet.location,
                            style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textGrey,
                                fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
              
                  const SizedBox(height: 30),
                  
              
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _makePhoneCall(pet.contactPhone),
                      icon: const Icon(Icons.phone),
                      label: const Text("Call Owner / Finder"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, color: AppColors.textGrey)),
      ],
    );
  }
}