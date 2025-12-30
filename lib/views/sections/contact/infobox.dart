import 'package:flutter/material.dart';

Widget infoBox({
  required IconData icon,
  required String title,
  required String value,
}) {
  return Row(
    children: [
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFF25A77C),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(10),
        child: Icon(icon, color: Colors.white),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Colors.white70),
          ),
        ],
      ),
    ],
  );
}
