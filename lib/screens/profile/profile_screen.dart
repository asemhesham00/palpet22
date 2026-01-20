import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_colors.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../auth/login_screen.dart'; 
import 'widgets/profile_menu_item.dart';
import 'edit_profile_screen.dart'; 
import 'my_posts_screen.dart'; 
import 'favorites_screen.dart';
import 'my_bookings_screen.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = "loading...";
  String _username = ""; 
  String _photoUrl = "https://cdn-icons-png.flaticon.com/128/1077/1077114.png";
  int _postsCount = 0; 
  String _ratingDisplay = "0.0";
  int _bookingsCount = 0; 

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
            .collection('pets')
            .where('ownerId', isEqualTo: user.uid)
            .get();

        final ratingStats = await DatabaseService().getUserRatingStats(user.uid);
        double avg = ratingStats['average'];

        final bookingsCount = await DatabaseService().getUserBookingsCount(user.uid);

        if (mounted) {
          setState(() {
            if (userDoc.exists) {
              _name = userDoc['name'] ?? "palpet user";
              _username = userDoc['username'] ?? ""; 
            }
            _postsCount = postsSnapshot.docs.length;
            _ratingDisplay = avg.toStringAsFixed(1);
            _bookingsCount = bookingsCount; 
          });
        }
      } catch (e) {
        debugPrint("Error fetching user data: $e");
      }
    }
  }

  void _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("logout failure: $e")),
      );
    }
  }


  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text(
            "Are you sure you want to delete your account? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); 
              _executeDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }


  void _executeDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {

      await DatabaseService().deleteUserData(user.uid);


      await AuthService().deleteAccount();

      if (mounted) {

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Delete failed: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Container(
                  height: 180,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: NetworkImage(_photoUrl),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            
            Text(
              _name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            
            Text(
              _username.isNotEmpty ? "@$_username" : "",
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildStatCard("My Posts", _postsCount.toString()), 
                  const SizedBox(width: 16),
                  _buildStatCard("Bookings", _bookingsCount.toString()), 
                  const SizedBox(width: 16),
                  _buildStatCard("Rating", "$_ratingDisplay ★"),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "General",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  ProfileMenuItem(
                    title: "Edit Profile",
                    icon: Icons.person_outline,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                      );
                      if (result == true) {
                        _fetchUserData();
                      }
                    },
                  ),
                  
                  ProfileMenuItem(
                    title: "My Posts",
                    icon: Icons.article_outlined, 
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyPostsScreen()),
                      );
                      _fetchUserData();
                    },
                  ),

                  ProfileMenuItem(
                    title: "My Bookings",
                    icon: Icons.calendar_today_outlined,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MyBookingsScreen()),
                      );
                    },
                  ),
                  
                  ProfileMenuItem(
                    title: "Favorites",
                    icon: Icons.favorite_border,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FavoritesScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Settings",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 12),
                  

                  ProfileMenuItem(
                    title: "Delete Account",
                    icon: Icons.delete_outline,
                    isLogout: true,
                    onTap: _confirmDeleteAccount,
                  ),
                  const SizedBox(height: 12),
                  
                  ProfileMenuItem(
                    title: "Log Out",
                    icon: Icons.logout,
                    isLogout: true,
                    onTap: _handleLogout,
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}