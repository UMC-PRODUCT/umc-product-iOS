//
//  ThreadMemberProfile.swift
//  CommunityDomain
//
//  Created by euijjang97 on 11/19/26.
//

import CoreDomain
import UMCFoundation

/// 스레드에서 보는 다른 회원의 프로필 (#1681).
///
/// 이름·학교·사진은 마이페이지와 같은 규칙으로 가장 최근 활동 기록의 값을 먼저 쓴다.
/// 이메일은 없다 — 서버가 연락용 이메일을 주지 않아 화면은 늘 비공개로 보인다.
public struct ThreadMemberProfile: Equatable, Sendable {

    // MARK: - Property

    public let memberId: String
    public let name: String
    public let nickname: String
    public let schoolName: String
    /// 최근 기수(`"12"`). 활동 기록·역할이 없으면 빈 문자열.
    public let generation: String
    /// 최근 파트. 파트가 없는 운영진이거나 못 읽으면 `nil`.
    public let part: UMCPartType?
    public let profileImageURL: String?
    public let activityLogs: [ActivityLog]
    /// GitHub → LinkedIn → Blog → Instagram → 개인 사이트 순. 값이 없으면 비공개로 보인다.
    public let links: [Link]

    // MARK: - Init

    public init(
        memberId: String,
        name: String,
        nickname: String,
        schoolName: String,
        generation: String,
        part: UMCPartType?,
        profileImageURL: String?,
        activityLogs: [ActivityLog],
        links: [Link]
    ) {
        self.memberId = memberId
        self.name = name
        self.nickname = nickname
        self.schoolName = schoolName
        self.generation = generation
        self.part = part
        self.profileImageURL = profileImageURL
        self.activityLogs = activityLogs
        self.links = links
    }
}

// MARK: - Link

extension ThreadMemberProfile {

    /// 외부 링크 한 줄. 서버는 입력하지 않은 링크와 비공개 링크를 똑같이 `null` 로 줘서
    /// 둘을 구분하지 않는다.
    public struct Link: Equatable, Hashable, Sendable {
        public let kind: Kind
        /// 공개된 주소. 없거나 비공개면 `nil`.
        public let value: String?

        public init(kind: Kind, value: String?) {
            self.kind = kind
            self.value = value
        }
    }

    public enum Kind: CaseIterable, Hashable, Sendable {
        case github
        case linkedIn
        case blog
        case instagram
        case personal
    }
}

// MARK: - Mapping

extension ThreadMemberProfile {

    /// MEMBER-101 응답으로 만든 정본 프로필에서 화면 값을 고른다.
    public init(profile: Profile) {
        let visibleRecords = profile.challengerRecords.filter {
            UMCPartType(apiValue: $0.part) != .admin
        }
        let latestRecord = visibleRecords.max { $0.gisu.intValue < $1.gisu.intValue }
            ?? profile.challengerRecords.max { $0.gisu.intValue < $1.gisu.intValue }
        let latestRole = profile.roles.max { $0.gisu.intValue < $1.gisu.intValue }
        let recordPart = latestRecord.flatMap { UMCPartType(apiValue: $0.part) }
        let rolePart = latestRole?.responsiblePart.flatMap { UMCPartType(apiValue: $0) }
        let links = profile.externalLinks

        self.init(
            memberId: profile.memberId,
            name: latestRecord?.name?.nonEmpty ?? profile.name,
            nickname: latestRecord?.nickname?.nonEmpty ?? profile.nickname,
            schoolName: latestRecord?.schoolName.nonEmpty ?? profile.schoolName,
            generation: latestRecord?.gisu ?? latestRole?.gisu ?? "",
            part: [recordPart, rolePart].compactMap { $0 }.first { $0 != .admin },
            profileImageURL: latestRecord?.profileImageLink?.nonEmpty
                ?? profile.profileImageLink?.nonEmpty,
            activityLogs: profile.activityLogs(),
            links: [
                Link(kind: .github, value: links?.github?.nonEmpty),
                Link(kind: .linkedIn, value: links?.linkedIn?.nonEmpty),
                Link(kind: .blog, value: links?.blog?.nonEmpty),
                Link(kind: .instagram, value: links?.instagram?.nonEmpty),
                Link(kind: .personal, value: links?.personal?.nonEmpty)
            ]
        )
    }
}

private extension String {
    var intValue: Int { Int(self) ?? 0 }
    var nonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
