# iPhone Duo 적응형 화면

- 작성자: 제옹(euijjang97)
- 적용 범위: `UMCApp`의 홈·공지·활동·커뮤니티·마이페이지. iPhone 앱의 배포 대상은 유지한다.

## 레이아웃과 상태

기기 이름이나 접힘 각도를 판별하지 않는다. SwiftUI가 제공하는 컨테이너 폭과
Dynamic Type을 사용하므로 회전·분할 화면·실행 중 크기 변경에도 같은 규칙이 적용된다.

- 홈은 `AdaptiveContentLayout`으로 같은 자식 뷰를 재배치한다. 기본 최소 열 너비는
  340pt, 열 간격은 24pt이며 사용 가능한 콘텐츠 폭이 704pt 이상일 때 두 열을 쓴다.
  각 열은 독립적으로 흐른다. 왼쪽은 시즌·일정, 오른쪽은 상벌점·최근 공지여서
  옆 카드 높이에 맞춘 빈 공간을 만들지 않는다. 좁은 창에서는 시즌·상벌점·일정·공지
  순서로 배치하며 뷰와 접근성 읽기 순서를 재생성하지 않는다. 바깥 여백은 별도다. 접근성 글자 크기에서는 한 열을 유지한다. 최대 콘텐츠 폭은 1100pt다.
- 공지는 하나의 `NavigationSplitView`가 목록과 상세를 소유한다. 상세의 기존
  `PathStore.notice` 경로가 편집·수신 현황·딥링크를 계속 처리하며 시스템이 좁은 창에서
  열을 접는다. 목록은 280–380pt, 상세 본문과 읽음 조작은 최대 720pt로 제한한다.
  넓은 창의 목록은 제목·날짜와 미리보기·상태의 두 줄로 표시한다. 고정 최소 높이와
  카드 그림자를 없애고 커뮤니티와 같은 여백·서체·선택 테두리를 사용한다.
  상세는 대상 태그·제목·작성자/날짜·본문 순으로 읽도록 위계를 정리한다.
- 공지 편집이나 작성 중에는 목록에서 다른 공지를 선택해 현재 경로를 덮어쓸 수 없다.
  생성·수정·삭제 뒤에는 현재 검색어와 필터로 목록을 다시 읽는다.
- 활동은 출석 가능한 세션과 출석 이력을 나란히 표시하고, 운영진 일정 목록은 가용 폭에
  맞춘 독립적인 지연 로딩 열을 사용해 이웃 카드 높이로 생기는 공백을 없앤다.
  출석 카드는 작은 아이콘과 제목·시간/상태 두 줄로 표시하고, 빈 출석 현황은
  간결한 아이콘·설명 행으로 표시한다. 넓은 상세는 지도와 출석 조작을 병렬로 놓는다.
  스터디 카드의 멘토·스터디원과 일정 조작도 가용 폭에 따라 배치한다.
  섹션 레일은 1200pt 이상에서만 표시해 Duo에서 본문 영역을 불필요하게 줄이지 않는다.
  접근성 글자 크기에서는 한 열과 기존 타이틀 메뉴를 사용한다.
- 마이페이지는 프로필·메뉴 사이드바와 상세를 하나의 `NavigationSplitView`에 유지한다.
  선택 전 상세에는 실제 명함과 프로필 개요를 표시하며 기존 `PathStore.mypage`가
  선택 상세를 소유한다. 편집·설정·계정 및 알 수 없는 하위 경로는 메뉴 선택으로
  덮어쓰지 않는다. 접기·펼치기에도 같은 상세와 편집 상태를 유지한다.
- 커뮤니티는 목록과 채팅을 하나의 `NavigationSplitView`에 유지한다. 상세 경로와
  채팅 ViewModel을 크기에 따라 다시 만들지 않아 초안·스크롤·실시간 구독을 보존한다.
  작성 중인 메시지·답장·편집이 있으면 다른 방으로 이동하기 전에 삭제 확인을 받는다.
  생성·편집·하위 상세 경로는 목록 선택으로 덮어쓰지 않는다. 명시적으로 같은 방을
  다시 선택하면 읽지 않음 배지를 지우되 초안은 유지한다.
  목록의 native List·스와이프·페이지네이션을 유지하며 제목·시각과 최근 메시지·상태를
  두 줄로 표시한다. 아이콘은 기본 32pt, 행 내부 여백은 가로 16pt·세로 8pt다.
  공지와 같은 280–380pt 사이드바·inline 제목·1pt 선택 테두리를 사용한다. 긴 말풍선은 로컬 폭에
  따라 최대 520pt까지 확장하며 메시지 영역과 입력창은 같은 720pt 중심선을 사용한다.
  넓은 창에서는 채팅 중에도 기본 탭 막대를 표시한다. 상세 영역은 공지와 같은
  콘텐츠 배경과 네이티브 제목·부제를 사용해 사이드바와 구분한다. 일반 iPhone과
  좁은 화면의 채팅도 같은 밝은 콘텐츠 배경을 사용하며 기존 헤더 배치는 유지한다.

`NavigationStack`과 ViewModel을 폭 조건으로 새로 만들지 않는다. 홈의 선택 날짜·월,
공지 검색·필터, 활동의 선택 섹션과 각 탭 경로는 크기 변경과 독립적으로 유지한다.
좁은 창에서 넓은 창으로 돌아오면 분할 사이드바를 다시 표시한다.
시스템 safe area와 탐색 막대를 사용하고, 홈 카드 눌림 모션은 동작 줄이기를 따른다.

## 검증 실행

저장소 루트에서 다음 명령을 실행한다. 설치된 시뮬레이터 이름은 환경에 맞게 지정한다.

```bash
make -C UMCApp generate
make -C UMCApp build DESTINATION='platform=iOS Simulator,name=iPhone Duo'
make -C UMCApp test SCHEME=CoreUIComponents DESTINATION='platform=iOS Simulator,name=iPhone Duo'
make -C UMCApp test SCHEME=UMCApp DESTINATION='platform=iOS Simulator,name=iPhone Duo'
make -C UMCApp test SCHEME=UMCAppAdaptiveUITests DESTINATION='platform=iOS Simulator,name=iPhone Duo'
```

`AdaptiveContentLayoutTests`는 열 전환 경계, 반복 크기 변경, 접근성 한 열 정책과
실제 SwiftUI 측정 시 높이 증가를 검증한다. `NoticeDeepLinkRoutingTests`는 딥링크 및
작성 경로 보존을 검증한다. `AdaptiveContinuityUITests`는 stub 세션에서 월 선택·공지 상세의
회전/탭 전환 연속성, 커뮤니티 작성 초안, 큰 글자의 달력 조작 영역을 검증하고
마이페이지 설정 상세의 회전/탭 전환 연속성을 검증한다.
다섯 탭의 앱 스크린샷을 결과 번들에 남긴다. Duo의 비활성 디스플레이를 캡처하면
검은 이미지가 나올 수 있으므로 결과를 직접 확인하고 활성 디스플레이 캡처로 보완한다. `CommunitySplitSelectionTests`는 생성·편집·
중첩 경로 보호를, `MessageBubbleLayoutTests`는 좁은 폭과 넓은 폭의 실제 렌더링을 검증한다.

UI 테스트는 기존 `-stubSession` 및 `--notice-force-permission` Debug 실행 인자를 사용한다.
기존 `MOCK_AUTH_BYPASS=1` 환경 변수로 테스트에서 인증 소개 연출도 생략한다.
권한 인자는 더미 세션에서 실제 공지 권한 API를 호출해 로그아웃되는 것을 막는다. 프로덕션
인증·권한 처리나 배포 최소 버전(iOS 26.4)을 변경하지 않는다.

실제 Duo 검증에서는 Device Hub에서 접기·펼치기, 양쪽 회전, 분할 화면을 반복한다.
홈에서 다음 달 선택, 공지 검색 후 상세·작성 진입, 활동 섹션 선택을 먼저 수행한 뒤
각 변경 후 상태와 뒤로가기 동작을 확인한다. 시뮬레이터 검증은 실기기 검증을 대신하지 않는다.

## 검증 기록 (2026-11-02)

Xcode 27.2 SDK로 빌드했으며 배포 최소 버전은 iOS 26.4다. iOS 26.5 시뮬레이터에서
CoreUIComponents 53개, CommunityPresentation 278개, MyPagePresentation 69개,
NoticePresentation 31개, 앱의 NoticeDeepLinkRoutingTests 5개가 통과했다.
공지 목록의 긴 제목·미리보기가 320pt 폭의 간결한 행 안에 들어가는 실제 SwiftUI 측정도 포함한다.

Duo iOS 27.2에서는 다섯 탭 진입, 홈 월 선택 유지, 공지 상세 회전·탭 복귀,
커뮤니티 초안 회전, 마이페이지 설정 회전·탭 복귀의 일반 크기 UI 테스트 5개가 통과했다.
큰 글자 UI 검증은 이번 완료 범위에 포함하지 않는다. XCTest 이미지가 비활성 디스플레이를
캡처해 검게 나오는 경우가 있어 실제 화면은 Device Hub와 활성 디스플레이 캡처로 확인한다.
최종 화면은 Duo의 다섯 탭과 공지·채팅 상세, iPhone 17 Pro(iOS 26.5)의 밝은 채팅 배경을
일반 글자 크기에서 직접 확인했다. 실제 접기·펼치기에서는 홈의 선택 월과 커뮤니티의
선택 방·초안 및 다시 펼친 사이드바를 확인했다. 실기기와 운영 서버의 실시간 메시지
송수신은 검증하지 않았다.

더미 커뮤니티 저장소는 조회할 때마다 고정된 읽지 않음 개수를 반환한다. 따라서 사이드바를
접었다가 펼치며 다시 조회하면 더미 배지가 되살아날 수 있다. 운영 저장소의 읽음 상태
검증과 구분해야 한다.

## 최종 화면

아래 이미지는 더미 세션의 일반 글자 크기로 확인한 최종 시뮬레이터 화면이다.

| 화면 | 검토 자료 |
|---|---|
| 홈 | [독립적인 두 열](Evidence/iPhone-Duo/home-verified-final.png) |
| 공지 | [간결한 목록](Evidence/iPhone-Duo/notice-slim-final.png) · [선택 상세](Evidence/iPhone-Duo/notice-detail-final.png) |
| 활동 | [출석 목록과 빈 현황](Evidence/iPhone-Duo/activity-slim-final.png) |
| 커뮤니티 | [Duo 목록·채팅](Evidence/iPhone-Duo/community-white-duo-final.png) · [일반 iPhone 채팅](Evidence/iPhone-Duo/community-white-iphone-final.png) |
| 마이페이지 | [메뉴·프로필 분할](Evidence/iPhone-Duo/mypage-final.png) |

## 근거

- [Apple: Get ready for iPhone Duo](https://developer.apple.com/iphone-duo/)
- [Apple: Prepare your app for iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111461/)
- [Apple: Adaptive layouts on iPhone Duo](https://developer.apple.com/videos/play/tech-talks/111463/)
- [SwiftUI Layout](https://developer.apple.com/documentation/swiftui/layout)
