import 'dart:ui' show PointerDeviceKind;
import 'dart:ui' as ui show SemanticsAction, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:portfolio_hesu/portfolio/apps/profile_app.dart';
import 'package:portfolio_hesu/portfolio/data/portfolio_data.dart';
import 'package:portfolio_hesu/portfolio/mobile/apple_mobile_shell.dart';
import 'package:portfolio_hesu/portfolio/portfolio_app.dart';
import 'package:portfolio_hesu/portfolio/services/external_launcher.dart';
import 'package:portfolio_hesu/portfolio/theme/apple_theme.dart';
import 'package:portfolio_hesu/portfolio/theme/portfolio_theme_controller.dart';

import 'support/music_test_controller.dart';

void main() {
  group('모바일 Instagram형 프로필 앱', () {
    testWidgets('iPhone과 iPad는 About과 분리된 프로필 앱을 연다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(Size, bool)>[
        (Size(390, 844), false),
        (Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$1, tablet: scenario.$2);

        final launcher = find.byKey(const Key('home-app-profile'));
        expect(launcher, findsOneWidget);
        final launcherSemantics = find.descendant(
          of: launcher,
          matching: find.byKey(const Key('apple-app-icon-profile')),
        );
        expect(launcherSemantics, findsOneWidget);
        expect(
          tester.getSemantics(launcherSemantics).getSemanticsData().label,
          'Open 프로필',
        );
        expect(find.byKey(const Key('about-app')), findsNothing);

        await tester.tap(launcher);
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('about-app')), findsNothing);
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('mobile-app-more-profile')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Close 프로필 window'), findsOneWidget);
      }

      semantics.dispose();
    });

    testWidgets('인스타그램형 프로필 요약을 보이고 사이드바는 iPad에만 둔다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$2, tablet: scenario.$3);
        await _openProfile(tester);

        final profile = find.byKey(const Key('profile-app'));
        expect(
          find.descendant(of: profile, matching: find.text('민희수')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          find.descendant(
            of: profile,
            matching: find.byKey(const Key('profile-handle')),
          ),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          find.descendant(of: profile, matching: find.text('@min_hesu')),
          findsOneWidget,
          reason: scenario.$1,
        );
        _expectButtonSemantics(
          tester,
          find.byKey(const Key('profile-follow-action')),
          label: '팔로우',
        );
        _expectButtonSemantics(
          tester,
          find.byKey(const Key('profile-message-action')),
          label: '메시지 보내기',
        );
        expect(
          find.byKey(const Key('profile-sidebar')),
          scenario.$3 ? findsOneWidget : findsNothing,
          reason: scenario.$1,
        );
        expect(
          find.byKey(const Key('profile-sidebar-reels-action')),
          scenario.$3 ? findsOneWidget : findsNothing,
          reason: scenario.$1,
        );
        if (scenario.$3) {
          final profileRect = tester.getRect(profile);
          final sidebarRect = tester.getRect(
            find.byKey(const Key('profile-sidebar')),
          );
          expect(sidebarRect.width, closeTo(72, 0.1));
          expect(sidebarRect.top, closeTo(profileRect.top, 0.1));
          expect(sidebarRect.bottom, closeTo(profileRect.bottom, 0.1));
          expect(
            tester
                .getRect(
                  find.byKey(const Key('profile-sidebar-settings-action')),
                )
                .bottom,
            greaterThan(profileRect.bottom - 72),
          );
        }
        expect(
          find.byKey(const Key('profile-suggested-friends')),
          findsNothing,
          reason: scenario.$1,
        );
        expect(find.text('추천 친구'), findsNothing, reason: scenario.$1);
      }

      semantics.dispose();
    });

    testWidgets('독립 프로필은 연결 콜백이 없는 이동 제어를 비활성화한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpStandaloneProfile(
        tester,
        size: const Size(834, 1194),
        tablet: true,
      );

      for (final actionKey in const <Key>[
        Key('profile-message-action'),
        Key('profile-sidebar-projects-action'),
        Key('profile-sidebar-message-action'),
        Key('profile-sidebar-settings-action'),
      ]) {
        final semanticsData = tester
            .getSemantics(find.byKey(actionKey))
            .getSemanticsData();
        expect(semanticsData.flagsCollection.isEnabled, ui.Tristate.isFalse);
        expect(semanticsData.hasAction(ui.SemanticsAction.tap), isFalse);
      }
      expect(
        find.byKey(const Key('profile-career-projects-link')),
        findsNothing,
      );

      semantics.dispose();
    });

    testWidgets('팔로우 버튼은 팔로잉 상태를 두 번 토글한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
      );
      await _openProfile(tester);

      final follow = find.byKey(const Key('profile-follow-action'));
      _expectButtonSemantics(tester, follow, label: '팔로우');
      expect(
        find.descendant(of: follow, matching: find.text('팔로우')),
        findsOneWidget,
      );

      await tester.tap(follow);
      await tester.pumpAndSettle();

      _expectButtonSemantics(tester, follow, label: '팔로우 취소');
      expect(
        find.descendant(of: follow, matching: find.text('팔로잉')),
        findsOneWidget,
      );

      await tester.tap(follow);
      await tester.pumpAndSettle();

      _expectButtonSemantics(tester, follow, label: '팔로우');
      expect(
        find.descendant(of: follow, matching: find.text('팔로우')),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('메시지 보내기는 메일 앱을 열고 닫으면 프로필로 돌아온다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(tester, size: scenario.$2, tablet: scenario.$3);
        await _openProfile(tester);

        await tester.tap(find.byKey(const Key('profile-message-action')));
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('mail-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          find.byKey(const Key('profile-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
        await tester.tap(find.byKey(const Key('mobile-back-close-mail')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('mail-app')),
          findsNothing,
          reason: scenario.$1,
        );
        expect(
          find.byKey(const Key('profile-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
      }

      semantics.dispose();
    });

    testWidgets('경력 갤러리는 포트폴리오 회사를 열고 닫으면 프로필로 돌아온다', (tester) async {
      final semantics = tester.ensureSemantics();

      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);

        final career = find.byKey(const Key('profile-history-post-experience'));
        await _ensureCardBuilt(tester, career);
        _expectButtonSemantics(tester, career, label: '경력 게시물 열기');
        final companyLink = find.byKey(
          const Key('profile-career-projects-link'),
        );
        _expectButtonSemantics(tester, companyLink, label: '포트폴리오 회사 열기');
        final linkRect = tester.getRect(companyLink);
        expect(linkRect.width, greaterThanOrEqualTo(44));
        expect(linkRect.height, greaterThanOrEqualTo(44));
        await tester.ensureVisible(career);
        await tester.tap(companyLink);
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('projects-app')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          tester
              .getSemantics(
                find.byKey(const Key('projects-finder-location-career')),
              )
              .getSemanticsData()
              .flagsCollection
              .isSelected,
          ui.Tristate.isTrue,
          reason: scenario.$1,
        );
        await tester.tap(find.byKey(const Key('mobile-back-close-projects')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('projects-app')), findsNothing);
        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      }

      semantics.dispose();
    });

    testWidgets('iPhone 경력 카드 본체는 기존 릴스와 경력 답글을 유지한다', (tester) async {
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );
      await _openProfile(tester);

      await _openHistoryCard(
        tester,
        const Key('profile-history-post-experience'),
      );

      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      expect(find.byKey(const Key('projects-app')), findsNothing);
      expect(
        find.byKey(const Key('profile-reel-reply-item-experience-0')),
        findsOneWidget,
      );
    });

    testWidgets('iPad 사이드바 Reels는 경력 상세를 열고 뒤로 가기를 유지한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: data,
      );
      await _openProfile(tester);

      await _openCareerReelFromSidebar(tester);

      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      expect(find.byKey(const Key('projects-app')), findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const Key('profile-reel-info')),
          matching: find.text('경력'),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-sidebar')), findsOneWidget);

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('profile-history-detail')), findsNothing);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      expect(find.byKey(const Key('profile-sidebar')), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('피드는 identity와 단위가 있는 게시물·경력·교육 통계만 보여준다', (tester) async {
      final semantics = tester.ensureSemantics();
      final source = _injectedProfileData();
      final data = _profileDataWithHistory(
        source,
        experiences: source.experiences.take(1),
        education: source.education,
      );
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );

      await _openProfile(tester);

      final profile = find.byKey(const Key('profile-app'));
      expect(profile, findsOneWidget);
      for (final text in <String>[
        data.identity.name,
        data.identity.englishName,
        data.identity.headline,
        data.identity.biography,
      ]) {
        expect(
          find.descendant(of: profile, matching: find.text(text)),
          findsOneWidget,
          reason: text,
        );
      }
      expect(find.bySemanticsLabel('게시물 2개'), findsOneWidget);
      expect(find.bySemanticsLabel('경력 3년'), findsOneWidget);
      expect(find.bySemanticsLabel('교육 2번'), findsOneWidget);
      expect(find.bySemanticsLabel('프로젝트 1개'), findsNothing);
      expect(find.bySemanticsLabel('스킬 2개'), findsNothing);
      final stats = find.byKey(const Key('profile-stats'));
      expect(
        find.descendant(of: stats, matching: find.text('2개')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('3년')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: stats, matching: find.text('2번')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('profile-github-action')), findsNothing);
      expect(find.byKey(const Key('profile-mail-action')), findsNothing);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      expect(find.byKey(const Key('profile-highlights')), findsNothing);
      expect(find.byKey(const Key('profile-project-grid')), findsNothing);
      expect(find.text(_sentinelSkillGroup), findsNothing);
      expect(find.text(_sentinelSkill), findsNothing);
      expect(find.text(_sentinelProjectTitle), findsNothing);
      expect(find.text(_sentinelProjectDescription), findsNothing);
      expect(_fakeSocialMetricTextInside(profile), findsNothing);
      semantics.dispose();
    });

    testWidgets('경력과 교육은 각각 하나의 정사각형 게시물로 피드에 배치한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final grid = find.byKey(const Key('profile-history-grid'));
        final experiencePost = find.byKey(
          const Key('profile-history-post-experience'),
        );
        final educationPost = find.byKey(
          const Key('profile-history-post-education'),
        );
        expect(grid, findsOneWidget, reason: scenario.$1);
        for (final post in <Finder>[experiencePost, educationPost]) {
          await _ensureCardBuilt(tester, post);
          expect(find.descendant(of: grid, matching: post), findsOneWidget);
          final postRect = tester.getRect(post);
          expect(postRect.width, greaterThan(0), reason: scenario.$1);
          expect(
            postRect.width,
            closeTo(postRect.height, 0.5),
            reason: scenario.$1,
          );
        }
        expect(
          _widgetsWithKeyPrefixInside(grid, 'profile-history-card-experience-'),
          findsNothing,
        );
        expect(
          _widgetsWithKeyPrefixInside(grid, 'profile-history-card-education-'),
          findsNothing,
        );
        expect(find.byKey(const Key('profile-history-post')), findsNothing);
        _expectButtonSemantics(tester, experiencePost, label: '경력 게시물 열기');
        _expectButtonSemantics(tester, educationPost, label: '교육 게시물 열기');
        expect(
          find.descendant(of: experiencePost, matching: find.text('경력')),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: experiencePost,
            matching: find.text('경력 ${data.experiences.length}개'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: educationPost, matching: find.text('교육')),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: educationPost,
            matching: find.text('교육 ${data.education.length}개'),
          ),
          findsOneWidget,
        );
      }
      semantics.dispose();
    });

    testWidgets('상세는 이미지 없이 Instagram Reels 오버레이 구조만 제공한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      _expectReelTemplate(tester, data: data);
      expect(tester.takeException(), isNull);
      semantics.dispose();
    });

    testWidgets('릴스 미디어는 공유 액션 직후 끝나고 첫 답글을 바로 보여준다', (tester) async {
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );

        final detail = find.byKey(const Key('profile-history-detail'));
        final overlay = find.byKey(const Key('profile-reel-overlay'));
        final thread = find.byKey(const Key('profile-reel-reply-thread'));
        final firstReply = find.byKey(
          const Key('profile-reel-reply-item-education-0'),
        );
        final shareAction = find.byKey(const Key('profile-reel-share-action'));
        final detailRect = tester.getRect(detail);
        final overlayRect = tester.getRect(overlay);
        final threadRect = tester.getRect(thread);
        final firstReplyRect = tester.getRect(firstReply);
        final shareActionRect = tester.getRect(shareAction);

        expect(
          overlayRect.left,
          closeTo(detailRect.left, 1),
          reason: '${scenario.$1} left edge',
        );
        expect(
          overlayRect.right,
          closeTo(detailRect.right, 1),
          reason: '${scenario.$1} right edge',
        );
        expect(
          overlayRect.top,
          closeTo(detailRect.top, 1),
          reason: '${scenario.$1} top edge',
        );
        expect(
          overlayRect.height,
          lessThan(detailRect.height),
          reason: '${scenario.$1} compact reel height',
        );
        expect(
          threadRect.top,
          closeTo(overlayRect.bottom, 1),
          reason: '${scenario.$1} thread follows the reel surface',
        );
        expect(
          overlayRect.bottom - shareActionRect.bottom,
          inInclusiveRange(0, 24),
          reason: '${scenario.$1} reel ends near the share action',
        );
        expect(
          threadRect.top,
          lessThan(detailRect.bottom),
          reason: '${scenario.$1} thread starts in the initial viewport',
        );
        expect(
          firstReplyRect.top,
          lessThan(detailRect.bottom),
          reason: '${scenario.$1} first reply is initially visible',
        );
        expect(
          firstReplyRect.bottom,
          greaterThan(detailRect.top),
          reason: '${scenario.$1} first reply intersects the viewport',
        );
        expect(tester.widget<Stack>(overlay), isA<Stack>());
        expect(
          tester
              .element(overlay)
              .findAncestorWidgetOfExactType<ClipRRect>()
              ?.key,
          const Key('mobile-app-clip'),
          reason: '${scenario.$1} overlay is not a rounded inset card',
        );
      }
    });

    testWidgets('중립 미디어 슬롯과 오버레이 컨트롤은 라이트·다크 대비를 따른다', (tester) async {
      for (final brightness in Brightness.values) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: const Size(390, 844),
          tablet: false,
          brightness: brightness,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );

        final overlay = find.byKey(const Key('profile-reel-overlay'));
        final mediaSlot = find.byKey(const Key('profile-reel-media-slot'));
        final topBar = find.byKey(const Key('profile-reel-top-bar'));
        final actionRail = find.byKey(const Key('profile-reel-action-rail'));
        final info = find.byKey(const Key('profile-reel-info'));
        expect(
          find.descendant(of: overlay, matching: mediaSlot),
          findsOneWidget,
        );

        final mediaColor = tester.widget<ColoredBox>(mediaSlot).color;
        final foreground = brightness == Brightness.dark
            ? Colors.white
            : AppleTheme.primaryLabel(tester.element(overlay));
        if (brightness == Brightness.light) {
          expect(mediaColor.computeLuminance(), greaterThan(0.7));
          expect(foreground.computeLuminance(), lessThan(0.2));
        } else {
          expect(mediaColor.computeLuminance(), lessThan(0.2));
          expect(foreground, Colors.white);
        }

        final overlayText = <Text>[
          ...find
              .descendant(of: topBar, matching: find.byType(Text))
              .evaluate()
              .map((element) => element.widget as Text),
          ...find
              .descendant(of: info, matching: find.byType(Text))
              .evaluate()
              .map((element) => element.widget as Text),
        ];
        expect(overlayText, isNotEmpty);
        for (final text in overlayText) {
          expect(text.style?.color, foreground, reason: text.data);
        }

        final actionIcons = find
            .descendant(of: actionRail, matching: find.byType(Icon))
            .evaluate()
            .map((element) => element.widget as Icon)
            .toList();
        expect(actionIcons, hasLength(3));
        for (final icon in actionIcons) {
          expect(icon.color, foreground);
        }
        final cameraIcon = tester.widget<Icon>(
          find.descendant(of: topBar, matching: find.byType(Icon)),
        );
        expect(cameraIcon.color, foreground);

        final avatar = tester.widget<Container>(
          find.byKey(const Key('profile-reel-avatar')),
        );
        final avatarDecoration = avatar.decoration! as BoxDecoration;
        expect(avatarDecoration.border!.top.color, foreground);

        final likeAction = find.byKey(const Key('profile-reel-like-action'));
        await tester.tap(likeAction);
        await tester.pump();
        final filledHeart = find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_rounded),
        );
        expect(filledHeart, findsOneWidget);
        expect(tester.widget<Icon>(filledHeart).color, AppleTheme.red);
      }
    });

    testWidgets('하트는 카운트 없이 outline과 빨간 filled 상태를 두 번 토글한다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: _injectedProfileData(),
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final actionRail = find.byKey(const Key('profile-reel-action-rail'));
      final likeAction = find.byKey(const Key('profile-reel-like-action'));
      expect(
        find.descendant(of: actionRail, matching: likeAction),
        findsOneWidget,
      );
      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsNothing,
      );

      await tester.tap(likeAction);
      await tester.pump();

      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');
      final filledHeart = find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.favorite_rounded),
      );
      expect(filledHeart, findsOneWidget);
      expect(tester.widget<Icon>(filledHeart).color, AppleTheme.red);
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsNothing,
      );

      await tester.tap(likeAction);
      await tester.pump();

      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_rounded),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: actionRail, matching: find.byType(Text)),
        findsNothing,
        reason: '행동 레일에 임의의 좋아요·댓글 수를 만들지 않는다.',
      );
      expect(find.byKey(const Key('profile-reel-like-count')), findsNothing);
      expect(find.byKey(const Key('profile-reel-comment-count')), findsNothing);
      expect(_fakeSocialMetricTextInside(detail), findsNothing);
      expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);
      semantics.dispose();
    });

    testWidgets('좋아요는 같은 게시물에 보존되고 경력·교육 사이에서 분리된다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: _injectedProfileData(),
      );
      await _openProfile(tester);
      await _openCareerReelFromSidebar(tester);

      var likeAction = find.byKey(const Key('profile-reel-like-action'));
      await tester.tap(likeAction);
      await tester.pump();
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();
      await _openCareerReelFromSidebar(tester);

      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');
      final persistedHeart = find.descendant(
        of: likeAction,
        matching: find.byIcon(Icons.favorite_rounded),
      );
      expect(persistedHeart, findsOneWidget);
      expect(tester.widget<Icon>(persistedHeart).color, AppleTheme.red);

      await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
      await tester.pumpAndSettle();
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('동일 경력 재빌드는 상태를 보존하고 변경된 경력은 상세와 좋아요를 초기화한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final original = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: original,
      );
      await _openProfile(tester);
      await _openCareerReelFromSidebar(tester);

      final profileState = tester.state(find.byType(ProfileApp));
      var likeAction = find.byKey(const Key('profile-reel-like-action'));
      await tester.tap(likeAction);
      await tester.pump();
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');

      final copiedExperiences = <PortfolioExperience>[
        for (final item in original.experiences)
          PortfolioExperience(
            role: item.role,
            organization: item.organization,
            period: item.period,
            description: item.description,
          ),
      ];
      final copiedEducation = <PortfolioEducation>[
        for (final item in original.education)
          PortfolioEducation(
            program: item.program,
            institution: item.institution,
            period: item.period,
            link: switch (item.link) {
              final link? => PortfolioProjectLink(
                label: link.label,
                url: link.url,
              ),
              null => null,
            },
          ),
      ];
      final identicalHistory = _profileDataWithHistory(
        original,
        experiences: copiedExperiences,
        education: copiedEducation,
      );

      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: identicalHistory,
      );

      expect(
        identical(tester.state(find.byType(ProfileApp)), profileState),
        isTrue,
      );
      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요 취소');

      final changedHistory = _profileDataWithHistory(
        identicalHistory,
        experiences: <PortfolioExperience>[
          copiedExperiences[1],
          copiedExperiences[0],
          copiedExperiences[2],
        ],
        education: <PortfolioEducation>[copiedEducation[1], copiedEducation[0]],
      );

      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: changedHistory,
      );

      expect(
        identical(tester.state(find.byType(ProfileApp)), profileState),
        isTrue,
      );
      expect(find.byKey(const Key('profile-history-detail')), findsNothing);
      expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
      final feedPosition = tester
          .state<ScrollableState>(
            _scrollableInside(const Key('profile-scroll')),
          )
          .position;
      expect(feedPosition.pixels, closeTo(0, 0.5));

      await _openCareerReelFromSidebar(tester);
      likeAction = find.byKey(const Key('profile-reel-like-action'));
      _expectButtonSemantics(tester, likeAction, label: '좋아요');
      expect(
        find.descendant(
          of: likeAction,
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('댓글 버튼은 같은 상세 스크롤을 답글 스레드까지 이동시킨다', (tester) async {
      final semantics = tester.ensureSemantics();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 560),
        tablet: false,
        data: _injectedProfileData(),
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final detailScroll = find.byKey(
        const Key('profile-history-detail-scroll'),
      );
      final scrollable = _scrollableInside(
        const Key('profile-history-detail-scroll'),
      );
      final commentAction = find.byKey(
        const Key('profile-reel-comment-action'),
      );
      final replyThread = find.byKey(const Key('profile-reel-reply-thread'));
      expect(scrollable, findsOneWidget);
      expect(commentAction, findsOneWidget);
      _expectButtonSemantics(tester, commentAction, label: '댓글 보기');
      expect(
        find.descendant(of: detailScroll, matching: replyThread),
        findsOneWidget,
      );

      final scrollableState = tester.state<ScrollableState>(scrollable);
      final position = scrollableState.position;
      final offsetBeforeTap = position.pixels;
      final bottomSheetCountBefore = find.byType(BottomSheet).evaluate().length;
      final dialogCountBefore = find.byType(Dialog).evaluate().length;
      final modalBarrierCountBefore = find
          .byType(ModalBarrier)
          .evaluate()
          .length;

      await tester.tap(commentAction);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
      expect(
        find.byKey(const Key('profile-reel-comments-sheet')),
        findsNothing,
      );
      expect(find.byType(BottomSheet), findsNWidgets(bottomSheetCountBefore));
      expect(find.byType(Dialog), findsNWidgets(dialogCountBefore));
      expect(find.byType(ModalBarrier), findsNWidgets(modalBarrierCountBefore));
      expect(_verticalScrollablesInside(detail), findsOneWidget);
      expect(
        identical(tester.state<ScrollableState>(scrollable), scrollableState),
        isTrue,
      );
      expect(identical(scrollableState.position, position), isTrue);
      expect(position.pixels, greaterThan(offsetBeforeTap));
      expect(
        tester.getRect(replyThread).top,
        inInclusiveRange(
          tester.getRect(detail).top,
          tester.getRect(detail).bottom,
        ),
      );
      semantics.dispose();
    });

    testWidgets('경력 게시물은 실제 경력만 각각의 답글로 서술한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      await _pumpProfileShell(
        tester,
        size: const Size(834, 1194),
        tablet: true,
        data: data,
      );
      await _openProfile(tester);
      await _openCareerReelFromSidebar(tester);

      final detail = find.byKey(const Key('profile-history-detail'));
      final overlay = find.byKey(const Key('profile-reel-overlay'));
      final info = find.byKey(const Key('profile-reel-info'));
      final thread = find.byKey(const Key('profile-reel-reply-thread'));
      expect(thread, findsOneWidget);
      expect(
        tester.getRect(overlay).bottom,
        lessThanOrEqualTo(tester.getRect(thread).top),
      );
      expect(
        find.descendant(of: info, matching: find.text('경력')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: info,
          matching: find.text('경력 ${data.experiences.length}개'),
        ),
        findsOneWidget,
      );

      final expectedItemKeys = <String>[
        for (var index = 0; index < data.experiences.length; index++)
          'profile-reel-reply-item-experience-$index',
      ];
      final replyItems = _widgetsWithKeyPrefixInside(
        thread,
        'profile-reel-reply-item-',
      );
      expect(replyItems, findsNWidgets(expectedItemKeys.length));
      expect(
        replyItems.evaluate().map((element) {
          return (element.widget.key! as ValueKey<String>).value;
        }).toList(),
        expectedItemKeys,
        reason: '경력 게시물에는 경력 답글만 원본 순서로 이어져야 한다.',
      );
      expect(
        _widgetsWithKeyPrefixInside(
          thread,
          'profile-reel-reply-item-education-',
        ),
        findsNothing,
      );
      expect(
        _widgetsWithKeyPrefixInside(thread, 'profile-reel-reply-author-'),
        findsNWidgets(expectedItemKeys.length),
      );
      for (final forbidden in <String>[
        _sentinelSkillGroup,
        _sentinelSkill,
        _sentinelProjectTitle,
        _sentinelProjectDescription,
      ]) {
        expect(
          find.descendant(
            of: thread,
            matching: find.textContaining(forbidden, findRichText: true),
          ),
          findsNothing,
          reason: '실제 경력·교육 외 콘텐츠를 reply로 섞지 않는다.',
        );
      }

      for (var index = 0; index < data.experiences.length; index++) {
        final experience = data.experiences[index];
        _expectReplyItem(
          tester,
          thread: thread,
          identityName: data.identity.name,
          kind: 'experience',
          index: index,
          expectedText: <String>[
            experience.role,
            experience.organization,
            experience.period,
            experience.description,
          ],
        );
      }

      for (final education in data.education) {
        expect(
          find.descendant(of: thread, matching: find.text(education.program)),
          findsNothing,
        );
      }
      expect(
        find.byKey(const Key('profile-reel-comment-composer')),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(TextField)),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('교육 게시물은 실제 교육만 각각의 답글로 서술하고 링크를 유지한다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      final launcher = _RecordingLauncher();
      await _pumpProfileShell(
        tester,
        size: const Size(390, 844),
        tablet: false,
        data: data,
        launcher: launcher,
      );
      await _openProfile(tester);
      await _openHistoryCard(
        tester,
        const Key('profile-history-post-education'),
      );

      final detail = find.byKey(const Key('profile-history-detail'));
      final info = find.byKey(const Key('profile-reel-info'));
      final thread = find.byKey(const Key('profile-reel-reply-thread'));
      expect(
        find.descendant(of: info, matching: find.text('교육')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: info,
          matching: find.text('교육 ${data.education.length}개'),
        ),
        findsOneWidget,
      );
      final expectedItemKeys = <String>[
        for (var index = 0; index < data.education.length; index++)
          'profile-reel-reply-item-education-$index',
      ];
      final replyItems = _widgetsWithKeyPrefixInside(
        thread,
        'profile-reel-reply-item-',
      );
      expect(replyItems, findsNWidgets(expectedItemKeys.length));
      expect(
        replyItems.evaluate().map((element) {
          return (element.widget.key! as ValueKey<String>).value;
        }).toList(),
        expectedItemKeys,
        reason: '교육 게시물에는 교육 답글만 원본 순서로 이어져야 한다.',
      );
      expect(
        _widgetsWithKeyPrefixInside(
          thread,
          'profile-reel-reply-item-experience-',
        ),
        findsNothing,
      );

      for (var index = 0; index < data.education.length; index++) {
        final education = data.education[index];
        _expectReplyItem(
          tester,
          thread: thread,
          identityName: data.identity.name,
          kind: 'education',
          index: index,
          expectedText: <String>[
            education.program,
            education.institution,
            education.period,
            if (education.link case final link?) link.label,
          ],
        );
      }
      for (final experience in data.experiences) {
        expect(
          find.descendant(of: thread, matching: find.text(experience.role)),
          findsNothing,
        );
      }

      final linkedEducation = data.education.first;
      final link = linkedEducation.link!;
      final linkedItem = find.byKey(
        const Key('profile-reel-reply-item-education-0'),
      );
      final unlinkedItem = find.byKey(
        const Key('profile-reel-reply-item-education-1'),
      );
      final linkAction = find.byKey(
        const Key('profile-reel-reply-link-education-0'),
      );
      expect(
        find.descendant(of: linkedItem, matching: linkAction),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: linkedItem,
          matching: find.bySemanticsLabel('Open ${link.label}'),
        ),
        findsOneWidget,
      );
      _expectButtonSemantics(tester, linkAction, label: 'Open ${link.label}');
      expect(
        find.descendant(
          of: unlinkedItem,
          matching: find.byWidgetPredicate(
            (widget) =>
                widget.key == const Key('profile-reel-reply-link-education-1'),
          ),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.bySemanticsLabel('Open ${link.label}'),
        ),
        findsOneWidget,
      );

      expect(
        find.byKey(const Key('profile-reel-comment-composer')),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(TextField)),
        findsNothing,
      );
      expect(
        find.descendant(of: detail, matching: find.byType(EditableText)),
        findsNothing,
      );

      await tester.ensureVisible(linkAction);
      await tester.pumpAndSettle();
      await tester.tap(linkAction);
      await tester.pumpAndSettle();
      expect(launcher.uris, <Uri>[link.uri]);
      semantics.dispose();
    });

    testWidgets('공용 헤더는 상세에서 뒤로 가고 피드 루트에서 앱을 닫는다', (tester) async {
      final semantics = tester.ensureSemantics();
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 844), false),
        ('iPad', Size(834, 1194), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final control = find.byKey(const Key('mobile-back-close-profile'));
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(control, findsOneWidget, reason: scenario.$1);
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Close 프로필 window',
          reason: scenario.$1,
        );

        await _openHistoryCard(
          tester,
          const Key('profile-history-post-education'),
        );
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Back in 프로필',
          reason: scenario.$1,
        );
        expect(find.bySemanticsLabel('Close 프로필 window'), findsNothing);
        final detail = find.byKey(const Key('profile-history-detail'));
        expect(find.byKey(const Key('profile-history-grid')), findsNothing);
        expect(find.byKey(const Key('profile-app')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(_fakeSocialMetricTextInside(detail), findsNothing);
        expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);

        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile-history-detail')), findsNothing);
        expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsOneWidget);
        expect(
          find.byKey(const Key('mobile-app-navigation-bar')),
          findsOneWidget,
          reason: scenario.$1,
        );
        expect(
          tester.getSemantics(control).getSemanticsData().label,
          'Close 프로필 window',
          reason: scenario.$1,
        );

        await tester.tap(control);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('mobile-home')), findsOneWidget);
        expect(find.byKey(const Key('mobile-app-surface')), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('상세에서 돌아오면 iPhone과 iPad 피드의 비영 스크롤 위치를 복원한다', (tester) async {
      final data = _injectedProfileData();
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(390, 420), false),
        ('iPad', Size(834, 420), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: data,
        );
        await _openProfile(tester);

        final card = find.byKey(const Key('profile-history-post-education'));
        await _ensureCardBuilt(tester, card);
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        final feedPosition = tester
            .state<ScrollableState>(
              _scrollableInside(const Key('profile-scroll')),
            )
            .position;
        final offsetBeforeDetail = feedPosition.pixels;
        expect(
          offsetBeforeDetail,
          greaterThan(0),
          reason: '${scenario.$1} precondition',
        );

        await tester.tap(card);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('profile-history-detail')), findsOneWidget);
        await tester.tap(find.byKey(const Key('mobile-back-close-profile')));
        await tester.pumpAndSettle();

        final restoredPosition = tester
            .state<ScrollableState>(
              _scrollableInside(const Key('profile-scroll')),
            )
            .position;
        expect(
          restoredPosition.pixels,
          closeTo(offsetBeforeDetail, 1),
          reason: scenario.$1,
        );
        expect(card, findsOneWidget, reason: scenario.$1);
        final cardRect = tester.getRect(card);
        expect(cardRect.bottom, greaterThan(0), reason: scenario.$1);
        expect(cardRect.top, lessThan(scenario.$2.height), reason: scenario.$1);
      }
    });

    testWidgets('라이트와 다크의 iPhone·iPad 200% 피드와 상세가 넘치지 않는다', (tester) async {
      for (final formFactor in const <(Size, bool)>[
        (Size(320, 480), false),
        (Size(600, 720), true),
        (Size(834, 620), true),
      ]) {
        final backgroundColors = <Brightness, Color>{};
        for (final brightness in Brightness.values) {
          final data = _injectedProfileData();
          await tester.pumpWidget(const SizedBox.shrink());
          await _pumpProfileShell(
            tester,
            size: formFactor.$1,
            tablet: formFactor.$2,
            brightness: brightness,
            textScaler: const TextScaler.linear(2),
            data: data,
          );

          await _openProfile(tester);

          final profile = find.byKey(const Key('profile-app'));
          expect(profile, findsOneWidget);
          final background = find.byKey(const Key('profile-background'));
          expect(background, findsOneWidget);
          backgroundColors[brightness] = tester
              .widget<ColoredBox>(background)
              .color;
          expect(find.byKey(const Key('profile-scroll')), findsOneWidget);
          expect(find.byKey(const Key('profile-history-grid')), findsOneWidget);
          final firstCard = find.byKey(
            const Key('profile-history-post-experience'),
          );
          await _ensureCardBuilt(tester, firstCard);
          await tester.ensureVisible(firstCard);
          await tester.pumpAndSettle();
          final metadata = find.byKey(
            const Key('profile-history-post-meta-experience'),
          );
          final title = find.byKey(
            const Key('profile-history-post-title-experience'),
          );
          expect(metadata, findsOneWidget);
          expect(title, findsOneWidget);
          expect(
            tester.getRect(metadata).bottom,
            lessThanOrEqualTo(tester.getRect(title).top + 0.5),
            reason: '${formFactor.$1} $brightness card text overlap',
          );
          expect(
            Theme.of(tester.element(profile)).brightness,
            brightness,
            reason: '${formFactor.$1} $brightness',
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness feed',
          );

          if (formFactor.$2) {
            await _openCareerReelFromSidebar(tester);
          } else {
            await _openHistoryCard(
              tester,
              const Key('profile-history-post-education'),
            );
          }
          expect(
            find.byKey(const Key('profile-history-detail')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('profile-history-detail-scroll')),
            findsOneWidget,
          );
          expect(
            Theme.of(
              tester.element(find.byKey(const Key('profile-history-detail'))),
            ).brightness,
            brightness,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '${formFactor.$1} $brightness detail',
          );

          if (formFactor.$2) {
            await tester.tap(
              find.byKey(const Key('mobile-back-close-profile')),
            );
            await tester.pumpAndSettle();
            await _openHistoryCard(
              tester,
              const Key('profile-history-post-education'),
            );
            expect(
              find.byKey(const Key('profile-history-detail')),
              findsOneWidget,
            );
            expect(
              tester.takeException(),
              isNull,
              reason: '${formFactor.$1} $brightness education detail',
            );
          }
        }
        expect(
          backgroundColors[Brightness.light],
          isNot(backgroundColors[Brightness.dark]),
          reason: '${formFactor.$1} light and dark surfaces',
        );
      }
    });

    testWidgets('iPhone과 iPad의 피드와 상세는 터치와 마우스 드래그로 스크롤된다', (tester) async {
      for (final scenario in const <(String, Size, bool)>[
        ('iPhone', Size(320, 480), false),
        ('iPad', Size(834, 620), true),
      ]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await _pumpProfileShell(
          tester,
          size: scenario.$2,
          tablet: scenario.$3,
          data: _injectedProfileData(),
        );
        await _openProfile(tester);
        await _expectTouchAndMouseScroll(
          tester,
          const Key('profile-scroll'),
          reason: '${scenario.$1} feed',
        );
        if (scenario.$3) {
          await _openCareerReelFromSidebar(tester);
        } else {
          await _openHistoryCard(
            tester,
            const Key('profile-history-post-education'),
          );
        }
        await _expectTouchAndMouseScroll(
          tester,
          const Key('profile-history-detail-scroll'),
          reason: '${scenario.$1} detail',
        );
        expect(tester.takeException(), isNull, reason: scenario.$1);
      }
    });
  });
}

Future<void> _pumpProfileShell(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
  PortfolioData data = portfolioData,
  ExternalLauncher? launcher,
  Brightness brightness = Brightness.light,
  TextScaler textScaler = TextScaler.noScaling,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final themeController = PortfolioThemeController(
    initial: brightness == Brightness.dark
        ? PortfolioThemePreference.dark
        : PortfolioThemePreference.light,
  );
  addTearDown(themeController.dispose);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      themeMode: themeController.themeMode,
      scrollBehavior: const PortfolioScrollBehavior(),
      home: MediaQuery(
        data: MediaQueryData(size: size, textScaler: textScaler),
        child: AppleMobileShell(
          data: data,
          externalLauncher: launcher ?? _RecordingLauncher(),
          themeController: themeController,
          musicController: createTestMusicController(),
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpStandaloneProfile(
  WidgetTester tester, {
  required Size size,
  required bool tablet,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppleTheme.light(),
      darkTheme: AppleTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: ProfileApp(
          data: portfolioData,
          launcher: _RecordingLauncher(),
          tablet: tablet,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

PortfolioData _injectedProfileData() {
  return PortfolioData(
    identity: const PortfolioIdentity(
      name: '프로필 사용자',
      englishName: 'Profile User',
      email: 'profile@example.com',
      githubUrl: 'https://github.com/profile-user/',
      headline: 'Injected profile headline',
      biography: 'Injected profile biography',
    ),
    experiences: const <PortfolioExperience>[
      PortfolioExperience(
        role: 'Lead Flutter Developer',
        organization: 'Profile Company Alpha',
        period: '2024 - Present',
        description: _longExperienceDescription,
      ),
      PortfolioExperience(
        role: 'Mobile Engineer',
        organization: 'Profile Company Beta',
        period: '2022 - 2024',
        description: 'Flutter와 Dart 기반 모바일 제품의 설계와 출시를 담당했습니다.',
      ),
      PortfolioExperience(
        role: 'Junior Java Developer',
        organization: 'Profile Company Gamma',
        period: '2020 - 2021',
        description: 'Java 기반 애플리케이션 개발과 운영 자동화를 경험했습니다.',
      ),
    ],
    education: const <PortfolioEducation>[
      PortfolioEducation(
        program: 'Advanced Mobile Application Development Program',
        institution: 'Profile Technology Academy',
        period: '2019 - 2020',
        link: PortfolioProjectLink(
          label: 'Education certificate',
          url: 'https://example.com/education/certificate',
        ),
      ),
      PortfolioEducation(
        program: 'Game Entertainment and Business Degree',
        institution: 'Profile University',
        period: '2009 - 2011',
      ),
    ],
    skillGroups: const <PortfolioSkillGroup>[
      PortfolioSkillGroup.constant(
        title: _sentinelSkillGroup,
        skills: <String>[_sentinelSkill, 'SECOND_SENTINEL_SKILL'],
      ),
    ],
    projects: const <PortfolioProject>[
      PortfolioProject.constant(
        title: _sentinelProjectTitle,
        description: _sentinelProjectDescription,
        period: '2026',
        technologies: <String>['SENTINEL_PROJECT_TECHNOLOGY'],
        links: <PortfolioProjectLink>[],
      ),
    ],
  );
}

PortfolioData _profileDataWithHistory(
  PortfolioData source, {
  required Iterable<PortfolioExperience> experiences,
  required Iterable<PortfolioEducation> education,
}) {
  return PortfolioData(
    identity: source.identity,
    experiences: experiences,
    education: education,
    skillGroups: source.skillGroups,
    projects: source.projects,
  );
}

final class _RecordingLauncher implements ExternalLauncher {
  final List<Uri> uris = <Uri>[];

  @override
  Future<bool> launch(Uri uri) async {
    uris.add(uri);
    return true;
  }
}

Finder _scrollableInside(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(Scrollable),
  );
}

Future<void> _openProfile(WidgetTester tester) async {
  final profileLauncher = find.byKey(const Key('home-app-profile'));
  expect(profileLauncher, findsOneWidget);
  await tester.tap(profileLauncher);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('profile-app')), findsOneWidget);
}

Future<void> _openHistoryCard(WidgetTester tester, Key cardKey) async {
  final card = find.byKey(cardKey);
  await _ensureCardBuilt(tester, card);
  expect(card, findsOneWidget);
  await tester.ensureVisible(card);
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

Future<void> _openCareerReelFromSidebar(WidgetTester tester) async {
  final reelsAction = find.byKey(const Key('profile-sidebar-reels-action'));
  expect(find.byKey(const Key('profile-sidebar')), findsOneWidget);
  expect(reelsAction, findsOneWidget);
  await tester.tap(reelsAction);
  await tester.pumpAndSettle();
}

Future<void> _ensureCardBuilt(WidgetTester tester, Finder card) async {
  final scrollable = _scrollableInside(const Key('profile-scroll'));
  final position = tester.state<ScrollableState>(scrollable).position;
  while (card.evaluate().isEmpty &&
      position.pixels < position.maxScrollExtent) {
    await tester.drag(
      find.byKey(const Key('profile-scroll')),
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
  }
}

Future<void> _expectTouchAndMouseScroll(
  WidgetTester tester,
  Key scrollKey, {
  required String reason,
}) async {
  final target = find.byKey(scrollKey);
  expect(target, findsOneWidget, reason: reason);
  final scrollable = find.descendant(
    of: target,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
      description: 'vertical Scrollable',
    ),
  );
  expect(scrollable, findsOneWidget, reason: reason);
  final position = tester.state<ScrollableState>(scrollable).position;
  expect(position.maxScrollExtent, greaterThan(0), reason: reason);

  await tester.drag(target, const Offset(0, -180));
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason touch');

  position.jumpTo(0);
  await tester.pump();
  final targetRect = tester.getRect(target);
  final dragStart = Offset(targetRect.left + 8, targetRect.center.dy);
  final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await mouse.addPointer(location: dragStart);
  await mouse.down(dragStart);
  await mouse.moveBy(const Offset(0, -180));
  await mouse.up();
  await tester.pumpAndSettle();
  expect(position.pixels, greaterThan(0), reason: '$reason mouse');
  await mouse.removePointer();

  position.jumpTo(0);
  await tester.pump();
}

Finder _fakeSocialMetricTextInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.textContaining(_fakeSocialMetricPattern, findRichText: true),
  );
}

Finder _fakeSocialMetricSemanticsInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.bySemanticsLabel(_fakeSocialMetricPattern),
  );
}

void _expectButtonSemantics(
  WidgetTester tester,
  Finder finder, {
  required String label,
}) {
  expect(finder, findsOneWidget);
  final semantics = tester.getSemantics(finder).getSemanticsData();
  expect(semantics.label, label);
  expect(semantics.flagsCollection.isButton, isTrue);
  expect(semantics.hasAction(ui.SemanticsAction.tap), isTrue);
}

Finder _widgetsWithKeyPrefixInside(Finder scope, String prefix) {
  return find.descendant(
    of: scope,
    matching: find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> && key.value.startsWith(prefix);
    }, description: 'widget with a key beginning with $prefix'),
  );
}

Finder _verticalScrollablesInside(Finder scope) {
  return find.descendant(
    of: scope,
    matching: find.byWidgetPredicate(
      (widget) =>
          widget is Scrollable &&
          (widget.axisDirection == AxisDirection.down ||
              widget.axisDirection == AxisDirection.up),
      description: 'vertical Scrollable',
    ),
  );
}

void _expectReplyItem(
  WidgetTester tester, {
  required Finder thread,
  required String identityName,
  required String kind,
  required int index,
  required List<String> expectedText,
}) {
  final item = find.byKey(Key('profile-reel-reply-item-$kind-$index'));
  final author = find.byKey(Key('profile-reel-reply-author-$kind-$index'));
  final content = find.byKey(Key('profile-reel-reply-content-$kind-$index'));
  expect(find.descendant(of: thread, matching: item), findsOneWidget);
  expect(find.descendant(of: item, matching: author), findsOneWidget);
  expect(find.descendant(of: item, matching: content), findsOneWidget);
  expect(
    find.descendant(of: author, matching: find.text(identityName)),
    findsOneWidget,
  );

  final authorText = find
      .descendant(of: author, matching: find.byType(Text))
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
  expect(authorText, <String>[
    identityName,
  ], reason: '실제 identity만 reply 작성자로 노출한다.');

  final contentTextWidgets = find.descendant(
    of: content,
    matching: find.byType(Text),
  );
  final contentText = contentTextWidgets
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
  expect(contentText, expectedText, reason: '임의의 댓글 대신 실제 포트폴리오 데이터만 서술한다.');
  for (final text in expectedText) {
    final textWidget = find.descendant(of: content, matching: find.text(text));
    expect(textWidget, findsOneWidget, reason: text);
    final widget = tester.widget<Text>(textWidget);
    expect(widget.maxLines, isNull, reason: text);
    expect(widget.overflow, isNot(TextOverflow.ellipsis), reason: text);
  }
}

void _expectReelTemplate(WidgetTester tester, {required PortfolioData data}) {
  final detail = find.byKey(const Key('profile-history-detail'));
  final overlay = find.byKey(const Key('profile-reel-overlay'));
  final topBar = find.byKey(const Key('profile-reel-top-bar'));
  final actionRail = find.byKey(const Key('profile-reel-action-rail'));
  final info = find.byKey(const Key('profile-reel-info'));
  final account = find.byKey(const Key('profile-reel-account-row'));

  expect(detail, findsOneWidget);
  expect(overlay, findsOneWidget);
  final overlayRect = tester.getRect(overlay);
  expect(overlayRect.height, greaterThan(0));
  expect(overlayRect.width, greaterThan(tester.getSize(detail).width * 0.55));

  for (final section in <Finder>[topBar, actionRail, info]) {
    expect(
      find.descendant(of: overlay, matching: section),
      findsOneWidget,
      reason: 'Reel controls must stay inside the overlay',
    );
  }
  final topBarRect = tester.getRect(topBar);
  final actionRailRect = tester.getRect(actionRail);
  final infoRect = tester.getRect(info);
  for (final sectionRect in <Rect>[topBarRect, actionRailRect, infoRect]) {
    expect(sectionRect.left, greaterThanOrEqualTo(overlayRect.left));
    expect(sectionRect.top, greaterThanOrEqualTo(overlayRect.top));
    expect(sectionRect.right, lessThanOrEqualTo(overlayRect.right));
    expect(sectionRect.bottom, lessThanOrEqualTo(overlayRect.bottom));
  }
  expect(
    topBarRect.center.dy,
    lessThan(overlayRect.top + (overlayRect.height * 0.25)),
    reason: 'Reels 제목과 카메라는 미디어 슬롯 상단에 오버레이한다.',
  );
  expect(
    actionRailRect.center.dx,
    greaterThan(overlayRect.center.dx),
    reason: '하트·댓글·공유 액션은 미디어 슬롯 오른쪽에 세로 배치한다.',
  );
  expect(
    infoRect.center.dy,
    greaterThan(overlayRect.center.dy),
    reason: '계정과 설명은 미디어 슬롯 하단에 오버레이한다.',
  );
  expect(
    infoRect.right,
    lessThanOrEqualTo(actionRailRect.left),
    reason: '하단 정보와 오른쪽 액션 레일이 겹치지 않아야 한다.',
  );
  expect(
    find.descendant(of: topBar, matching: find.text('Reels')),
    findsOneWidget,
  );
  final cameraAction = find.byKey(const Key('profile-reel-camera-action'));
  expect(find.descendant(of: topBar, matching: cameraAction), findsOneWidget);
  _expectButtonSemantics(tester, cameraAction, label: '카메라');
  final likeAction = find.byKey(const Key('profile-reel-like-action'));
  final commentAction = find.byKey(const Key('profile-reel-comment-action'));
  final shareAction = find.byKey(const Key('profile-reel-share-action'));
  for (final action in <Finder>[likeAction, commentAction, shareAction]) {
    expect(find.descendant(of: actionRail, matching: action), findsOneWidget);
  }
  _expectButtonSemantics(tester, likeAction, label: '좋아요');
  _expectButtonSemantics(tester, commentAction, label: '댓글 보기');
  _expectButtonSemantics(tester, shareAction, label: '공유');
  expect(find.descendant(of: info, matching: account), findsOneWidget);
  expect(
    find.descendant(of: account, matching: find.text(data.identity.name)),
    findsOneWidget,
  );
  expect(
    find.descendant(
      of: account,
      matching: find.byKey(const Key('profile-reel-avatar')),
    ),
    findsOneWidget,
  );

  expect(find.byKey(const Key('profile-reel-visual')), findsNothing);
  expect(find.byKey(const Key('profile-reel-artwork')), findsNothing);
  expect(find.byKey(const Key('profile-reel-caption')), findsNothing);
  expect(
    find.descendant(of: detail, matching: find.byType(Image)),
    findsNothing,
  );
  expect(
    find.descendant(of: detail, matching: find.byType(RawImage)),
    findsNothing,
  );
  expect(
    find.descendant(of: detail, matching: find.byType(CustomPaint)),
    findsNothing,
  );
  expect(
    find.descendant(
      of: detail,
      matching: find.byWidgetPredicate(
        (widget) => switch (widget) {
          Container(:final decoration) =>
            decoration is BoxDecoration && decoration.image != null,
          DecoratedBox(:final decoration) =>
            decoration is BoxDecoration && decoration.image != null,
          _ => false,
        },
        description: 'widget with a DecorationImage',
      ),
    ),
    findsNothing,
  );
  expect(find.byKey(const Key('profile-reel-like-count')), findsNothing);
  expect(find.byKey(const Key('profile-reel-comment-count')), findsNothing);
  expect(find.byKey(const Key('profile-reel-follower-count')), findsNothing);
  expect(find.byKey(const Key('mobile-app-navigation-bar')), findsOneWidget);
  expect(_fakeSocialMetricTextInside(detail), findsNothing);
  expect(_fakeSocialMetricSemanticsInside(detail), findsNothing);
}

const _sentinelSkillGroup = 'SENTINEL_SKILL_GROUP';
const _sentinelSkill = 'SENTINEL_SKILL';
const _sentinelProjectTitle = 'SENTINEL_PROJECT_TITLE';
const _sentinelProjectDescription = 'SENTINEL_PROJECT_DESCRIPTION';
const _longExperienceDescription =
    '사용자 문제를 분석하고 Flutter 애플리케이션의 구조를 설계한 뒤 구현과 출시를 '
    '담당했습니다. 다양한 화면 크기와 접근성 글자 크기를 함께 검증하고, 제품 출시 이후에는 '
    '사용자 피드백과 운영 지표를 바탕으로 긴 호흡의 개선 작업을 반복했습니다. 이 설명은 작은 '
    'iPhone과 iPad의 상세 화면에서 실제 스크롤이 필요한 길이를 보장하기 위한 테스트 데이터입니다.';

final _fakeSocialMetricPattern = RegExp(
  r'(?:\d[\d,.]*\s*(?:[KkMm]|만)?\s*'
  r'(?:좋아요|팔로워|팔로잉|likes?|followers?|following))|'
  r'(?:(?:좋아요|팔로워|팔로잉|likes?|followers?|following)\s*'
  r'\d[\d,.]*\s*(?:[KkMm]|만)?)',
  caseSensitive: false,
);
