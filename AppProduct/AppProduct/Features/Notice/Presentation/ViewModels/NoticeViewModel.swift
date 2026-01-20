//
//  NoticeViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/15/26.
//

import Foundation
import SwiftUI

@Observable
final class NoticeViewModel {
    
    // MARK: - FilterMode
    enum FilterMode: Hashable {
        case generation(Generation)
        case currentOnly
        
        var label: String {
            switch self {
            case .generation(let gen):
                return gen.title
            case .currentOnly:
                return "현재 기수만 보기"
            }
        }
    }
    
    enum SubFilterType: Equatable {
        case all
        case management
        case part(Part)
    }
    
    // MARK: - Properties
    var generations: [Generation] = []
    var currentGeneration: Generation?
    var filterMode: FilterMode = .currentOnly
    
    // 필터 관련
    var selectedNoticeFilter: NoticeFilterType = .all
    var isShowingFilterSheet: Bool = false
    
    // 각 필터별 독립적인 서브 필터 상태
    var coreSubFilter: SubFilterType = .all
    var branchSubFilter: SubFilterType = .all
    var schoolSubFilter: SubFilterType = .all

    // Mock 데이터
    var userSchool: String = "가천대학교"
    var userBranch: String = "Nova"
    var userPart: Part = .ios
    
    // MARK: - Computed Properties
    var currentSubFilter: SubFilterType {
        switch selectedNoticeFilter {
        case .core:
            return coreSubFilter
        case .branch:
            return branchSubFilter
        case .school:
            return schoolSubFilter
        default:
            return .all
        }
    }
    
    // MARK: - Configure
    func configure(generations: [Generation], current: Generation) {
        self.generations = generations
        self.currentGeneration = current
        self.filterMode = .currentOnly
    }
    
    // MARK: - Filter Actions
    func selectFilter(_ filter: NoticeFilterType) {
        selectedNoticeFilter = filter
        
        // 시트가 필요한 필터인 경우에만 시트 표시
        switch filter {
        case .core, .branch, .school:
            isShowingFilterSheet = true
        case .all, .part:
            // 전체와 파트는 바로 필터링만 적용
            break
        }
    }
    
    func selectSubFilter(_ subFilter: SubFilterType) {
        switch selectedNoticeFilter {
        case .core:
            coreSubFilter = subFilter
        case .branch:
            branchSubFilter = subFilter
        case .school:
            schoolSubFilter = subFilter
        default:
            break
        }
    }
    
    var noticeItems: [NoticeItemModel] = [
        .init(tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "2026 UMC 신년회 안내", content: "안녕하세요! 가천대학교 UMC 챌린저 여러분! 회장 웰시입니다!", writer: "웰시/최지은", hasLink: false, hasVote: false, viewCount: 32),
        .init(tag: .central, mustRead: true, isAlert: true, date: Date(), title: "UMC 9기 ✨Demo Day✨ 안내", content: "안녕하세요, UMC 9기 챌린저 여러분! 총괄 챗챗입니다~", writer: "챗챗/전채운", hasLink: false, hasVote: false, viewCount: 123),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5)
    ]
}

    
