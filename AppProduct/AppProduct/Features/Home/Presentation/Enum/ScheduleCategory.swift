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
        case .general:      return "calendar.badge"
        }
    }

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
}
