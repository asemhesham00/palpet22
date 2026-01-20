import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HotelCardSkeleton extends StatelessWidget {
  const HotelCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              height: 180,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                      Container(width: 150, height: 20, color: Colors.white),
                      Container(width: 50, height: 20, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(width: 100, height: 14, color: Colors.white),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                      const SizedBox(width: 8),
                      Container(width: 60, height: 24, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}