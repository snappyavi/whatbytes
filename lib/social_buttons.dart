
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SocialButtons extends StatelessWidget {
  const SocialButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialIcon(Icons.facebook, Colors.blue),
        const SizedBox(width: 16),
        _socialIcon(Icons.g_mobiledata, Colors.red),
        const SizedBox(width: 16),
        _socialIcon(Icons.apple, Colors.black),
      ],
    );
  }

  Widget _socialIcon(IconData icon, Color color) {
    return CircleAvatar(
      backgroundColor: color,
      child: Icon(icon, color: Colors.white),
    );
  }
}
