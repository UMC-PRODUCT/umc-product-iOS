# 스레드 포그라운드 알림 검토와 수정

- 작성자: 제옹(euijjang97)
- 검토일: 2026-10-26
- 범위: `UMCApp/` 포그라운드 표시 정책. 서버는 읽기 전용으로 확인했다.

## 서버 계약 확인

실제 변경은 기본 브랜치 `main`이 아니라 `develop`에 병합됐다. 기준 커밋은
`5129149e41bc24543547407745aa83a32bd5481d`다. `main`의 옛 계약 문서만 보면
스레드 FCM 배선이 없는 것으로 오판하므로 최신 병합 PR과 구현을 함께 확인했다.

- [메시지 알림 #1343](https://github.com/UMC-PRODUCT/umc-product-server/pull/1343)
- [초대 알림 #1398](https://github.com/UMC-PRODUCT/umc-product-server/pull/1398)
- [커스텀 스킴 연결 #1404](https://github.com/UMC-PRODUCT/umc-product-server/pull/1404)
- [CommunityAlarmEventListener](https://github.com/UMC-PRODUCT/umc-product-server/blob/5129149e41bc24543547407745aa83a32bd5481d/monolith/src/main/java/com/umc/product/notification/adapter/in/event/CommunityAlarmEventListener.java)
- [FirebaseFcmMessageAdapter](https://github.com/UMC-PRODUCT/umc-product-server/blob/5129149e41bc24543547407745aa83a32bd5481d/monolith/src/main/java/com/umc/product/notification/adapter/out/external/fcm/FirebaseFcmMessageAdapter.java)

메시지 발송 대상은 ACTIVE 멤버 중 발신자를 제외한 사람이다. 수신자별 메시지 조회가
가능해야 하며 SYSTEM 메시지는 제외한다. 음소거한 사람은 제외하되 멘션 대상이면
음소거를 우회한다. 초대 이벤트는 초대된 멤버에게 발송한다. 현재 앱 화면이나 앱
활성 상태를 검사하는 분기는 이 리스너에 없다.

메시지·초대 모두 `deepLink = umc://thread/{id}`를 전달한다. 별도 스레드 `type`이나
`threadId` 데이터 키는 설정하지 않는다. FCM 어댑터는 title/body를 notification에 넣고
`deepLink`를 String data 맵에 추가한다. 따라서 iOS는 기존 `PushPayload.deepLink`와
`MessageLink`를 재사용한다. `unc://`는 계약에 없으며 지원하지 않는다.

## 수정 전 발견 사항

1. **P1 — 현재 보고 있는 방에서도 배너·소리가 발생한다.**
   `AppDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)`는
   payload나 화면과 무관하게 `[.banner, .sound, .badge]`를 반환했다.
2. **P1 — 표시 중인 스레드의 정체성을 알림 계층에서 알 수 없다.**
   기존 `PathStore`는 타입 소거 NavigationPath를 보관한다. 방이 메모리에 남아 있다는
   사실만으로 표시 중이라고 판단하면 다른 탭·참여자 화면·시트에서도 알림을 잃는다.
3. **서버/클라이언트 경계 — 동일 방 알림 억제는 iOS 표시 정책으로 처리해야 한다.**
   서버 수신자 필터에는 화면 표시 정보가 없다. 모든 포그라운드 알림을 숨기면 다른
   방·공지·출석 알림까지 사라지므로 목적지와 표시 상태를 함께 확인해야 한다.

## 적용한 변경

- App이 소유하는 `ForegroundThreadStore`를 SwiftUI 환경과 AppDelegate에 같은 인스턴스로
  전달한다. 화면마다 UUID 소유권을 사용해 이전 화면의 늦은 종료가 새 화면을 지우지 못하게 했다.
- 방의 appear/disappear, scene active, 선택 탭, 진입 스택 깊이, 헤더 로딩 완료,
  퇴장/삭제 상태, 로컬 시트·전체 화면·Alert 상태를 통해 표시 여부를 갱신한다.
- 앱 전역 점검 화면·공지 Alert·오류 Alert가 덮고 있으면 표시 스레드를 반환하지 않는다.
- 활성 key window가 하나이고 UIKit root가 다른 화면을 present하지 않은 경우에만
  억제한다. PhotosPicker·ShareLink·전체 화면 사진처럼 방이 직접 표시 상태를 소유하지
  않는 화면도 이 검사에 포함한다. 창을 특정할 수 없거나 여러 창이면 알림을 표시한다.
- 앱이 active이고 payload의 스레드 링크와 표시 중인 방 ID가 같을 때만 `[.badge]`를
  반환한다. 다른 방·비활성 상태·링크 누락·해석 불가 알림은 기존 표시 옵션을 유지한다.
- 서버가 메시지와 초대의 종류를 구분하지 않으므로 동일 방 초대도 같은 정책을 적용한다.
- 기존 알림 기록 저장, 출석 상태 갱신, 알림 탭의 딥링크 수신, 실시간 메시지와 읽음
  워터마크 경로는 유지한다. 백그라운드 콜백을 변경하지 않았다.

Universal Links·서버 수정·새 패키지·AppProduct 변경은 필요하지 않아 추가하지 않았다.

## 검증

독립 코드 리뷰에서 시스템 PhotosPicker·ShareLink가 방의 로컬 시트 상태에 포함되지
않는 점이 발견됐다. UIKit의 실제 modal presentation 검사로 보완한 뒤 재검토했으며,
추가로 수정이 필요한 코드 결함은 발견되지 않았다. 이는 실기기 검증을 대체하지 않는다.

- `make -C UMCApp test SCHEME=CoreRouting`: exit 0, 8 tests / 3 suites 통과.
- `make -C UMCApp test SCHEME=CommunityPresentation`: exit 0, 241 tests / 16 suites 통과.
- `make -C UMCApp test SCHEME=UMCApp`: 최종 실행 exit 0, 54 tests / 10 suites 통과.
  테스트 과정에서 변경된 앱과 Feature 소스가 iOS Simulator 대상으로 빌드됐다.
- `git diff --check`: 통과.
- 로컬 로그: `/tmp/thread-notification-generate.log`, `/tmp/thread-routing-tests.log`,
  `/tmp/thread-community-tests.log`, `/tmp/thread-notification-final-tests.log`.
  세 테스트 스킴은 합계 303개 테스트가 통과했다.

- `make -C UMCApp generate`: 성공. 신규 CoreRouting 소스 포함 확인.
- 정책 테스트: 동일 방의 badge 유지, 다른 방/미표시/비활성 상태의 기존 표시,
  공지·출석·오타 스킴·잘못된 링크 회귀를 추가했다.
- 상태 테스트: 이전 소유자의 늦은 종료, 현재 화면 종료, 전역 화면 덮임/복원을 추가했다.
- 실제 APNs/FCM 수신과 기기에서 화면 전환 중의 배너·소리는 별도 실기기 검증이 필요하다.
  로컬 테스트가 서버 배포 완료나 실기기 푸시 수신을 증명하지는 않는다.


### 남은 기기 검증

| 조건 | 기대 결과 |
|---|---|
| 같은 방을 활성 화면으로 보고 있음 | 배너·소리 없음, 기존 badge/알림 기록 동작 유지 |
| 다른 방·다른 탭·참여자 화면 | 배너·소리 유지 |
| PhotosPicker·공유 시트·사진 전체 화면·점검 화면 | 배너·소리 유지 |
| 시스템 시트를 닫고 같은 방으로 복귀 | 같은 방 배너·소리 억제 복원 |
| 앱 inactive/background 또는 종료 상태 | 기존 OS 푸시 표시 및 탭 딥링크 진입 유지 |

실제 FCM 전송, APNs 수신, 시스템 시트의 표시/해제 애니메이션 경계는 이번 로컬 자동
테스트에서 확인하지 않았다. 테스트는 정책·소유권·화면 상태 판정과 앱 컴파일을 검증한다.
관련 작업은 iOS 이슈 #1575와 `bug/1575` 브랜치에서 관리한다.
