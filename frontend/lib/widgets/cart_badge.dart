// lib/widgets/cart_badge.dart
import 'package:flutter/material.dart';

class CartBadge extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const CartBadge({super.key, required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(icon: const Icon(Icons.shopping_cart), onPressed: onTap),
        if (count > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
              child: Text('$count', style: const TextStyle(color: Colors.white, fontSize: 11)),
            ),
          )
      ],
    );
  }
}