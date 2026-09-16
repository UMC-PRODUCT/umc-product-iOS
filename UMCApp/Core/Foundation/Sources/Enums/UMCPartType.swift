//
//  UMCPartType.swift
//  UMCFoundation
//
//  Created by 이예지 on 5/8/26.
//

import Foundation

/// UMC 동아리의 파트(직무) 유형을 정의하는 열거형입니다.
///
/// UMC는 기획·디자인과 개발 파트로 구성되며, 이 열거형은 각 파트와 세부 기술 스택을
/// 타입 안전하게 표현합니다.
///
/// 11기부터 개발 파트가 ``webProductEngineer``·``mobileProductEngineer`` 두 값으로
/// 개편됐고, 서버(Spring/Node)·프론트(Web/Android/iOS)는 구 기수 기록을 읽기 위한
/// 레거시로만 남았습니다 (#1351).
///
/// - Note: Associated Value를 사용하여 서버/프론트 파트의 세부 기술 스택을 구분합니다.
///
/// - Usage:
/// ```swift
/// let userPart: UMCPartType = .front(type: .ios)
/// print(userPart.name)  // "iOS"
///
/// let serverPart: UMCPartType = .server(type: .spring)
/// print(serverPart.name)  // "Spring"
/// ```
public enum UMCPartType: Codable, Equatable, Hashable, Sendable {
    // MARK: - Cases

    /// 운영진 파트
    case admin

    /// 기획 파트 (Project Manager)
    case pm

    /// 디자인 파트 (UI/UX Designer)
    case design

    /// 서버 파트 (Backend Developer)
    ///
    /// - Parameter type: 서버 기술 스택 (Spring, Node.js)
    case server(type: ServerType)

    /// 프론트 파트 (Frontend Developer)
    ///
    /// - Parameter type: 프론트 기술 스택 (Web, Android, iOS)
    ///
    /// - Note: 레거시 파트다. 서버가 `WEB`·`ANDROID`·`IOS` 를 신규 발급하지 않고
    ///   구 기수 보존용으로만 남겼다 (#1351). 삭제하면 지난 기수 기록을 못 읽는다.
    case front(type: FrontType)

    /// 웹 프로덕트 엔지니어 파트 (서버 `WEB_PRODUCT_ENGINEER`)
    ///
    /// 11기부터 개발 파트를 대체한 두 파트 중 하나다. 기존 `WEB` 과 별개 값이라
    /// 같은 화면에 구·신 기수가 섞이면 두 파트가 함께 보인다.
    case webProductEngineer

    /// 모바일 프로덕트 엔지니어 파트 (서버 `MOBILE_PRODUCT_ENGINEER`)
    ///
    /// 11기부터 레거시 `IOS`·`ANDROID` 를 대체한다.
    case mobileProductEngineer

    // MARK: - Property

    /// 파트의 표시 이름을 반환합니다.
    ///
    /// - Returns:
    ///   - PM: "PM"
    ///   - Design: "Design"
    ///   - Server: "Spring" 또는 "NodeJS"
    ///   - Front: "Web", "Android", "iOS"
    ///   - Product Engineer: "웹 프로덕트 엔지니어", "모바일 프로덕트 엔지니어"
    ///
    /// - Note: 신규 두 파트만 한글 표시명이다. 서버 `ChallengerPart` 가 확정한
    ///   `displayName` 을 그대로 쓰며, 영문으로 줄이면 레거시 `Web` 과 겹친다.
    public var name: String {
        switch self {
        case .admin:
            return "Admin"
        case .pm:
            return "PM"
        case .design:
            return "Design"
        case .server(let type):
            return type.rawValue
        case .front(let type):
            return type.rawValue
        case .webProductEngineer:
            return "웹 프로덕트 엔지니어"
        case .mobileProductEngineer:
            return "모바일 프로덕트 엔지니어"
        }
    }

    /// 파트의 정렬 순서를 반환합니다.
    ///
    /// 정렬 순서: PM(0) > Design(1) > Web(2) > iOS(3) > Android(4) > Spring(5) >
    /// NodeJS(6) > 웹 프로덕트 엔지니어(7) > 모바일 프로덕트 엔지니어(8)
    ///
    /// - Note: 화면 정렬 전용 값이라 서버 `ChallengerPart.sortOrder` 와 일치하지
    ///   않는다(운영진이 서버 7, 여기선 -1). 신규 파트는 기존 7종 뒤에 이어 붙인다.
    public var sortOrder: Int {
        switch self {
        case .admin:
            return -1
        case .pm:
            return 0
        case .design:
            return 1
        case .front(let type):
            switch type {
            case .web:
                return 2
            case .ios:
                return 3
            case .android:
                return 4
            }
        case .server(let type):
            switch type {
            case .spring:
                return 5
            case .node:
                return 6
            }
        case .webProductEngineer:
            return 7
        case .mobileProductEngineer:
            return 8
        }
    }

    /// 파트별 아이콘
    public var icon: String {
        switch self {
        case .admin: return "person.badge.key.fill"
        case .pm: return "doc.text.fill"
        case .design: return "paintpalette.fill"
        case .server(type: .spring): return "leaf.fill"
        case .server(type: .node): return "hexagon.fill"
        case .front(type: .web): return "globe"
        case .front(type: .android): return "inset.filled.applewatch.case"
        case .front(type: .ios): return "apple.logo"
        case .webProductEngineer: return "laptopcomputer"
        case .mobileProductEngineer: return "iphone"
        }
    }

    /// 모든 파트 조합 (Associated Value로 CaseIterable 불가하여 직접 정의)
    public static let allCases: [UMCPartType] = [
        .pm, .design,
        .server(type: .spring), .server(type: .node),
        .front(type: .web), .front(type: .android),
        .front(type: .ios),
        .webProductEngineer, .mobileProductEngineer
    ]

    // MARK: - Nested Types

    /// 서버 파트의 기술 스택을 정의하는 열거형입니다.
    public enum ServerType: String, Codable, Equatable, Hashable, Sendable {
        /// Spring Framework 기반 백엔드 개발
        case spring = "Spring"

        /// Node.js 기반 백엔드 개발
        case node = "NodeJS"
    }

    /// 프론트 파트의 기술 스택을 정의하는 열거형입니다.
    public enum FrontType: String, Codable, Equatable, Hashable, Sendable {
        /// 웹 프론트엔드 개발 (React, Vue 등)
        case web = "Web"

        /// Android 네이티브 앱 개발 (Kotlin/Java)
        case android = "Android"

        /// iOS 네이티브 앱 개발 (Swift)
        case ios = "iOS"
    }

    // MARK: - API 변환

    /// 서버 API 쿼리 파라미터용 문자열
    public var apiValue: String {
        switch self {
        case .admin:                    return "ADMIN"
        case .pm:                       return "PLAN"
        case .design:                   return "DESIGN"
        case .server(let type):
            switch type {
            case .spring:               return "SPRINGBOOT"
            case .node:                 return "NODEJS"
            }
        case .front(let type):
            switch type {
            case .web:                  return "WEB"
            case .android:              return "ANDROID"
            case .ios:                  return "IOS"
            }
        case .webProductEngineer:       return "WEB_PRODUCT_ENGINEER"
        case .mobileProductEngineer:    return "MOBILE_PRODUCT_ENGINEER"
        }
    }

    /// 서버 API 문자열로부터 생성
    public init?(apiValue: String) {
        switch apiValue {
        case "ADMIN":       self = .admin
        case "PLAN":        self = .pm
        case "DESIGN":      self = .design
        case "SPRINGBOOT":  self = .server(type: .spring)
        case "NODEJS":      self = .server(type: .node)
        case "WEB":         self = .front(type: .web)
        case "ANDROID":     self = .front(type: .android)
        case "IOS":         self = .front(type: .ios)
        case "WEB_PRODUCT_ENGINEER":    self = .webProductEngineer
        case "MOBILE_PRODUCT_ENGINEER": self = .mobileProductEngineer
        default:            return nil
        }
    }

    // MARK: - Codable

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)

        guard let part = UMCPartType(apiValue: rawValue) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid UMCPartType api value: \(rawValue)"
            )
        }
        self = part
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiValue)
    }
}
