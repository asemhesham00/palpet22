import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/database_service.dart';

class PetCard extends StatelessWidget {
  final String ownerId;
  final String name;
  final String breed;
  final String gender;
  final String age;
  final String description;
  final String imageUrl;
  final VoidCallback onTap;

  const PetCard({
    super.key,
    required this.ownerId,
    required this.name,
    required this.breed,
    required this.gender,
    required this.age,
    required this.description,
    required this.imageUrl,
    required this.onTap,
  });

  bool get _isLocalAsset {
    return imageUrl.startsWith('assets/') || imageUrl.startsWith('lib/');
  }

  bool get _isDefaultIcon {
    return _isLocalAsset ||
        imageUrl.contains('flaticon') ||
        imageUrl.contains('discordapp') ||
        imageUrl.contains('placeholder');
  }

  Widget _buildImage() {
    if (_isLocalAsset) {
      return Image.asset(
        imageUrl,
        fit: _isDefaultIcon ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) {
          return const Center(
            child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    } else {
      return Image.network(
        imageUrl,
        fit: _isDefaultIcon ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (ctx, error, stackTrace) {
          return Container(
            color: Colors.grey[100],
            child: const Icon(Icons.broken_image, size: 40, color: Colors.grey),
          );
        },
      );
    }
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
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(
                    height: 100,
                    child: Center(child: Text("Unable to load user info")),
                  );
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
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
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
                          Text(
                            "$postCount",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const Text(
                            "Posts Published",
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Close"),
                      ),
                    )
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
    final isMale = gender.toLowerCase() == 'male';
    final genderBgColor = isMale ? Colors.blue[50] : Colors.pink[50];
    final genderTextColor = isMale ? Colors.blue : Colors.pink;

    final bool isIcon = _isDefaultIcon;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                        Text(
                          "Owner",
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: AspectRatio(
              aspectRatio: 1.5,
              child: Container(
                color: isIcon
                    ? AppColors.primary.withOpacity(0.05)
                    : Colors.grey[100],
                child: isIcon
                    ? Padding(
                        padding: const EdgeInsets.all(30.0),
                        child: _buildImage(),
                      )
                    : _buildImage(),
              ),
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
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: genderBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        gender,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: genderTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      breed,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const CircleAvatar(radius: 2, backgroundColor: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      age,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark.withOpacity(0.6),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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