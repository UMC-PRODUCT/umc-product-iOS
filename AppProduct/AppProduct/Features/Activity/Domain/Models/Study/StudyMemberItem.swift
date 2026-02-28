//
//  StudyMemberItem.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import SwiftUI

/// 스터디 파트
enum StudyPart: String, CaseIterable, Codable, Hashable {
    case ios = "iOS"
    case android = "Android"
    case web = "Web"
    case spring = "Spring"
    case nodejs = "Node.js"
    case design = "Design"
    case pm = "PM"

    /// UMCPartType 변환
    var partType: UMCPartType {
        switch self {
        case .ios:     return .front(type: .ios)
        case .android: return .front(type: .android)
        case .web:     return .front(type: .web)
        case .spring:  return .server(type: .spring)
        case .nodejs:  return .server(type: .node)
        case .design:  return .design
        case .pm:      return .pm
        }
    }

    /// 파트별 고유 색상 (UMCPartType에 위임)
    var color: Color { partType.color }
}

/// 운영진 스터디 출석 관리에서 사용되는 스터디원 모델
///
/// 스터디원의 기본 정보와 출석 상태를 표시합니다.
struct StudyMemberItem: Identifiable, Equatable, Hashable {

    // MARK: - Property

    /// 고유 식별자
    let id: UUID

    /// 서버 식별자
    let serverID: String

    /// 챌린저 워크북 식별자
    let challengerWorkbookId: Int?

    /// 이름
    let name: String

    /// 닉네임
    let nickname: String

    /// 파트
    let part: StudyPart

    /// 대학교
    let university: String

    /// 스터디 주제
    let studyTopic: String

    /// 주차
    let week: Int

    /// 프로필 이미지 URL
    let profileImageURL: String?

    /// 제출 URL
    let submissionURL: String?

    /// 베스트 워크북 선정 여부
    var isBestWorkbook: Bool

    // MARK: - Initializer

    /// 스터디원 모델 초기화
    init(
        id: UUID = UUID(),
        serverID: String,
        challengerWorkbookId: Int? = nil,
        name: String,
        nickname: String,
        part: StudyPart,
        university: String,
        studyTopic: String,
        week: Int = 1,
        profileImageURL: String? = nil,
        submissionURL: String? = nil,
        isBestWorkbook: Bool = false
    ) {
        self.id = id
        self.serverID = serverID
        self.challengerWorkbookId = challengerWorkbookId
        self.name = name
        self.nickname = nickname
        self.part = part
        self.university = university
        self.studyTopic = studyTopic
        self.week = week
        self.profileImageURL = profileImageURL
        self.submissionURL = submissionURL
        self.isBestWorkbook = isBestWorkbook
    }

    // MARK: - Computed Property

    /// 표시용 이름 (이름 + 닉네임)
    var displayName: String {
        "\(nickname)/\(name)"
    }
}
