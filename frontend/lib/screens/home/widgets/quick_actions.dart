import 'package:flutter/material.dart';
import '../../../utils/colors.dart';

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  static final List<_QuickItem> _items = [
    _QuickItem(
      "Restaurants",
      Icons.restaurant_menu,
      "https://images.unsplash.com/photo-1559339352-11d035aa65de?w=600&q=70",
    ),
    _QuickItem(
      "Shops",
      Icons.storefront,
      "https://images.unsplash.com/photo-1505238680356-667803448bb6?w=600&q=70",
    ),
    _QuickItem(
      "Pharmacies",
      Icons.local_pharmacy,
      "https://images.unsplash.com/photo-1584367369853-8b966cf2235f?w=600&q=70",
    ),
    _QuickItem(
      "Send Packages",
      Icons.local_shipping,
      "https://images.unsplash.com/photo-1549921296-3a6b2c5a8b00?w=600&q=70",
    ),
    _QuickItem(
      "Local Markets",
      Icons.shopping_basket,
      "https://images.unsplash.com/photo-1469536526925-9b5547cd7090?w=600&q=70",
    ),
    _QuickItem(
      "More",
      Icons.apps,
      "https://images.unsplash.com/photo-1541534401786-2077eed87a72?w=600&q=70",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: _items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: .95,
      ),
      itemBuilder: (_, i) => _QuickTile(item: _items[i]),
    );
  }
}

class _QuickItem {
  final String label;
  final IconData icon;
  final String bgImage;
  _QuickItem(this.label, this.icon, this.bgImage);
}

class _QuickTile extends StatelessWidget {
  final _QuickItem item;
  const _QuickTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(
          image: NetworkImage(item.bgImage),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(.25),
            BlendMode.darken,
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          alignment: Alignment.bottomLeft,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Icon(item.icon, color: AppColors.accentOrange, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
