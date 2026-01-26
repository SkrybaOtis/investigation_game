import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  
  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
  });
  
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class EpisodeCardShimmer extends StatelessWidget {
  const EpisodeCardShimmer({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ShimmerLoading(height: 150, borderRadius: 8),
            const SizedBox(height: 12),
            const ShimmerLoading(height: 24, width: 200),
            const SizedBox(height: 8),
            ShimmerLoading(height: 16, width: MediaQuery.of(context).size.width * 0.6),
            const SizedBox(height: 8),
            const ShimmerLoading(height: 16, width: 100),
          ],
        ),
      ),
    );
  }
}

class EpisodeListShimmer extends StatelessWidget {
  final int itemCount;
  
  const EpisodeListShimmer({super.key, this.itemCount = 5});
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => const EpisodeCardShimmer(),
    );
  }
}