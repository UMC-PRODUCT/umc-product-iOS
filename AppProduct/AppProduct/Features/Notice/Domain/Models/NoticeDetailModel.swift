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
