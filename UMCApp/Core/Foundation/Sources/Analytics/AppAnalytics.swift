//
//  AppAnalytics.swift
//  UMCFoundation
//
//  Created by euijjang97 on 11/1/26.
//

/// SDK 의존 없이 제품 이벤트를 전달하는 공용 진입점.
///
/// 이벤트 이름과 매개변수는 고정된 분류값만 사용한다. 사용자 식별자, 본문, 검색어,
/// URL, 위치 좌표와 서버 오류 원문은 전달하지 않는다. 앱이 수집기를 설치하기 전에는 no-op이다.
@MainActor
public enum AppAnalytics {

    public typealias Handler = @MainActor @Sendable (String, [String: String]) -> Void

    private static var handler: Handler?

    /// 앱 조립 계층에서 Firebase 초기화에 성공한 뒤 한 번 설치한다.
    public static func configure(handler: @escaping Handler) {
        self.handler = handler
    }

    public static func track(_ event: String, parameters: [String: String] = [:]) {
        handler?(event, parameters)
    }
}
