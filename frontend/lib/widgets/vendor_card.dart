// lib/widgets/vendor_card.dart
import 'package:flutter/material.dart';

class VendorCard extends StatelessWidget {
  final String id;
  final String name;
  final String image;
  final String eta;
  final double rating;
  final VoidCallback onTap;

  const VendorCard({
    super.key,
    required this.id,
    required this.name,
    required this.image,
    required this.eta,
    required this.rating,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(image, width: 64, height: 64, fit: BoxFit.cover),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$eta • ${rating.toStringAsFixed(1)} ★'),
        trailing: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Open'),
        ),
      ),
    );
  }
}