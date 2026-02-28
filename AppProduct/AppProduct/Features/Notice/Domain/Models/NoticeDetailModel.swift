//
//  NoticeDetailModel.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import Foundation
import SwiftUI

// MARK: - NoticeDetail

/// 공지사항 상세정보 엔티티
struct NoticeDetail: Equatable, Identifiable, Hashable {
    /// 공지 고유 ID
    let id: String
    /// 기수
    let generation: Int
    /// 공지 범위 (중앙/지부/교내)
    let scope: NoticeScope
    /// 공지 카테고리
    let category: NoticeCategory

    /// 필독 여부
    let isMustRead: Bool

    /// 공지 제목
    let title: String
    /// 공지 본문
    let content: String

    /// 작성자 ID
    let authorID: String
    /// 작성자 멤버 ID (authorMemberId)
    let authorMemberId: String?
    /// 작성자 이름
    let authorName: String
    /// 작성자 프로필 이미지 URL
    let authorImageURL: String?

    /// 생성일
    let createdAt: Date
    /// 수정일
    let updatedAt: Date?

    /// 수신 대상
    let targetAudience: TargetAudience

    /// 수정/삭제 권한 보유 여부
    let hasPermission: Bool

    /// 첨부 이미지 URL 목록
    let images: [String]
    /// 첨부 이미지 원본 메타데이터 (수정 화면의 교체 API 구성에 사용)
    var imageItems: [NoticeAttachmentImage] = []
    /// 첨부 링크 목록
    let links: [String]
    /// 첨부 투표
    let vote: NoticeVote?

    /// 작성자 표기 기본값 (닉네임/이름-기수TH UMC 직책)
    var defaultAuthorDisplayName: String { authorName }

    /// NoticeChip에 표시할 공지 타입
    var noticeType: NoticeType {
        // 파트 공지인 경우
        if case .part = category {
            return .part
        }
        
        // scope에 따라 구분
        switch scope {
        case .central:
            return .core
        case .branch:
            return .branch
        case .campus:
            return .campus
        }
    }

    init(
        id: String,
        generation: Int,
        scope: NoticeScope,
        category: NoticeCategory,
        isMustRead: Bool,
        title: String,
        content: String,
        authorID: String,
        authorMemberId: String? = nil,
        authorName: String,
        authorImageURL: String?,
        createdAt: Date,
        updatedAt: Date?,
        targetAudience: TargetAudience,
        hasPermission: Bool,
        images: [String],
        imageItems: [NoticeAttachmentImage] = [],
        links: [String],
        vote: NoticeVote?
    ) {
        self.id = id
        self.generation = generation
        self.scope = scope
        self.category = category
        self.isMustRead = isMustRead
        self.title = title
        self.content = content
        self.authorID = authorID
        self.authorMemberId = authorMemberId
        self.authorName = authorName
        self.authorImageURL = authorImageURL
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.targetAudience = targetAudience
        self.hasPermission = hasPermission
        self.images = images
        self.imageItems = imageItems
        self.links = links
        self.vote = vote
    }
}

/// 공지 첨부 이미지 메타데이터
struct NoticeAttachmentImage: Equatable, Hashable, Identifiable {
    let id: String
    let url: String
}


// MARK: - TargetAudience
                                                                                                                                              
 /// 공지 수신 대상
struct TargetAudience: Equatable, Hashable {
    let generation: Int
    let scope: NoticeScope
    let parts: [UMCPartType]
    let branches: [String]
    let schools: [String]
    
    /// 수신 대상 표시 텍스트 (예: "12기 / 전체")
    var displayText: String {
        var components: [String] = ["\(generation)기"]
        
        switch scope {
        case .central:
            if parts.isEmpty {
                components.append("전체")
            } else {
                components.append(
                    parts.map { NoticePart(umcPartType: $0)?.displayName ?? $0.name }
                        .joined(separator: ", ")
                )
            }
        case .branch:
            if branches.isEmpty {
                components.append("전체 지부")
            } else {
                components.append(branches.joined(separator: ", "))
            }
        case .campus:
            if schools.isEmpty {
                components.append("전체")
            } else {
                components.append(schools.joined(separator: ", "))
            }
        }
        
        return components.joined(separator: " / ")
    }
}

extension TargetAudience {
    /// 전체 대상 (기본값)
    static func all(generation: Int, scope: NoticeScope) -> TargetAudience {
        TargetAudience(
            generation: generation,
            scope: scope,
            parts: [],
            branches: [],
            schools: []
        )
    }
}


// MARK: - ImageViewerItem
/// fullScreenCover에서 Identifiable 사용을 위한 래퍼
struct ImageViewerItem: Identifiable {
    let id = UUID()
    let index: Int
}


// MARK: - NoticeVote

/// 공지사항 투표
struct NoticeVote: Equatable, Identifiable, Hashable {
    let id: String
    let question: String
    let options: [VoteOption]
    let startDate: Date
    let endDate: Date
    /// 복수 선택 허용 여부
    let allowMultipleChoices: Bool
    /// 익명 투표 여부
    let isAnonymous: Bool
    /// 현재 사용자가 투표한 옵션 ID 목록
    let userVotedOptionIds: [String]
    
    /// 전체 투표 수
    var totalVotes: Int {
        options.reduce(0) { $0 + $1.voteCount }
    }
    
    /// 투표 종료 여부
    var isEnded: Bool {
        Date() > endDate
    }
    
    /// 투표 상태
    var status: VoteStatus {
        isEnded ? .ended : .active
    }
    
    /// 사용자 투표 여부
    var hasUserVoted: Bool {
        !userVotedOptionIds.isEmpty
    }
    
    /// 날짜 포맷 (MM.dd - MM.dd)
    var formattedPeriod: String {
        startDate.dateRange(to: endDate)
    }
}

/// 투표 옵션
struct VoteOption: Equatable, Identifiable, Hashable {
    let id: String
    let title: String
    let voteCount: Int

    /// 투표율 계산
    func percentage(totalVotes: Int) -> Double {
        guard totalVotes > 0 else { return 0 }
        return Double(voteCount) / Double(totalVotes) * 100
    }
}

/// 투표 상태
enum VoteStatus {
    case active  // 진행 중
    case ended   // 종료
}


// MARK: - ReadStatusTab

/// 공지 열람 현황 탭 (확인/미확인)
enum ReadStatusTab: String, CaseIterable {
    case confirmed = "확인"
    case unconfirmed = "미확인"
}

// MARK: - NoticeReadStatus

/// 공지 열람 현황 전체 데이터
struct NoticeReadStatus: Equatable {
    let noticeId: String
    let confirmedUsers: [ReadStatusUser]
    let unconfirmedUsers: [ReadStatusUser]
    
    /// 확인한 사람 수
    var confirmedCount: Int {
        confirmedUsers.count
    }
    
    /// 미확인한 사람 수
    var unconfirmedCount: Int {
        unconfirmedUsers.count
    }
    
    /// 전체 대상자 수
    var totalCount: Int {
        confirmedCount + unconfirmedCount
    }
    
    /// 하단 메시지 (예: "이미 3명이 공지를 확인했습니다.")
    var bottomMessage: String {
        "이미 \(confirmedCount)명이 공지를 확인했습니다."
    }
}


// MARK: - ReadStatusUser

/// 공지 열람 현황 - 사용자 정보
struct ReadStatusUser: Equatable, Identifiable {
    let id: String
    let name: String
    let nickName: String
    let part: String
    let branch: String
    let campus: String
    let profileImageURL: String?
    let isRead: Bool
    
    /// NoticeReadStatusItemModel로 변환
    func toItemModel() -> NoticeReadStatusItemModel {
        NoticeReadStatusItemModel(
            profileImage: nil,
            userName: name,
            nickName: nickName,
            part: part,
            location: branch,
            campus: campus,
            isRead: isRead
        )
    }
}

// MARK: - ReadStatusFilterType

/// 공지 열람 현황 필터 타입
enum ReadStatusFilterType: String, CaseIterable, Identifiable {
    case all = "전체 보기"
    case branch = "지부별 보기"
    case school = "학교별 보기"
    
    var id: String { rawValue }

    /// 열람 현황 필터 메뉴 아이콘
    var iconName: String {
        switch self {
        case .all:
            return "line.3.horizontal.decrease"
        case .branch:
            return "mappin.and.ellipse"
        case .school:
            return "graduationcap"
        }
    }
}
