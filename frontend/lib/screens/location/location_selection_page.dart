import 'package:flutter/material.dart';

class LocationSelectionPage extends StatefulWidget {
  final Function(String) onLocationSelected;

  const LocationSelectionPage({super.key, required this.onLocationSelected});

  @override
  State<LocationSelectionPage> createState() => _LocationSelectionPageState();
}

class _LocationSelectionPageState extends State<LocationSelectionPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedLocation = 'Lagos';

  final List<Map<String, dynamic>> _locations = [
    {
      'name': 'Lagos',
      'areas': [
        'Victoria Island',
        'Lekki',
        'Ikeja',
        'Surulere',
        'Yaba',
        'Maryland',
        'Ajah',
      ],
      'icon': '🏙️',
      'popular': true,
    },
    {
      'name': 'Abuja',
      'areas': ['Garki', 'Wuse', 'Maitama', 'Asokoro', 'Gwarinpa'],
      'icon': '🏛️',
      'popular': true,
    },
    {
      'name': 'Port Harcourt',
      'areas': ['GRA', 'Trans Amadi', 'Old Port Harcourt', 'Diobu'],
      'icon': '🌊',
      'popular': false,
    },
    {
      'name': 'Kano',
      'areas': ['Fagge', 'Nassarawa', 'Gwale', 'Dala'],
      'icon': '🏜️',
      'popular': false,
    },
    {
      'name': 'Ibadan',
      'areas': ['UI', 'Bodija', 'Ring Road', 'Challenge'],
      'icon': '🌳',
      'popular': false,
    },
  ];

  final List<Map<String, dynamic>> _filters = [
    {'name': 'Free Delivery', 'icon': '🚚', 'active': false},
    {'name': 'Fast Food', 'icon': '🍔', 'active': false},
    {'name': 'Nigerian Food', 'icon': '🍲', 'active': true},
    {'name': 'Pizza', 'icon': '🍕', 'active': false},
    {'name': 'Chinese', 'icon': '🥡', 'active': false},
    {'name': 'Healthy', 'icon': '🥗', 'active': false},
  ];

  final List<Map<String, dynamic>> _promos = [
    {
      'title': '50% Off First Order',
      'subtitle': 'Valid for new users only',
      'color': Colors.red,
      'icon': '🎉',
    },
    {
      'title': 'Free Delivery Weekend',
      'subtitle': 'No minimum order required',
      'color': Colors.green,
      'icon': '🚚',
    },
    {
      'title': 'Buy 2 Get 1 Free',
      'subtitle': 'On selected restaurants',
      'color': Colors.orange,
      'icon': '🍔',
    },
  ];

  List<Map<String, dynamic>> get filteredLocations {
    if (_searchController.text.isEmpty) {
      return _locations;
    }
    return _locations.where((location) {
      return location['name'].toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ) ||
          location['areas'].any(
            (area) => area.toLowerCase().contains(
              _searchController.text.toLowerCase(),
            ),
          );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.onLocationSelected(_selectedLocation);
              Navigator.pop(context);
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search for your city or area...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear, color: Colors.grey),
                    ),
                ],
              ),
            ),

            // Current Location Button
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () {
                  // Simulate GPS location detection
                  setState(() {
                    _selectedLocation = 'Current Location (Lagos)';
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('📍 Location detected: Lagos, Nigeria'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Current Location',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Auto-detect your location',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Popular Cities Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Popular Cities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            // Cities List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredLocations.length,
              itemBuilder: (context, index) {
                final location = filteredLocations[index];
                final isSelected = _selectedLocation == location['name'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedLocation = location['name'];
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? Colors.green
                              : Colors.grey.withOpacity(0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              location['icon'],
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      location['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.green
                                            : Colors.black,
                                      ),
                                    ),
                                    if (location['popular']) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.orange,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Popular',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  location['areas'].take(3).join(', ') +
                                      (location['areas'].length > 3
                                          ? '...'
                                          : ''),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Filters Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Food Preferences',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final filter = _filters[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _filters[index]['active'] =
                              !_filters[index]['active'];
                        });
                      },
                      borderRadius: BorderRadius.circular(25),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: filter['active'] ? Colors.green : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: filter['active']
                                ? Colors.green
                                : Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter['icon'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              filter['name'],
                              style: TextStyle(
                                color: filter['active']
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Promos Section
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Current Promotions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _promos.length,
              itemBuilder: (context, index) {
                final promo = _promos[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: promo['color'].withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: promo['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          promo['icon'],
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              promo['title'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              promo['subtitle'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: promo['color'],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
