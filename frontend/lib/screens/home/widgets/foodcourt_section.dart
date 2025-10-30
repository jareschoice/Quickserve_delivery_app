import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class FoodCourtSection extends StatelessWidget {
  const FoodCourtSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _FoodItem(
        "Mega Burger",
        "https://images.unsplash.com/photo-1550547660-d9450f859349?w=1200&q=80",
        2500,
        "20–30 min",
        4.6,
      ),
      _FoodItem(
        "Shawarma Pro",
        "https://images.unsplash.com/photo-1606756790138-261fa0ae3d3d?w=1200&q=80",
        1800,
        "25–35 min",
        4.5,
      ),
      _FoodItem(
        "Family Pizza",
        "https://images.unsplash.com/photo-1548365328-9f547fb0953d?w=1200&q=80",
        5200,
        "30–40 min",
        4.7,
      ),
      _FoodItem(
        "Fried Rice Pack",
        "https://images.unsplash.com/photo-1612872087720-bb876e3c1d1d?w=1200&q=80",
        1600,
        "20–30 min",
        4.4,
      ),
    ];

    return SizedBox(
      height: 210,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _FoodCard(item: items[i]),
      ),
    );
  }
}

class _FoodItem {
  final String name, img, eta;
  final int price;
  final double rating;
  _FoodItem(this.name, this.img, this.price, this.eta, this.rating);
}

class _FoodCard extends StatelessWidget {
  final _FoodItem item;
  const _FoodCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.network(
              item.img,
              height: 120,
              width: 260,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Text(
                  "₦${item.price}",
                  style: const TextStyle(
                    color: AppColors.accentOrange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  "${item.rating}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.timer_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  item.eta,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textDark,
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
