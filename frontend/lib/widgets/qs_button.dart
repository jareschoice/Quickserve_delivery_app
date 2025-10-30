import 'package:flutter/material.dart';

class QSButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool loading;

  const QSButton({super.key, required this.text, required this.onPressed, this.loading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        child: loading ? const CircularProgressIndicator() : Text(text),
      ),
    );
  }
}
