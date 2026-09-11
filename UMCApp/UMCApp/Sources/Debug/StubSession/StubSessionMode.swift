//
//  StubSessionMode.swift
//  UMCApp
//
//  Created by jaewon Lee on 8/3/26.
//

#if DEBUG
import Foundation

/// 검증용 stub 세션 토글 (단일 진실 원천).
///
/// 켜면 앱 시작 시 인증·홈 데이터 Repository를 stub 구현체로 교체해, 로그인 화면을 건너뛰고
/// 픽스처가 채워진 홈으로 바로 들어간다 (`DIContainer+StubSession.swift`). 서버 팀이 카카오
/// 개발자 콘솔에 iOS bundle id를 등록하기 전까지 쓰려고 만든 장치다.
///
/// - Important: 릴리스 빌드에는 이 파일과 stub 구현 전체가 컴파일되지 않는다 (`#if DEBUG`).
///
/// ## 기본값은 실서버다
///
/// 소셜 로그인·딥링크처럼 실제 서버 응답을 봐야 하는 검증이 기본이므로, 아무것도 안 하면
/// 실서버에 붙는다. 픽스처가 필요할 때만 켠다.
///
/// - stub을 켤 때: 스킴 실행 인자에 `-stubSession` 추가
/// - 켜 둔 채 특정 실행만 실서버로 되돌릴 때: 실행 인자 `-realSession`,
///   또는 검증 화면 토글(`UserDefaults`에 남아 기기 단독 실행에도 적용)
///
/// 어느 쪽이든 DI 등록이 앱 시작 시 한 번만 돌기 때문에 앱을 다시 켜야 반영된다.
enum StubSessionMode {

    /// 검증 화면 토글이 쓰는 저장 키.
    private static let realSessionKey = "debug.stubSession.forceRealSession"

    /// stub Repository로 교체할지 여부. `UMCAppApp`이 시작 시 한 번만 읽는다.
    static var isEnabled: Bool {
        guard !isRealSessionForced else { return false }
        return CommandLine.arguments.contains("-stubSession")
    }

    /// 실서버 세션이 강제됐는지. 실행 인자가 최우선이다.
    static var isRealSessionForced: Bool {
        if CommandLine.arguments.contains("-realSession") { return true }
        return UserDefaults.standard.bool(forKey: realSessionKey)
    }

    /// 검증 화면에서 전환한다. 다음 실행부터 적용된다.
    static func setRealSessionForced(_ isForced: Bool) {
        UserDefaults.standard.set(isForced, forKey: realSessionKey)
    }
}
#endif
