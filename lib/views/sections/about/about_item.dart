import 'package:flutter/material.dart';

class buildTimelineItem extends StatefulWidget {
  final String title;
  final String subtitle;
  final String description;

  const buildTimelineItem({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
  });

  @override
  State<buildTimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<buildTimelineItem> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 30),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFF25A77C),
                    shape: BoxShape.circle,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 2,
                  height: 60,
                  color: const Color(0xFF25A77C),
                ),
              ],
            ),

            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 150),
                    style: TextStyle(
                      color: isHovered ? const Color(0xFF25A77C) : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    child: Text(widget.title),
                  ),

                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Color(0xFF25A77C),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    widget.description,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
