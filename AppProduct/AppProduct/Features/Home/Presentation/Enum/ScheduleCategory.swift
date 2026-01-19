//
//  ScheduleCategory.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import SwiftUI
import FoundationModels

@Generable
enum ScheduleIconCategory: String, CaseIterable {
    case leadership
    case study
    case fee
    case meeting
    case networking
    case hackathon
    case project
    case presentation
    case workshop
    case review
    case celebration
    case orientation
    case general

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
        case .general:      return "calendar"
        }
    }

    var color: Color {
        switch self {
        case .leadership:   return .indigo          // 리더십 - 신뢰/권위
        case .study:        return .blue            // 학습 - 지식/차분
        case .fee:          return .green           // 회비 - 돈/성공
        case .meeting:      return .cyan            // 회의 - 소통/협업
        case .networking:   return .teal            // 네트워킹 - 연결/교류
        case .hackathon:    return .purple          // 해커톤 - 창의/개발
        case .project:      return .orange          // 프로젝트 - 빌드/에너지
        case .presentation: return .red             // 발표 - 열정/주목
        case .workshop:     return .mint            // 워크샵 - 자연/휴식
        case .review:       return .yellow          // 회고 - 아이디어/인사이트
        case .celebration:  return .accentColor         // 축하 - 기쁨/파티
        case .orientation:  return .orange          // 오리엔테이션 - 환영/시작
        case .general:      return .grey000            // 기본 - 중립
        }
    }
}
