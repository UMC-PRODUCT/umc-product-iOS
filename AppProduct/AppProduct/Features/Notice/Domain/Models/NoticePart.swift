//
//  NoticePart.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

// MARK: - NoticePart
/// 공지 탭(UI 필터) 전용 파트 타입
enum NoticePart: String, CaseIterable, Identifiable, Equatable, Hashable {
    case web
    case ios
    case android
    case design
    case plan
    case nodejs
    case springboot

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .web:
            return "Web"
        case .ios:
            return "iOS"
        case .android:
            return "Android"
        case .design:
            return "Design"
        case .plan:
            return "Plan"
        case .nodejs:
            return "Node.js"
        case .springboot:
            return "SpringBoot"
        }
    }

    var iconName: String {
        switch self {
        case .web:
            return "globe"
        case .ios:
            return "apple.logo"
        case .android:
            return "inset.filled.applewatch.case"
        case .design:
            return "paintpalette.fill"
        case .plan:
            return "doc.text.fill"
        case .nodejs:
            return "hexagon.fill"
        case .springboot:
            return "leaf.fill"
        }
    }

    var umcPartType: UMCPartType {
        switch self {
        case .web:
            return .front(type: .web)
        case .ios:
            return .front(type: .ios)
        case .android:
            return .front(type: .android)
        case .design:
            return .design
        case .plan:
            return .pm
        case .nodejs:
            return .server(type: .node)
        case .springboot:
            return .server(type: .spring)
        }
    }

    init?(apiValue: String) {
        guard let part = UMCPartType(apiValue: apiValue) else { return nil }
        self.init(umcPartType: part)
    }

    init?(umcPartType: UMCPartType) {
        switch umcPartType {
        case .front(let type):
            switch type {
            case .web:
                self = .web
            case .ios:
                self = .ios
            case .android:
                self = .android
            }
        case .design:
            self = .design
        case .pm:
            self = .plan
        case .server(let type):
            switch type {
            case .node:
                self = .nodejs
            case .spring:
                self = .springboot
            }
        }
    }
}
