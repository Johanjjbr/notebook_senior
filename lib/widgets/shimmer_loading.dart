import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerList extends StatelessWidget {
  final int itemCount;

  const ShimmerList({super.key, this.itemCount = 5});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerGrid extends StatelessWidget {
  final int crossAxisCount;

  const ShimmerGrid({super.key, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: 6,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class ShimmerForm extends StatelessWidget {
  const ShimmerForm({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: double.infinity, height: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 16),
            Container(width: double.infinity, height: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            const SizedBox(height: 24),
            Container(width: 100, height: 20, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 12),
            Row(children: [
              ...List.generate(6, (_) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8))),
              )),
            ]),
          ],
        ),
      ),
    );
  }
}
