//
//  APIConfig.swift
//  UMCFoundation
//
//  Created by euijjang97 on 3/6/26.
//

import Foundation

public extension Config {
    /// 네트워크 레이어가 API 요청을 구성할 때 사용하는 설정 모음입니다.
    ///
    /// `Config.API`는 plist에 들어 있는 원시 설정 값을 `CoreNetwork`가 바로
    /// 사용할 수 있는 타입 안전한 값으로 변환해 제공합니다. 호출부에서는
    /// `BASE_URL` 문자열을 직접 읽기보다 이 네임스페이스를 통해 접근하는 편이 낫습니다.
    enum API {
        // MARK: - Property

        /// `Info.plist`에서 읽은 원본 API base URL 문자열입니다.
        ///
        /// 일반적으로 빌드 시점에 `Secrets.xcconfig`를 통해 주입되며,
        /// 잘못된 URL 형식을 분리해 진단할 수 있도록 우선 문자열로 유지합니다.
        public static var baseURLString: String {
            Config.stringValue(for: "BASE_URL")
        }

        /// 외부 API 요청을 만들 때 기준이 되는 정규화된 base URL입니다.
        ///
        /// - Returns: `BASE_URL`로부터 생성한 유효한 `URL`입니다.
        /// - Precondition: `BASE_URL`이 `Info.plist`에 존재하고, 절대 URL로 변환 가능해야 합니다.
        public static var baseURL: URL {
            guard let url = URL(string: baseURLString) else {
                fatalError("Invalid Base_URL: \(baseURLString)")
            }
            return url
        }

        /// feature가 별도로 덮어쓰지 않는 한 모든 API 요청이 공유하는 기본 헤더입니다.
        ///
        /// 현재는 JSON 기반 요청을 전제로 한 최소 헤더만 제공하며,
        /// 공통 헤더 정책이 늘어나면 이 값을 기준으로 확장합니다.
        public static var defaultHeaders: [String: String] {
            ["Content-Type": "application/json"]
        }
    }
}
