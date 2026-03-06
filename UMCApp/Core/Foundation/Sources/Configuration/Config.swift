//
//  Config.swift
//  UMCFoundation
//
//  Created by euijjang97 on 3/6/26.
//

import Foundation

/// `Info.plist`에 노출된 앱 설정 값을 조회하는 진입점입니다.
///
/// 하위 모듈이 `Bundle.main`을 직접 읽지 않도록 런타임 설정 조회를 이
/// 네임스페이스로 모읍니다. `Config.API`, `Config.Auth` 같은 세부 설정은
/// 여기서 읽은 원시 plist 값을 모듈별 타입으로 변환해 제공합니다.
public enum Config {
    // MARK: - Property

    /// 현재 실행 중인 앱 번들의 `Info.plist` 딕셔너리입니다.
    ///
    /// 모든 설정 accessor가 같은 값을 재사용할 수 있도록 한 번만 읽어 캐시합니다.
    /// 앱 실행에 필요한 설정이 빠진 상태는 복구 가능한 오류가 아니므로,
    /// plist 자체를 찾지 못하면 즉시 종료합니다.
    static let infoDictionary: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Info.plist not found")
        }
        return dict
    }()

    // MARK: - Function

    /// 지정한 plist 키에 대응하는 비어 있지 않은 문자열 설정 값을 반환합니다.
    ///
    /// - Parameter key: 조회할 `Info.plist` 키입니다.
    /// - Returns: `key`에 저장된 비어 있지 않은 문자열 값입니다.
    /// - Important: 이 helper는 값이 이미 build setting 또는 `xcconfig`를 통해
    ///   앱의 plist에 주입되어 있다고 가정합니다.
    /// - Precondition: `Info.plist`에 `key`에 해당하는 비어 있지 않은 문자열이 존재해야 합니다.
    static func stringValue(for key: String) -> String {
        guard let value = infoDictionary[key] as? String,
              value.isEmpty == false else {
            fatalError("\(key) not found in Info.plist")
        }
        return value
    }
}
