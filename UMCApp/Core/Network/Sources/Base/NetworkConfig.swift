//
//  NetworkConfig.swift
//  CoreNetwork
//
//  Created by euijjang97 on 3/6/26.
//

import Foundation
import UMCFoundation

/// 네트워크 모듈이 사용하는 런타임 설정을 타입 안전하게 노출합니다.
///
/// `NetworkConfig`는 원시 plist 접근을 `UMCFoundation`에 위임해
/// `CoreNetwork`가 앱 설정 키에 직접 의존하지 않도록 만듭니다.
/// 네트워크 계층의 공통 설정은 이 타입을 통해 읽는 것을 기본으로 합니다.
public enum NetworkConfig {
    // MARK: - Property

    /// 공통 네트워크 클라이언트와 target 정의가 사용하는 base URL입니다.
    ///
    /// 실제 값은 `Config.API.baseURL`에서 가져오며,
    /// 그 내부에서는 앱 번들 설정에 주입된 `BASE_URL` 항목을 읽습니다.
    public static var baseURL: URL {
        Config.API.baseURL
    }

    /// target이 별도로 덮어쓰지 않는 한 요청에 적용되는 기본 HTTP 헤더입니다.
    ///
    /// 현재 기본값은 JSON 요청을 위한 최소 헤더이며,
    /// 공통 헤더 정책이 추가되면 이 값을 기준으로 확장합니다.
    public static var defaultHeaders: [String: String] {
        Config.API.defaultHeaders
    }
}
