//
//  ScheduleCategory.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import SwiftUI
import FoundationModels

/// 일정 카테고리 아이콘 타입
///
/// 일정의 종류(스터디, 회의, 해커톤 등)를 정의하고,
/// 각 종류에 따른 심볼 아이콘, 테마 색상, 한글 명칭을 제공합니다.
enum ScheduleIconCategory: String, CaseIterable {
    /// 리더십 관련 활동
    case leadership
    /// 스터디 활동
    case study
    /// 회비 관련
    case fee
    /// 회의 (운영진 회의 등)
    case meeting
    /// 네트워킹 행사
    case networking
    /// 해커톤 행사
    case hackathon
    /// 프로젝트 활동
    case project
    /// 발표 관련 (데모데이 등)
    case presentation
    /// 워크샵 행사
    case workshop
    /// 회고 활동
    case review
    /// 축하/기념 행사
    case celebration
    /// 오리엔테이션 (OT)
    case orientation
    /// 일반 일정
    case general
    
    /// 카테고리별 시스템 심볼 이미지 이름
    var symbol: String {
        switch self {
        case .leadership:   return "person.3.sequence.fill"
        case .study:        return "book.closed.fill"
        case .fee:          return "wonsign.circle.fill"
        case .meeting:      return "person.2.fill"
        case .networking:   return "bubble.left.and.bubble.right.fill"
        case .hackathon:    return "laptopcomputer"
        case .project:      return "hammer.fill"
        case .presentation: return "mic.fill"
        case .workshop:     return "tent.fill"
        case .review:       return "lightbulb.fill"
        case .celebration:  return "sparkles"
        case .orientation:  return "megaphone.fill"
        case .general:      return "calendar.badge"
        }
    }
    
    /// 카테고리별 테마 색상
    var color: Color {
        switch self {
        case .leadership:   return .indigo
        case .study:        return .blue
        case .fee:          return .green
        case .meeting:      return .cyan
        case .networking:   return .teal
        case .hackathon:    return .purple
        case .project:      return .orange
        case .presentation: return .red
        case .workshop:     return .mint
        case .review:       return .yellow
        case .celebration:  return .accentColor
        case .orientation:  return .orange
        case .general:      return .indigo500
        }
    }
    
    /// 카테고리별 한글 명칭
    var korean: String {
        switch self {
        case .leadership:   return "리더십"
        case .study:        return "스터디"
        case .fee:          return "회비"
        case .meeting:      return "회의"
        case .networking:   return "네트워킹"
        case .hackathon:    return "해커톤"
        case .project:      return "프로젝트"
        case .presentation: return "발표"
        case .workshop:     return "워크샵"
        case .review:       return "회고"
        case .celebration:  return "축하"
        case .orientation:  return "오리엔테이션"
        case .general:      return "일반"
        }
    }
}
