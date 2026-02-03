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
struct NoticeDetail: Equatable, Identifiable {
    // 기본 정보
    let id: String
    let generation: Int
    let scope: NoticeScope
    let category: NoticeCategory
    
    // 태그
    let isMustRead: Bool
    
    // 내용
    let title: String
    let content: String
    
    // 작성자
    let authorID: String
    let authorName: String
    let authorImageURL: String?
    
    // 날짜
    let createdAt: Date
    let updatedAt: Date?
    
    // 수신 대상
    let targetAudience: TargetAudience
    
    // 권한
    let hasPermission: Bool
    
    // 추가 콘텐츠
    let images: [String]
    let links: [String]
    let vote: NoticeVote?

    
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
}


// MARK: - TargetAudience
                                                                                                                                              
 /// 공지 수신 대상
struct TargetAudience: Equatable {
    let generation: Int
    let scope: NoticeScope
    let parts: [Part]
    let branches: [String]
    let schools: [String]
    
    // 수신 대상 표시 텍스트
    var displayText: String {
        var components: [String] = ["\(generation)기"]
        
        switch scope {
        case .central:
            if parts.isEmpty {
                components.append("전체")
            } else {
                components.append(parts.map { $0.name }.joined(separator: ", "))
            }
        case .branch:
            if branches.isEmpty {
                components.append("전체 지부")
            } else {
                components.append(branches.joined(separator: ", "))
            }
        case .campus:
            if schools.isEmpty {
                components.append("전체 학교")
            } else {
                components.append(schools.joined(separator: ", "))
            }
        }
        
        return components.joined(separator: " / ")
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
struct NoticeVote: Equatable, Identifiable {
    let id: String
    let question: String
    let options: [VoteOption]
    let startDate: Date
    let endDate: Date
    // 단일/복수 선택
    let allowMultipleChoices: Bool
    // 익명/실명
    let isAnonymous: Bool
    // 사용자가 투표한 옵션 ID들
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
struct VoteOption: Equatable, Identifiable {
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
