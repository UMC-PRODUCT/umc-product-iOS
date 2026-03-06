//
//  MapConfig.swift
//  UMCFoundation
//
//  Created by euijjang97 on 3/6/26.
//

import Foundation

public extension Config {
    /// 지도 및 지오코딩 연동에서 사용하는 설정 모음입니다.
    ///
    /// 지도 공급자용 시크릿을 별도 네임스페이스로 분리해,
    /// 관련 없는 모듈이 인증이나 네트워크 설정에 함께 의존하지 않도록 합니다.
    enum Map {
        // MARK: - Property

        /// TMap 기반 서비스를 호출할 때 사용하는 시크릿 키입니다.
        ///
        /// - Important: 값은 앱의 빌드 설정을 통해 주입되어야 하며,
        ///   `Info.plist`의 `TMAP_SECRET_KEY` 항목으로 노출되어 있어야 합니다.
        public static var tmapSecretKey: String {
            Config.stringValue(for: "TMAP_SECRET_KEY")
        }
    }
}
