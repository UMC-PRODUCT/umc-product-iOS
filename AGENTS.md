# AGENTS.md

이 문서는 이 저장소에서 작업하는 에이전트용 핵심 규칙입니다.
상세 설명은 `CLAUDE.md`를 참고합니다.

## 프로젝트 요약

- 프로젝트: UMC 동아리 운영 관리 iOS 앱
- 스택: SwiftUI, Swift 6.x, iOS 18+
- 핵심 모듈: Auth, Home, Notice, Activity, Community, MyPage

## 아키텍처

- 패턴: Feature-based + Clean Architecture + Observation
- 흐름: `View -> ViewModel -> UseCase -> Repository -> DataSource`
- 의존성: Protocol 기반, `DIContainer`에서 구현체 주입

## 구현 규칙

### ViewModel

- `@Observable` 사용
- 비동기 상태는 `Loadable` 우선
- 화면 내 에러는 `Loadable.failed(AppError)`로 처리
- 전역 중단성 에러는 `ErrorHandler` 사용

### View

- `@State private var viewModel` 패턴 사용
- Action 기반 단방향 데이터 흐름 유지

### 계층 의존성

- Presentation은 UseCase Protocol에만 의존
- UseCase는 Repository Protocol에만 의존
- 구현체 참조는 DIContainer에서만 조립

## 네트워크 규칙

- 공통 응답은 `APIResponse<T>` 디코딩 후 `unwrap()` 사용
- 네트워크 호출은 `MoyaNetworkAdapter` 사용
- 인증/토큰 갱신은 `NetworkClient`에 위임

## 에러 타입 기준

- `NetworkError`: 통신/인증/토큰 갱신 실패
- `RepositoryError`: 서버 비즈니스 실패/디코딩 실패
- `DomainError`: 도메인 규칙 위반
- 최종 화면 표출은 `AppError`로 통합

## 코딩 스타일

- 들여쓰기: 4 spaces
- 최대 줄 길이: 99자
- 불필요한 외부 공개 지양, `private` 우선
- 구획은 `// MARK: - ...` 사용

## Git / PR 규칙

### 커밋 형식

- 형식: `TYPE 작업 내용`
- TYPE: `feat`, `fix`, `refactor`, `docs`, `chore`, `test`, `design`

### PR 규칙

- 최소 1인 Approve 필수
- `main/develop` 직접 푸시 금지
- `Squash and Merge` 사용
- PR 본문은 `.github/pull_request_template.md` 템플릿 사용

## 참고 파일

- `CLAUDE.md`
- `AppProduct/Documentation.docc/Resources/NETWORK_API_GUIDE.md`
- `.github/pull_request_template.md`
