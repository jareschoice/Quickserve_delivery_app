import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const SectionTitle({super.key, required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        if (onSeeAll != null)
          TextButton(onPressed: onSeeAll, child: const Text("See all")),
      ],
    );
  }
}
