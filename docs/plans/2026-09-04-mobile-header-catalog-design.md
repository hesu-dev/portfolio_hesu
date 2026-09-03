# 모바일 공용 헤더와 앱 카탈로그 설계

## 목표와 결정

iPhone·iPad에서 앱별로 복제된 상단바를 `AppleMobileNavigationHeader` 한 개로
통합한다. 헤더는 왼쪽 44px 제어 영역, 화면 정중앙의 자연 높이 제목, 오른쪽
44px 비동작 `…` 영역을 소유한다. iPhone·iPad의 일반 앱과 Projects 모두 원형
뒤로/닫기 버튼을 leading 슬롯으로 넣고 모바일 폼팩터에서는 신호등을 사용하지 않는다.
제목은 좌우 제어의 실제 폭과 관계없이 화면 중앙에 두고, `Center` 안에서 자연
높이로 레이아웃해 아래쪽 가짜 여백을 만들지 않는다. 헤더 자체에는 탭 동작이나
접근성 action을 두지 않고, leading 제어만 독립된 semantics container로 만든다.

Projects의 모바일 Finder는 현재 전체 toolbar를 감싸는 드래그용
`GestureDetector`를 거치지 않고 공용 모바일 헤더를 직접 사용한다. 이렇게 하면
Flutter Web 접근성 레이어에서 닫기 action과 제목이 병합돼 전체 390×64px 헤더가
버튼이 되는 문제를 원인 단계에서 제거한다. desktop Finder의 드래그와 기존
뒤로/앞으로 도구는 그대로 유지한다.

## 앱 카탈로그와 표시 이름

desktop과 mobile이 하나의 launcher 목록을 공유하던 구조를 분리한다. desktop은
`About → Skills → Projects → Terminal → GitHub → Mail → 설정 → Trash` 순서를
사용한다. iPhone·iPad는 노란 메모가 이미 About 진입점이므로 About 아이콘을
제외하고 `Skills → Projects → Terminal → 사진 → GitHub → Mail → 설정 → Trash`
순서를 사용한다. 새 `PortfolioAppId.photos`는 공용 아이콘 프레임과 code-native
사진 artwork를 사용하고, 이번 단계에서는 Light/Dark를 따르는 `사진 준비 중`
화면만 연다. 추후 실제 갤러리는 같은 route를 확장한다.

Projects의 내부 category/id/key는 안정성을 위해 `career`를 유지하되, 공개 위치
label의 단일 source만 `경력`에서 `회사`로 바꾼다. 이 값이 desktop 사이드바,
Finder 제목, iPhone·iPad 하단 탐색과 접근성 label에 자동 전파되도록 한다.

## 검증

TDD로 제목의 자연 높이와 세로·가로 중심, 헤더 빈 영역/제목/`…` 탭 시 앱 유지,
leading 44×44만 닫기, Projects 상세→목록→루트 닫기를 고정한다. 별도 catalog
테스트로 form factor별 목록·순서·About 중복 제거·사진 placeholder를 검증하고,
`회사`가 세 폼팩터의 표시와 semantics에 전파되는지 확인한다. 이후 전체 테스트,
정적 분석, Pages/Vercel 빌드와 390/834/1280px 실화면을 다시 검수한다.
