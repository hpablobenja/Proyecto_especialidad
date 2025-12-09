// lib/presentation/widgets/back_home_button.dart

import 'package:flutter/material.dart';

class BackHomeButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isVisible;

  const BackHomeButton({Key? key, this.onPressed, this.isVisible = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    void handlePress() {
      if (onPressed != null) {
        onPressed!();
      } else {
        Navigator.of(context).pop();
      }
    }

    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      child: GestureDetector(
        onTap: handlePress,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back,
            //color: Color.fromARGB(221, 171, 82, 82),
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
