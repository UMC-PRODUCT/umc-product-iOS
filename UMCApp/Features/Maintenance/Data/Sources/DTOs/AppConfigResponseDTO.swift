//
//  AppConfigResponseDTO.swift
//  MaintenanceData
//
//  Created by euijjang97 on 9/17/26.
//

import Foundation
import MaintenanceDomain
import UMCFoundation

/// GitHub Pages에 올라간 원격 설정 파일(`app-config.json`) 응답 DTO.
///
/// API 서버가 아니라 정적 JSON이라 서버 응답 봉투(`isSuccess`/`result`)가 없다.
struct AppConfigResponseDTO: Codable, Sendable {

    // MARK: - Property

    /// 앱이 해석할 줄 아는 설정 파일 형식 버전.
    static let supportedVersion = 1

    let version: Int?
    let minimumVersion: String
    let notices: [RemoteNoticeDTO]

    private enum CodingKeys: String, CodingKey {
        case version
        case minimumVersion
        case notices
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        version = try container.decodeIntFlexibleIfPresent(forKey: .version)
        minimumVersion = try container.decodeIfPresent(
            String.self,
            forKey: .minimumVersion
        ) ?? ""
        notices = try container.decodeIfPresent([RemoteNoticeDTO].self, forKey: .notices) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(version, forKey: .version)
        try container.encode(minimumVersion, forKey: .minimumVersion)
        try container.encode(notices, forKey: .notices)
    }

    // MARK: - Function

    /// 모르는 형식 버전이면 전부 비활성으로 본다 — 형식이 바뀐 파일을 구버전 앱이 잘못
    /// 해석해 엉뚱한 안내를 띄우거나 업데이트를 강제하지 않도록.
    var isSupported: Bool {
        version == Self.supportedVersion
    }

    /// 빈 값이면 업데이트가 필요 없다(fail-open).
    func toMinimumSupportedVersion() -> String? {
        guard isSupported else { return nil }
        let trimmed = minimumVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func toNotices() -> [RemoteNotice] {
        guard isSupported else { return [] }
        return notices.compactMap { $0.toDomain() }
    }
}

// MARK: - RemoteNoticeDTO

/// 화면별 안내 항목.
struct RemoteNoticeDTO: Codable, Sendable {

    // MARK: - Property

    let screen: String
    let enabled: Bool
    let template: String
    let title: String
    let body: String
    let until: String?

    private enum CodingKeys: String, CodingKey {
        case screen
        case enabled
        case template
        case title
        case body
        case until
    }

    // MARK: - Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        screen = try container.decodeIfPresent(String.self, forKey: .screen) ?? ""
        enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled) ?? false
        template = try container.decodeIfPresent(String.self, forKey: .template) ?? ""
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? ""
        body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        until = try container.decodeIfPresent(String.self, forKey: .until)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(screen, forKey: .screen)
        try container.encode(enabled, forKey: .enabled)
        try container.encode(template, forKey: .template)
        try container.encode(title, forKey: .title)
        try container.encode(body, forKey: .body)
        try container.encodeIfPresent(until, forKey: .until)
    }

    // MARK: - Function

    /// 필수 값이 빠진 항목은 버린다. 설정 레포의 스키마 검사를 통과한 파일이면 여기서
    /// 걸러질 일은 없다.
    func toDomain() -> RemoteNotice? {
        guard !screen.isEmpty, !title.isEmpty, !body.isEmpty else { return nil }
        return RemoteNotice(
            screen: screen,
            isEnabled: enabled,
            template: RemoteNoticeTemplate(rawValue: template) ?? .unknown,
            title: title,
            body: body,
            until: until
        )
    }
}
