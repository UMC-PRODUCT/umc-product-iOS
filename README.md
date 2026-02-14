# UMC PRODUCT TEAM iOS

> UMC Product Team이 제작하는 iOS 애플리케이션입니다. (1st)

[![Swift](https://img.shields.io/badge/Swift-6.2-orange.svg)]()
[![Xcode](https://img.shields.io/badge/Xcode-26.2-blue.svg)]()
[![iOS](https://img.shields.io/badge/iOS-18.0+-blue.svg)]()

---

<br>

## 👥 멤버
| 리버/이재원 | 제옹/정의찬 | 마티/김미주 | 소피/이예지 |
|:------:|:------:|:------:|:------:|
| <img src="https://github.com/user-attachments/assets/a4ddee14-419e-41da-a89a-e2c2fb23a03f" width="300" height="250"> | <img src="https://github.com/user-attachments/assets/00ba6ec3-d252-4e93-b467-b0d0ba654fb4" width="300" height="250"> | <img src="https://github.com/user-attachments/assets/7842f405-80c3-4394-8978-617c020f47d5" width="300" height="250"> | <img src="https://github.com/user-attachments/assets/1749df32-f292-4613-916d-b88cf2390cd2" width="300" height="250"> |
| PL | iOS, PM | iOS | iOS |
| [리버](https://github.com/jwon0523) | [제옹](https://github.com/JEONG-J) | [마티](https://github.com/alwn8918) | [소피](https://github.com/LeeYeJi546) |

<br>


## 📱 소개

> **"Focus on Growth, We Handle the Ops"**

UMC(University MakeUs Challenge) 동아리 운영 관리 앱입니다.

디스코드, 구글 시트, 노션으로 분산된 운영 도구를 하나의 앱으로 통합하여 운영 효율성을 높이고, 부원들이 성장에만 집중할 수 있는 환경을 제공합니다.

**주요 기능**
- 공지사항 수신 확인 (The Ping) - 미확인자 추적 및 재알림
- Mobile-First Admin - PC 없이 출석/경고/공지 관리
- GPS 기반 스마트 출석 - 지오펜싱을 활용한 자동 출석 인증
- 커뮤니티 게시판 - 지부/학교 간 네트워킹

<br>

## 📆 프로젝트 기간
- 1기 기간: `2025.12.27 - 2026.02.20`

<br>

## 🤔 요구사항
For building and running the application you need:

iOS 26.0+ <br>
Xcode 26.2 <br>
Swift 6.2

<br>

## 🔐 시크릿 / Firebase 설정 안내

- `Secrets.xcconfig`의 실제 키 값(`BASE_URL`, `KAKAO_KEY`)은 **팀 내부 문서**를 확인해 설정해주세요.
- `GoogleService-Info.plist` 역시 **팀 내부 문서 가이드**에 따라 발급/배치 후 사용해주세요.
- 보안상 실제 키/설정 파일은 원격 저장소에 업로드하지 않습니다.

<br>

## ⚒️ 기술 스택 & 개발 환경
### Envrionment
<div align="left">
<img src="https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white" />
<img src="https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white" />
<img src="https://img.shields.io/badge/SPM-FA7343?style=for-the-badge&logo=swift&logoColor=white" />
<img src="https://img.shields.io/badge/Fastlane-n?style=for-the-badge&logo=fastlane&logoColor=black" />
</div>

### Development
<div align="left">
<img src="https://img.shields.io/badge/Xcode_26.2-007ACC?style=for-the-badge&logo=Xcode&logoColor=white" />
<img src="https://img.shields.io/badge/Swift_6.2-FA7343?style=for-the-badge&logo=swift&logoColor=white" />
<img src="https://img.shields.io/badge/SwiftUI-42A5F5?style=for-the-badge&logo=swift&logoColor=white" />
<img src="https://img.shields.io/badge/Alamofire-FF5722?style=for-the-badge&logo=swift&logoColor=white" />
<img src="https://img.shields.io/badge/Moya-8A4182?style=for-the-badge&logo=swift&logoColor=white" />
<img src="https://img.shields.io/badge/Combine-FF2D55?style=for-the-badge&logo=apple&logoColor=white" />
</div>

### Communication
<div align="left">
<img src="https://img.shields.io/badge/Notion-white.svg?style=for-the-badge&logo=Notion&logoColor=000000" />
<img src="https://img.shields.io/badge/Discord-5865F2?style=for-the-badge&logo=Discord&logoColor=white" />
<img src="https://img.shields.io/badge/Slack-4A154B?style=for-the-badge&logo=slack&logoColor=white" />
<img src="https://img.shields.io/badge/Figma-F24E1E?style=for-the-badge&logo=figma&logoColor=white" />
</div>

<br>

## 📱 화면 구성
<table>
  <tr>
    <td>
      사진 넣어주세요
    </td>
    <td>
      사진 넣어주세요
    </td>
   
  </tr>
</table>

<br>

## 🧪 테스트 실행 방법

```bash
# 전체 테스트
xcodebuild -project AppProduct/AppProduct.xcodeproj \
  -scheme AppProduct \
  test
```

- 인증 연동 테스트는 루트의 `.test-config.json`이 필요합니다.
- 샘플 형식은 `AppProduct/AppProductTests/AuhTest/EmailVerificationTests.swift`를 참고하세요.

<br>

## 🔔 FCM / 알림 히스토리 동작 요약

- 앱 실행 시 `AppDelegate`에서 Firebase Messaging을 초기화합니다.
- 권한/토큰 상태를 확인해 FCM 토큰 서버 등록을 시도합니다.
- 수신된 알림은 `NoticeHistoryData`로 SwiftData에 저장됩니다.
- CloudKit 사용 가능 시 동기화하고, 실패 시 로컬 저장소로 폴백합니다.

관련 코드:
- `AppProduct/AppProduct/App/AppDelegate.swift`
- `AppProduct/AppProduct/App/AppProductApp.swift`
- `AppProduct/AppProduct/Features/Home/Domain/Models/NoticeHistory/NoticeHistoryData.swift`

<br>

## 🧾 Git / PR 규칙

### 커밋 메시지

- 형식: `feat: 작업 내용`
- 본문: 상세 설명 2줄 이상 필수

예시:

```text
feat: 일정 상세 수정 API 연동

- 수정 모드에서 확인 버튼 액션을 updateSchedule 호출로 연결했습니다.
- API 완료 전 화면이 닫히지 않도록 처리하고 로딩 상태를 분리했습니다.
```

### PR

- PR 제목은 작업 의도가 바로 보이도록 `기능/영향 범위` 중심으로 작성합니다.
- PR 본문에는 최소한 `작업 내용`, `변경 이유`, `리뷰 포인트`, `추후 작업`을 모두 작성합니다.
- UI 변경이 있으면 스크린샷 또는 영상을 반드시 첨부합니다.
- `main`/`develop` 브랜치에는 직접 푸시하지 않고, 기능 브랜치에서 PR로만 반영합니다.
- 머지 전 최소 1명 이상의 Approve를 받은 뒤 병합합니다.
- 머지 방식은 `Squash and Merge`를 기본으로 사용합니다.

<br>

## 📚 참고 문서 / 트러블슈팅

### 참고 문서

- `AppProduct/Documentation.docc/Resources/NETWORK_API_GUIDE.md`
- `AppProduct/Documentation.docc/Resources/SECRET_CIDCD_GUIDE.md`
- `AppProduct/Documentation.docc/Resources/NOTICE_CLASSIFIER_GUIDE.md`
- `AppProduct/Documentation.docc/Resources/SCHEDULE_CLASSIFIER_GUIDE.md`

### 트러블슈팅

- `SwiftData CloudKit init failed` 로그는 CloudKit 실패 후 로컬 폴백 상황일 수 있습니다.
- 시뮬레이터에서는 APNS 토큰 미설정으로 FCM 토큰 발급이 제한될 수 있습니다.
- Preview에서 ModelContainer 관련 오류가 나면 in-memory 컨테이너 주입 여부를 확인하세요.

<br>

## 🤖 CoreML

- CoreML 기반 알림 분류(예: success/warning/error/info) 테스트 코드를 통해 분류 결과를 검증합니다.
- 학습/실험 관련 리소스는 `AppProduct/AppleCreateML` 경로를 기준으로 관리합니다.
- 분류 결과는 알림 히스토리 UI 아이콘/색상 매핑에 활용됩니다.
