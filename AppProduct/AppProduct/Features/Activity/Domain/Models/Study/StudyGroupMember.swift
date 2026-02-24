//
//  StudyGroupMember.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/9/26.
//

import Foundation

/// 스터디 그룹 내 멤버 모델
///
/// 스터디 그룹의 리더/멤버 정보를 표현합니다.
struct StudyGroupMember: Identifiable, Equatable, Hashable {

    // MARK: - Nested Types

    /// 멤버 역할
    enum MemberRole: String, Equatable, Hashable {
        case leader = "Leader"
        case member = "Member"
    }

    // MARK: - Property

    /// 고유 식별자
    let id: UUID = .init()

    /// 서버 식별자
    let serverID: String

    /// 챌린저 식별자
    let challengerID: Int?

    /// 멤버 식별자
    let memberID: Int?

    /// 이름
    let name: String

    /// 닉네임
    let nickname: String?

    /// 대학교
    let university: String

    /// 프로필 이미지 URL
    let profileImageURL: String?

    /// 역할
    let role: MemberRole

    /// 베스트 워크북 포인트
    let bestWorkbookPoint: Int

    // MARK: - Computed Property

    /// 표시용 이름 (닉네임/이름 또는 이름만)
    var displayName: String {
        if let nickname { return "\(nickname)/\(name)" }
        return name
    }

    // MARK: - Initializer

    init(
        serverID: String,
        challengerID: Int? = nil,
        memberID: Int? = nil,
        name: String,
        nickname: String? = nil,
        university: String,
        profileImageURL: String? = nil,
        role: MemberRole = .member,
        bestWorkbookPoint: Int = 0
    ) {
        self.serverID = serverID
        self.challengerID = challengerID
        self.memberID = memberID
        self.name = name
        self.nickname = nickname
        self.university = university
        self.profileImageURL = profileImageURL
        self.role = role
        self.bestWorkbookPoint = bestWorkbookPoint
    }
}
