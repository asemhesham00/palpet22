import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/database_service.dart';

class ClinicCard extends StatelessWidget {
  final String clinicId;
  final String ownerId;
  final String name;
  final String address;
  final String imageUrl;
  final bool isOpen;
  final VoidCallback onTap;

  const ClinicCard({
    super.key,
    required this.clinicId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.isOpen,
    required this.onTap,
  });

  bool get _isLocalAsset =>
      imageUrl.startsWith('assets/') || imageUrl.startsWith('lib/');

  bool get _isDefaultIcon {
    return _isLocalAsset ||
        imageUrl.contains('flaticon') ||
        imageUrl.contains('discordapp') ||
        imageUrl.contains('placeholder');
  }

  Widget _buildImage(String path, BoxFit fit) {
    if (_isLocalAsset) {
      return Image.asset(
        path,
        fit: fit,
        errorBuilder: (c, e, s) =>
            const Icon(Icons.local_hospital, size: 50, color: Colors.grey),
      );
    }
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (c, e, s) =>
          Container(height: 180, color: Colors.grey[200]),
    );
  }

  void _showOwnerProfile(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: FutureBuilder<List<dynamic>>(
              future: Future.wait([
                DatabaseService().getUser(ownerId),
                DatabaseService().getUserRatingStats(ownerId),
                DatabaseService().getUserPostCount(ownerId),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(
                      height: 100,
                      child: Center(child: Text("Unable to load user info")));
                }

                final userDoc = snapshot.data![0] as DocumentSnapshot;
                final ratingData = snapshot.data![1] as Map<String, dynamic>;
                final postCount = snapshot.data![2] as int;

                final userData = userDoc.data() as Map<String, dynamic>?;
                final String userName = userData?['name'] ?? 'Unknown User';
                final String? userImage =
                    userData?['photoUrl'] ?? userData?['image'];
                final double rating = ratingData['average'] ?? 0.0;
                final int reviewCount = ratingData['count'] ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: userImage != null && userImage.isNotEmpty
                          ? NetworkImage(userImage)
                          : null,
                      child: (userImage == null || userImage.isEmpty)
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(userName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark)),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                            "${rating.toStringAsFixed(1)} ($reviewCount reviews)",
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text("$postCount",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                          const Text("Posts Published",
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"))),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isIcon = _isDefaultIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => _showOwnerProfile(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.person_outline,
                            size: 16, color: Colors.black87),
                        SizedBox(width: 4),
                        Text("Owner",
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: DatabaseService().getItemRatingStats(clinicId),
                    builder: (context, snapshot) {
                      String ratingText = "-.-";
                      if (snapshot.hasData) {
                        double avg = snapshot.data!['average'] ?? 0.0;
                        int count = snapshot.data!['count'] ?? 0;
                        if (count > 0) {
                          ratingText = avg.toStringAsFixed(1);
                        } else {
                          ratingText = "New";
                        }
                      }
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            ratingText,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: Container(
              height: 180,
              width: double.infinity,
              color: isIcon
                  ? AppColors.primary.withOpacity(0.05)
                  : Colors.grey[100],
              child: isIcon
                  ? Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: _buildImage(imageUrl, BoxFit.contain),
                    )
                  : _buildImage(imageUrl, BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOpen ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isOpen ? "Open" : "Closed",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: const Text("View Details",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}