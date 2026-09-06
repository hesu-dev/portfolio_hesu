# 스킬 브랜드 아바타 설계

## 목표

데스크톱, 태블릿, 모바일에서 Skills 앱의 세 채널을 열었을 때 각 활동 메시지의 첫 글자 프로필 아바타를 해당 기술의 브랜드 로고로 바꾼다. 현재 포트폴리오에 노출되는 Development, Collaboration, Design & UI/UX 채널의 열 개 기술을 모두 포함하고, 기존 채널 탐색·메시지·접근성 동작은 유지한다.

## 자산과 표현

Flutter, Dart, React, Java, Notion, Slack, Trello, Figma, Adobe Photoshop, Adobe Illustrator의 컬러 SVG를 `assets/icons/skills/`에 로컬 자산으로 둔다. 동일한 출처와 좌표 체계를 사용해 시각 품질을 일관되게 유지하고, 이미 의존 중인 `flutter_svg`로 렌더링한다. 네트워크 로딩이나 새 패키지는 추가하지 않는다.

아바타는 기존 42×42 원형 크기와 `skills-message-avatar-*` 키·이미지 semantics를 유지한다. 밝은 중립 배경과 얇은 테두리 안에 로고를 `BoxFit.contain`으로 배치해 단색·다색 로고가 라이트 및 다크 테마에서 모두 식별되도록 한다. 포트폴리오 외부에서 알 수 없는 기술 이름이 주입되면 기존 색상 원과 첫 글자를 폴백으로 사용한다.

## 구조와 검증

세 폼 팩터의 채널 상세는 `_SkillActivityFeed`와 `_SkillActivityMessage`를 공유하므로, 기술 이름에서 SVG 경로를 찾는 단일 카탈로그와 공통 아바타 위젯만 추가한다. 세 채널 각각을 선택하면서 열 개 로고가 모두 나타나는지 데스크톱·태블릿·모바일 위젯 테스트로 확인하고, 각 SVG가 asset bundle에서 실제로 로드되는지도 검증한다. 기존 semantics 라벨과 이미지 플래그, 200% 텍스트 확대, 알 수 없는 기술의 첫 글자 폴백은 회귀 테스트로 보호한다.
