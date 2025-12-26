import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_moving_animation.dart';
import 'package:portfolio_hesu/views/widgets/animation/section_opacity_animation.dart';
import 'package:portfolio_hesu/views/sections/hello/social_profiles.dart';

class Hello extends StatelessWidget {
  const Hello({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        final showImage = c.maxWidth >= 600;
        final screenHeight = MediaQuery.of(context).size.height;

        return SizedBox(
          height: screenHeight,
          child: Flex(
            direction: wide ? Axis.horizontal : Axis.vertical,
            mainAxisAlignment: wide
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: constraints.maxHeight,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          AnimatedTextKit(
                            animatedTexts: [
                              TypewriterAnimatedText(
                                "Hi! I'm Min He-su",
                                textStyle: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontSize: 40,
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                speed: const Duration(milliseconds: 120),
                                cursor: "┃",
                              ),
                            ],
                            totalRepeatCount: 1,
                            pause: Duration.zero,
                            displayFullTextOnTap: true,
                            stopPauseOnTap: true,
                          ),
                          const SizedBox(height: 15),
                          Flexible(
                            child: OpacityFade(
                              direction: OpacityFadeInDirection.fadein,
                              child: Text(
                                "Flutter Developer and Google Developer for Dart\n"
                                "자바 & 플러터(다트) 개발자이자, 앱개발자를 지향하고 있습니다.\n"
                                "플러터 개발자로써, 2년 이상 앱 개발자로써 활동해왔습니다.\n",
                                style: Theme.of(context).textTheme.bodyLarge,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          SectionAnimation(
                            direction: MovingFadeInDirection.bottomToTop,
                            child: OpacityFade(
                              direction: OpacityFadeInDirection.fadein,
                              child: SocialProfiles(num: 1),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              if (showImage)
                Expanded(
                  flex: 1,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                      child: Image.asset(
                        "assets/image/pixelphoto.png",
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
