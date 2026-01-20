import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class AdoptionPetCardSkeleton extends StatelessWidget {
  const AdoptionPetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
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
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              height: 200,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(width: 120, height: 24, color: Colors.white),
                      Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(width: 150, height: 16, color: Colors.white),
                  const SizedBox(height: 12),

                  Container(width: double.infinity, height: 14, color: Colors.white),
                  const SizedBox(height: 6),
                  Container(width: 200, height: 14, color: Colors.white),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(width: 50, height: 20, color: Colors.white),
                      const SizedBox(width: 8),
                      Container(width: 50, height: 20, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Container(width: double.infinity, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}