//
//  NoticeViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/15/26.
//

import Foundation
import SwiftUI

/// 공지사항 화면 ViewModel
@Observable
final class NoticeViewModel {

    // MARK: - Nested Types
    /// 서브필터 타입 (ViewModel 내부용)
    enum SubFilterType: Equatable {
        case all
        case management
    }

    // MARK: - Properties
    /// 기수 목록
    var generations: [Generation] = []
    /// 현재 기수
    var currentGeneration: Generation?
    /// 선택된 기수
    var selectedGeneration: Generation?

    /// 메인필터 선택값
    var selectedNoticeMainFilter: NoticeMainFilterType = .all
    /// 서브필터 선택값
    var selectedNoticeSubFilter: NoticeSubFilterType = .all
    /// 파트 선택값
    var selectedPart: Part? = .all
    /// 필터 시트 표시 여부
    var isShowingFilterSheet: Bool = false

    /// 메인필터별 서브필터 상태
    var centralSubFilter: SubFilterType = .all
    var branchSubFilter: SubFilterType = .all
    var schoolSubFilter: SubFilterType = .all

    /// 사용자 정보 (Mock)
    var userSchool: String = "가천대학교"
    var userBranch: String = "Nova"
    var userPart: Part = .ios

    // MARK: - Computed Properties
    /// 현재 메인필터에 해당하는 서브필터 상태
    var currentSubFilter: SubFilterType {
        switch selectedNoticeMainFilter {
        case .central: return centralSubFilter
        case .branch: return branchSubFilter
        case .school: return schoolSubFilter
        default: return .all
        }
    }

    // MARK: - Methods
    /// 초기 설정
    func configure(generations: [Generation], current: Generation) {
        self.generations = generations
        self.currentGeneration = current
        self.selectedGeneration = current
    }

    /// 메인필터 선택
    func selectMainFilter(_ filter: NoticeMainFilterType) {
        selectedNoticeMainFilter = filter
        switch filter {
        case .central, .branch, .school:
            isShowingFilterSheet = true
        case .all, .part:
            break
        }
    }

    /// 서브필터 선택
    func selectSubFilter(_ subFilter: SubFilterType) {
        switch selectedNoticeMainFilter {
        case .central: centralSubFilter = subFilter
        case .branch: branchSubFilter = subFilter
        case .school: schoolSubFilter = subFilter
        default: break
        }
    }

    // MARK: - Mock Data
    var noticeItems: [NoticeItemModel] = [
        .init(tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "2026 UMC 신년회 안내", content: "안녕하세요! 가천대학교 UMC 챌린저 여러분! 회장 웰시입니다!", writer: "웰시/최지은", hasLink: false, hasVote: false, viewCount: 32),
        .init(tag: .central, mustRead: true, isAlert: true, date: Date(), title: "UMC 9기 ✨Demo Day✨ 안내", content: "안녕하세요, UMC 9기 챌린저 여러분! 총괄 챗챗입니다~", writer: "챗챗/전채운", hasLink: false, hasVote: false, viewCount: 123),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        .init(tag: .part, mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5)
    ]
}

    
