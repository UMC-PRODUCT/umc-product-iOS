# Secrets (xcconfig 기반 환경/시크릿 주입)

앱 타겟의 `BASE_URL`·`KAKAO_KEY`·`TMAP_SECRET_KEY` 를 빌드 설정(xcconfig) → `Info.plist` → `Config`(UMCFoundation) 경로로 주입합니다.

- 작성자: 제옹(euijjang97)

## 파일 구성

| 파일 | 배치 경로 | 커밋 | 역할 |
|------|-----------|------|------|
| `Shared.xcconfig` | `UMCApp/Secrets/` | ✅ | 앱 타겟이 참조하는 진입 xcconfig. 비밀이 아닌 기본값 + 환경별 `BASE_URL` 정의. 마지막에 `Secrets.xcconfig` 를 선택적 포함. |
| `Secrets.xcconfig.template` | `UMCApp/Secrets/` | ✅ | 로컬 시크릿 템플릿(플레이스홀더). |
| `Secrets.xcconfig` | `UMCApp/Secrets/` | ❌ (gitignore) | 개발자별 실제 키. `Shared.xcconfig` 기본값을 오버라이드. |
| `GoogleService-Info.plist` | `UMCApp/UMCApp/Resources/` | ❌ (gitignore) | Firebase(FCM 푸시·RemoteConfig) 설정. 없으면 `UMCAppApp.configureFirebaseIfNeeded()` 가 구성을 건너뛴다. |

두 시크릿 모두 **팀 공유 채널에서 수령**합니다. (`GoogleService-Info.plist` 는 Firebase 콘솔 →
프로젝트 `umcproduct-6cbe1` → 프로젝트 설정 → iOS 앱 `com.umc.product` 에서도 내려받을 수 있습니다.)

## 최초 세팅

```bash
cd UMCApp/Secrets
cp Secrets.xcconfig.template Secrets.xcconfig
# Secrets.xcconfig 를 열어 팀 채널에서 받은 실제 값 입력
cd ..

# Firebase 설정 파일을 앱 리소스 폴더에 배치 (buildableFolders 로 자동 포함됨)
cp ~/Downloads/GoogleService-Info.plist UMCApp/Resources/

make generate
```

Debug 빌드는 두 파일이 없어도 통과합니다 — `Shared.xcconfig` 의 `#include?` 가 에러 없이 넘어가고
기본(dev) 값이 쓰이며, Firebase 는 구성 없이 fail-open 으로 동작합니다.

## 누락 가드 (Release 빌드 실패)

앱 타겟의 Pre-action Run Script `Scripts/verify-secrets.sh` (`Project.swift` 의 `scripts:`)가
빌드 시작 전에 아래를 검사합니다.

- `KAKAO_KEY` / `TMAP_SECRET_KEY` / `GOOGLE_CLIENT_ID` / `GOOGLE_REVERSED_CLIENT_ID` 가
  비었거나 템플릿 플레이스홀더(`YOUR_..._HERE`)인지
- `GoogleService-Info.plist` 존재 여부 · plist 유효성 · `GOOGLE_APP_ID` 가 플레이스홀더(`__`)가 아닌지

| Configuration | 동작 |
|---------------|------|
| `Release` | **`error:` 로 빌드 실패** — 키 없는 아카이브가 스토어로 나가는 것을 막는다. |
| `Debug` | `warning:` 만 출력하고 통과 — 신규 클론·CI 는 시크릿 없이도 빌드/테스트되어야 한다. |

시크릿이 없으면 카카오 로그인(URL Scheme 이 `kakao` 로 깨짐)·구글 로그인·TMap 지오코딩·FCM 푸시가
**빌드는 성공한 채 런타임에만** 죽기 때문에, 이 가드가 유일한 조기 경보입니다.

## 값이 흐르는 경로

```
Shared.xcconfig (+ Secrets.xcconfig 오버라이드)
   → Project.swift 앱 타겟 infoPlist: "$(BASE_URL)" 등 치환
   → Info.plist
   → Config.stringValue(for:) / Config.API.baseURL / Config.Auth.kakaoKey / Config.Map.tmapSecretKey
```

## 환경 분기

`BASE_URL[config=Debug]` / `BASE_URL[config=Release]` 로 빌드 Configuration 에 따라 서버가 자동 선택됩니다.

## CI

### GitHub Actions

`.github/workflows/tuist-ci.yml` 이 클론 직후 두 파일을 UMCApp 경로에 주입합니다.

- `Secrets/Secrets.xcconfig` ← `Secrets.xcconfig.template` 복사 (플레이스홀더 값)
- `UMCApp/Resources/GoogleService-Info.plist` ← `secrets.GOOGLE_SERVICE_INFO_PLIST_BASE64` 디코드
  (시크릿 미설정 환경(fork PR 등)에서는 스킵)

CI 는 Debug 구성으로 빌드하므로 위 가드는 경고만 남깁니다.

### Xcode Cloud

`UMCApp/ci_scripts/ci_post_clone.sh` 가 클론 직후 App Store Connect 환경 변수를 읽어
두 파일을 만듭니다. Release 아카이브는 실제 값이 없으면 위 가드에 걸려 실패하므로
아래 환경 변수를 App Store Connect 워크플로에 등록해야 합니다.

| 환경 변수 | 필수 | 설명 |
|-----------|------|------|
| `GOOGLE_SERVICE_INFO_PLIST_BASE64` | ✅ | 새 `GoogleService-Info.plist` 의 base64. 대안으로 `GOOGLE_SERVICE_INFO_PLIST_CONTENT`(raw XML) 도 받습니다. |
| `BASE_URL_DEBUG` · `BASE_URL_RELEASE` | ✅ | 환경별 API 서버 주소. 레거시 `BASE_URL` 하나만 있으면 양쪽에 같은 값을 씁니다. |
| `KAKAO_KEY` | ✅ | 카카오 네이티브 앱 키. |
| `TMAP_SECRET_KEY` | ✅ | TMap Geocoding Secret Key. |
| `GOOGLE_CLIENT_ID` | ✅ | Firebase 프로젝트에 딸린 iOS OAuth 클라이언트 ID. |
| `GOOGLE_REVERSED_CLIENT_ID` | ⬜ | 생략하면 `GOOGLE_CLIENT_ID` 에서 `com.googleusercontent.apps.<unique>` 로 자동 도출합니다. |

스크립트가 만드는 xcconfig 키 집합은 `Shared.xcconfig` 가 기본값으로 선언해 둔 것과 같습니다
(`KAKAO_KEY` · `TMAP_SECRET_KEY` · `GOOGLE_CLIENT_ID` · `GOOGLE_REVERSED_CLIENT_ID` · `BASE_URL`).
`APS_ENVIRONMENT` 처럼 `Shared.xcconfig` 가 스스로 결정하는 값은 덮어쓰지 않습니다.

> ⚠️ UMCApp 은 Tuist 프로젝트라 `UMCApp.xcworkspace` 가 레포에 없습니다. Xcode Cloud 워크플로가
> 이 워크스페이스를 빌드하려면 post-clone 이후 `tuist install` · `tuist generate` 단계가 필요합니다.

> 레거시 `AppProduct/ci_scripts/ci_post_clone.sh` 는 동결된 `v2.2.0` 경로에 파일을 쓰므로
> UMCApp 빌드에서는 쓰지 않습니다. (읽기 전용 — 수정 금지)

## Firebase 프로젝트를 교체할 때

Firebase 프로젝트를 새로 만들면 `GoogleService-Info.plist` 와 Google OAuth 클라이언트 ID 가 함께
바뀝니다. plist 는 gitignore 대상이라 레포 파일 교체만으로 끝나지 않고 아래 **세 지점을 각각**
갱신해야 합니다. 하나라도 빠지면 그 경로의 빌드만 옛 프로젝트를 계속 바라봅니다.

| # | 갱신 지점 | 무엇을 바꾸나 | 누가/어디서 |
|---|-----------|---------------|-------------|
| 1 | 로컬 개발 환경 | `UMCApp/UMCApp/Resources/GoogleService-Info.plist` 교체 + `UMCApp/Secrets/Secrets.xcconfig` 의 `GOOGLE_CLIENT_ID` · `GOOGLE_REVERSED_CLIENT_ID` 갱신 | 팀원 각자 (새 파일·값은 팀 공유 채널로 재배포) |
| 2 | GitHub Actions | 레포 시크릿 `GOOGLE_SERVICE_INFO_PLIST_BASE64` 를 새 plist 의 base64 로 갱신 | 레포 Settings → Secrets and variables → Actions |
| 3 | Xcode Cloud | 환경 변수 `GOOGLE_SERVICE_INFO_PLIST_BASE64` · `GOOGLE_CLIENT_ID` · `GOOGLE_REVERSED_CLIENT_ID` 갱신 | App Store Connect → Xcode Cloud → 워크플로 환경 변수 |

base64 는 이렇게 만듭니다.

```bash
base64 -i UMCApp/UMCApp/Resources/GoogleService-Info.plist | pbcopy
```

`Secrets.xcconfig` 의 `GOOGLE_CLIENT_ID` · `GOOGLE_REVERSED_CLIENT_ID` 는 새 plist 의
`CLIENT_ID` · `REVERSED_CLIENT_ID` 와 **글자 그대로 같아야** 합니다. 어긋나면 구글 로그인이
빌드는 통과한 채 런타임에만 실패합니다.

콘솔 쪽 작업(APNs 인증 키 재업로드, Remote Config 파라미터 재생성, 서버 FCM 서비스 계정 교체)은
이 문서 범위 밖이지만 **빠뜨리면 푸시와 점검 배너가 무음으로 죽습니다.** sender ID 가 바뀌므로
기존 FCM 토큰은 전부 무효가 되고 앱을 다시 켤 때 `AppDelegate` 가 새 토큰을 재등록합니다.

> 스토어에 나가 있는 `v2.2.0`(동결된 `AppProduct`)은 여전히 옛 프로젝트를 바라봅니다.
> 해당 버전 사용자가 빠지기 전까지 옛 Firebase 프로젝트를 삭제하면 안 됩니다.

> xcconfig 에서 `//` 는 주석이므로 URL 은 `https:/$()/...` 형태로 escape 합니다.
