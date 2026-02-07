//
//  StudyMemberItem.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import Foundation

/// 운영진 스터디 출석 관리에서 사용되는 스터디원 모델
///
/// 스터디원의 기본 정보와 출석 상태를 표시합니다.
struct StudyMemberItem: Identifiable, Equatable, Hashable {

    // MARK: - Property

    /// 고유 식별자
    let id: UUID

    /// 서버 식별자
    let serverID: String

    /// 이름
    let name: String

    /// 닉네임
    let nickname: String

    /// 파트 (iOS, Android, Web 등)
    let part: String

    /// 대학교
    let university: String

    /// 스터디 주제
    let studyTopic: String

    /// 프로필 이미지 URL
    let profileImageURL: String?

    // MARK: - Initializer

    init(
        id: UUID = UUID(),
        serverID: String,
        name: String,
        nickname: String,
        part: String,
        university: String,
        studyTopic: String,
        profileImageURL: String? = nil
    ) {
        self.id = id
        self.serverID = serverID
        self.name = name
        self.nickname = nickname
        self.part = part
        self.university = university
        self.studyTopic = studyTopic
        self.profileImageURL = profileImageURL
    }

    // MARK: - Computed Property

    /// 표시용 이름 (이름 + 닉네임)
    var displayName: String {
        "\(nickname)/\(name)"
    }
}
