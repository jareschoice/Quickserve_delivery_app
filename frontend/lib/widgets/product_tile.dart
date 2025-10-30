// lib/widgets/product_tile.dart
import 'package:flutter/material.dart';

class ProductTile extends StatelessWidget {
  final String id;
  final String name;
  final int price;
  final String image;
  final VoidCallback onAdd;

  const ProductTile({
    super.key,
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(image, width: 64, height: 64, fit: BoxFit.cover),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('₦$price'),
        trailing: ElevatedButton(
          onPressed: onAdd,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          child: const Text('Add'),
        ),
      ),
    );
  }
}