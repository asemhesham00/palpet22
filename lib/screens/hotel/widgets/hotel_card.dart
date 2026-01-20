import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/database_service.dart';

class HotelCard extends StatelessWidget {
  final String petId;
  final String ownerId;
  final String name;
  final String address;
  final String imageUrl;
  final String description;
  final List<String> supportedPets;

  final VoidCallback onTap;

  const HotelCard({
    super.key,
    required this.petId,
    required this.ownerId,
    required this.name,
    required this.address,
    required this.imageUrl,
    required this.description,
    required this.supportedPets,
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
            const Icon(Icons.apartment, size: 50, color: Colors.grey),
      );
    }
    return Image.network(
      path,
      fit: fit,
      errorBuilder: (c, e, s) => Container(
        height: 200,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image, color: Colors.grey),
      ),
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
            color: Colors.black.withOpacity(0.05),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
                FutureBuilder<Map<String, dynamic>>(
                  future: DatabaseService().getItemRatingStats(petId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();

                    final double rating = snapshot.data!['average'] ?? 0.0;
                    final int count = snapshot.data!['count'] ?? 0;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            count > 0 ? rating.toStringAsFixed(1) : "New",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.zero,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  color: isIcon
                      ? Colors.orange.withOpacity(0.05)
                      : Colors.grey[100],
                  child: isIcon
                      ? Padding(
                          padding: const EdgeInsets.all(30.0),
                          child: _buildImage(imageUrl, BoxFit.contain),
                        )
                      : _buildImage(imageUrl, BoxFit.cover),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 14, color: AppColors.textGrey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "Supported: ${supportedPets.isEmpty ? 'All' : supportedPets.join(', ')}",
                  style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textGrey,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(fontSize: 14, color: AppColors.textGrey),
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
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "View Details",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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