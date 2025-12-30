// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:portfolio_hesu/views/sections/project/post.dart';
import 'package:portfolio_hesu/views/sections/project/project_item.dart';

class Project {
  final String title;
  final String desc;
  final String google;
  final String app;
  final String link;
  final List<String> tags;

  const Project(
    this.title,
    this.desc,
    this.tags,
    this.google,
    this.app,
    this.link,
  );
}

class ProjectTxt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProjectsGrid(
          items: const [
            Project(
              'App : HiddenTag maintenance',
              'HiddenTag - 히든태그 : 어플리케이션 페이지 유지보수',
              ['JAVA', 'JSP'], //Android
              //구글스토어
              'https://play.google.com/store/apps/details?id=ScanTag.ndk.det&pcampaignid=web_share',
              //앱스토어
              'https://apps.apple.com/kr/app/hiddentag-%ED%9E%88%EB%93%A0%ED%83%9C%EA%B7%B8/id413494082',
              //링크
              '',
            ),
            Project(
              'APP : AI-Bver maintenance',
              'AI-beaver - 에이아이비버 : 어플리케이션 개발 및 유지보수',
              ['PHP', 'Flutter'],
              'https://play.google.com/store/apps/details?id=com.aibver.lsmk&pcampaignid=web_share',
              '',
              '',
            ),
            Project(
              '범부처통합연구지원시스템(IRIS) Rnd 참여',
              '3D증강현실 기반의 교량 점검 시스템 개발',
              ['Unity', 'React'],
              '',
              '',
              'https://www.dbpia.co.kr/journal/articleDetail?nodeId=NODE11488090',
            ),
            Project(
              'APP : Blue Mentor Develop',
              '블루멘토 기계점검 안전설비 보고서 작성 어플 기획 및 개발',
              ['Flutter', 'node.js'],
              'https://play.google.com/store/apps/details?id=com.lsmk.BlueMentor&pcampaignid=web_share',
              'https://apps.apple.com/us/app/%EB%B8%94%EB%A3%A8%EB%A9%98%ED%86%A0/id6475704951',
              '',
            ),
          ],
        ),
        const SizedBox(height: 30),
        // Packages(),
      ],
    );
  }
}
