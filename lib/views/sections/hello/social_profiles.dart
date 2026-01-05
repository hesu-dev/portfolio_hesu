import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialProfiles extends StatelessWidget {
  final int num;
  const SocialProfiles({super.key, required this.num});

  // _pill('X/Twitter', Uri.parse('https://x.com/yourname')),
  // _pill(
  //   'YouTube',
  //   Uri.parse('https://youtube.com/@yourname'),
  // ),

  @override
  Widget build(BuildContext context) {
    return num == 0
        ? Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              pill('GitHub', Uri.parse('https://github.com/hesu-dev')),
              // pill('LinkedIn', Uri.parse('https://linkedin.com/in/yourname')),
              pill('velog', Uri.parse('https://velog.io/@hs0647/posts')),
              pill('Email', Uri.parse('mailto:hs0647@naver.com')),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: socials.map((s) {
              return GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(s.url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(s.icon, size: 28, color: Colors.grey.shade500),
                ),
              );
            }).toList(),
          );
  }

  static Widget pill(String label, Uri uri) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.north_east, size: 14),
        ],
      ),
      onPressed: () => launchUrl(uri, mode: LaunchMode.externalApplication),
    );
  }
}

class _SocialItem {
  final IconData icon;
  final String url;

  _SocialItem({required this.icon, required this.url});
}

final List<_SocialItem> socials = [
  _SocialItem(
    icon: FontAwesomeIcons.github,
    url: "https://github.com/hesu-dev/",
  ),
  _SocialItem(
    icon: FontAwesomeIcons.blog,
    url: "https://velog.io/@hs0647/posts",
  ),
  _SocialItem(
    icon: FontAwesomeIcons.linkedin,
    url: "https://www.linkedin.com/in/%ED%9D%AC%EC%88%98-%EB%AF%BC-938105237/",
  ),
  // _SocialItem(icon: FontAwesomeIcons.twitter, url: "https://x.com/sukenelll"),
  _SocialItem(icon: Icons.mail, url: "mailto:hs0647@naver.com"),
  // _SocialItem(
  //   icon: FontAwesomeIcons.instagram,
  //   url: "https://www.instagram.com/nelll_014/",
  // ),

  // _SocialItem(icon: Icons.calendar_today, url: "https://calendly.com/yourname"),
];
