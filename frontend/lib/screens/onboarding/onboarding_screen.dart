import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quickserve/widgets/background_wrapper.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoAdvance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoAdvance() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_index < pages.length - 1) {
        _controller.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        timer.cancel();
      }
    });
  }

  final pages = [
    {
      'title': '🍔 Welcome to QuickServe',
      'subtitle': 'Your premium food delivery service is here!\nFast, reliable, and delicious meals delivered to your doorstep.',
      'emoji': '🍽️',
    },
    {
      'title': '⭐ Special Meals Daily',
      'subtitle': 'Discover our chef\'s special meals and exclusive offers every day.\nAuthentic flavors from top restaurants.',
      'emoji': '🍲',
    },
    {
      'title': '🚀 Get Started Now',
      'subtitle': 'Join thousands of satisfied customers.\nOrder now and taste the difference!',
      'emoji': '💯',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: pages.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Large emoji instead of logo
                        Text(
                          pages[i]['emoji']!,
                          style: const TextStyle(fontSize: 120),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          pages[i]['title']!,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          pages[i]['subtitle']!,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 3.0,
                                color: Colors.black45,
                              ),
                            ],
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (i) => Container(
                    margin: const EdgeInsets.all(4),
                    height: 8,
                    width: _index == i ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _index == i ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  onPressed: () {
                    if (_index < pages.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  child: Text(
                    _index == pages.length - 1 ? 'Get Started' : 'Next',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}