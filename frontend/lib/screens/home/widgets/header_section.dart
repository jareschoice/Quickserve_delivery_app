import 'package:flutter/material.dart';
import '../../../utils/colors.dart';
import '../../location_screen.dart';

class HeaderSection extends StatelessWidget {
  final String currentLocation;
  const HeaderSection({super.key, required this.currentLocation});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Location (tap to edit)
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LocationScreen()),
              );
            },
            child: Row(
              children: [
                const Icon(Icons.location_on, color: AppColors.primaryGreen),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    currentLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bag icon with small "+"
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(
                  color: AppColors.primaryGreen.withOpacity(.2),
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(10),
              child: const Icon(
                Icons.shopping_bag_outlined,
                color: AppColors.textDark,
              ),
            ),
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                height: 18,
                width: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.accentOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Text(
                  "+",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
