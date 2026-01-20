import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/sections/contact/infobox.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_moving_animation.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';

class CustomFooter extends StatelessWidget {
  const CustomFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.grey[300];
    final isCompact = MediaQuery.of(context).size.width < 1000;

    return Container(
      color: const Color.fromARGB(24, 33, 33, 33),
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OpacityFade(
            direction: OpacityFadeInDirection.fadein,
            child: Text(
              "Contact",
              textAlign: TextAlign.left,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 60),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (!isCompact)
                SectionAnimation(
                  direction: MovingFadeInDirection.leftToRight,
                  child: infoBox(
                    icon: Icons.location_on_rounded,
                    title: "Location",
                    value: "Seoul, South Korea",
                  ),
                ),

              SectionAnimation(
                direction: MovingFadeInDirection.rightToLeft,
                child: infoBox(
                  icon: Icons.mail_rounded,
                  title: "Email",
                  value: "hs0647@naver.com",
                ),
              ),
              if (!isCompact)
                SectionAnimation(
                  direction: MovingFadeInDirection.leftToRight,
                  child: infoBox(
                    icon: Icons.location_on_rounded,
                    title: "Number",
                    value: "-",
                  ),
                ),
            ],
          ),

          const SizedBox(height: 30),
          Divider(color: Colors.grey[700]),
          const SizedBox(height: 20),
          Text(
            "This website is built with Flutter. | © 2025 hesu. All Rights Reserved.",
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
