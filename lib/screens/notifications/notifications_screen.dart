import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../services/database_service.dart';
import '../../data/models/pet.dart';

import '../adoption/pet_details_screen.dart';
import '../lost_found/lost_found_details_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllAsRead() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final batch = FirebaseFirestore.instance.batch();
    final snapshots = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }


  void _handleNotificationTap(BuildContext context, Map<String, dynamic> item) async {

    if (item['isRead'] == false) {
      FirebaseFirestore.instance
          .collection('notifications')
          .doc(item['id'])
          .update({'isRead': true});
    }

    String? petId = item['petId'];
    if (petId == null) return;


    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {

      Pet? pet = await DatabaseService().getPetById(petId);
      
      if (context.mounted) {
        Navigator.pop(context); 

        if (pet != null) {

          if (pet.postType == 'Adoption') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PetDetailsScreen(pet: pet)),
            );
          } else if (pet.postType == 'Lost' || pet.postType == 'Found') {
             Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LostFoundDetailsScreen(pet: pet)), 
            );
          } else {
             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("التفاصيل غير متاحة لهذا النوع")));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("هذا المنشور لم يعد موجوداً")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  String _timeAgo(Timestamp? timestamp) {
    if (timestamp == null) return "Just now";
    final date = timestamp.toDate();
    final difference = DateTime.now().difference(date);
    if (difference.inDays > 0) return "${difference.inDays} days ago";
    if (difference.inHours > 0) return "${difference.inHours} hours ago";
    if (difference.inMinutes > 0) return "${difference.inMinutes} min ago";
    return "Just now";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text("Mark all read", style: TextStyle(color: AppColors.primary)),
          )
        ],
      ),
      body: uid == null
          ? const Center(child: Text("Please login"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SelectableText(
                        "Database Error (Index needed):\n${snapshot.error}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final item = {
                      ...data,
                      'id': docs[index].id,
                      'time': _timeAgo(data['createdAt']),
                    };
                    return _buildNotificationCard(context, item);
                  },
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No notifications yet", style: TextStyle(fontSize: 18, color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, Map<String, dynamic> item) {
    bool isRead = item['isRead'] ?? false;
    String type = item['type'] ?? 'default';

    return InkWell(
      onTap: () => _handleNotificationTap(context, item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFF5F9FF),
          border: Border.all(
            color: isRead ? Colors.grey[200]! : AppColors.primary.withOpacity(0.3),
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getIconColor(type).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_getIconData(type), color: _getIconColor(type), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['title'] ?? "No Title",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['body'] ?? "",
                    style: const TextStyle(fontSize: 14, color: AppColors.textGrey, height: 1.4),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item['time'],
                    style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getIconColor(String type) {
    if (type == 'lost_alert') return Colors.redAccent;
    if (type == 'found_match') return Colors.green;
    return AppColors.primary;
  }

  IconData _getIconData(String type) {
    if (type == 'lost_alert') return Icons.warning_amber_rounded;
    if (type == 'found_match') return Icons.check_circle_outline;
    return Icons.notifications_outlined;
  }
}