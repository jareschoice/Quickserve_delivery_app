import 'dart:async';
import 'package:flutter/material.dart';

class ExploreCarousel extends StatefulWidget {
  const ExploreCarousel({super.key});

  @override
  State<ExploreCarousel> createState() => _ExploreCarouselState();
}

class _ExploreCarouselState extends State<ExploreCarousel> {
  final ScrollController _controller = ScrollController();
  Timer? _timer;
  double _offset = 0;

  final List<String> logos = [
    "https://upload.wikimedia.org/wikipedia/commons/6/6a/JavaScript-logo.png",
    "https://upload.wikimedia.org/wikipedia/commons/1/19/Coca-Cola_logo.svg",
    "https://upload.wikimedia.org/wikipedia/commons/a/a6/Logo_NIKE.svg",
    "https://upload.wikimedia.org/wikipedia/commons/2/2f/Google_2015_logo.svg",
    "https://upload.wikimedia.org/wikipedia/commons/4/44/McDonald%27s_Golden_Arches.svg",
    "https://upload.wikimedia.org/wikipedia/commons/f/fa/Apple_logo_black.svg",
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_controller.hasClients) return;
      final max = _controller.position.maxScrollExtent;
      _offset += 160; // move by about 2 items
      if (_offset > max) _offset = 0;
      _controller.animateTo(
        _offset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        itemCount: logos.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          return CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(logos[i], fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
