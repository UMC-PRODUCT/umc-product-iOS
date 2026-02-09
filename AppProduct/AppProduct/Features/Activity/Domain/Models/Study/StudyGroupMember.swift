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

    /// 이름
    let name: String

    /// 대학교
    let university: String

    /// 프로필 이미지 URL
    let profileImageURL: String?

    /// 역할
    let role: MemberRole

    // MARK: - Initializer

    init(
        serverID: String,
        name: String,
        university: String,
        profileImageURL: String? = nil,
        role: MemberRole = .member
    ) {
        self.serverID = serverID
        self.name = name
        self.university = university
        self.profileImageURL = profileImageURL
        self.role = role
    }
}
