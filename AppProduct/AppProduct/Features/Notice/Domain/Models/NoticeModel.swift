//
//  NoticeModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/14/26.
//

import Foundation
import SwiftUI

// MARK: - Generation
/// 기수 모델
struct Generation: Identifiable, Equatable, Hashable {
    let value: Int
    var id: Int { value }
    var title: String { "\(value)기" }
}

// MARK: - Part
/// 파트 모델
struct Part: Identifiable, Equatable, Hashable {
    var name: String
    var id: String { name }

    static let all = Part(name: "파트")
    static let web = Part(name: "Web")
    static let ios = Part(name: "iOS")
    static let android = Part(name: "Android")
    static let design = Part(name: "Design")
    static let plan = Part(name: "Plan")
    static let nodejs = Part(name: "Node.js")
    static let springboot = Part(name: "SpringBoot")

    static let allCases: [Part] = [.all, .web, .ios, .android, .design, .plan, .nodejs, .springboot]
}

// MARK: - NoticeSubFilterType
/// 서브필터 타입 (전체, 운영진 공지, 파트)
enum NoticeSubFilterType: Identifiable, Equatable, Hashable {
    case all          // 전체
    case management   // 운영진 공지
    case part         // 파트

    var id: String {
        switch self {
        case .all: return "all"
        case .management: return "management"
        case .part: return "part"
        }
    }

    var labelText: String {
        switch self {
        case .all: return "전체"
        case .management: return "운영진 공지"
        case .part: return "파트"
        }
    }
}

// MARK: - NoticeMainFilterType
/// 메인필터 타입 (전체, 중앙, 지부, 학교, 파트)
enum NoticeMainFilterType: Identifiable, Equatable, Hashable {
    case all              // 전체
    case central          // 중앙운영사무국
    case branch(String)   // 지부
    case school(String)   // 학교
    case part(Part)       // 파트

    var id: String {
        switch self {
        case .all: return "all"
        case .central: return "central"
        case .branch(let name): return "\(name)"
        case .school(let name): return "\(name)"
        case .part(let part): return "\(part.name)"
        }
    }

    /// 필터 라벨 텍스트
    var labelText: String {
        switch self {
        case .all: return "전체"
        case .central: return "중앙운영사무국"
        case .branch(let name): return name
        case .school(let name): return name
        case .part(let part): return part.name
        }
    }

    /// 필터 아이콘 (SF Symbol)
    var labelIcon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .central: return "building.columns"
        case .branch: return "mappin.and.ellipse"
        case .school: return "graduationcap"
        case .part: return "person.3.fill"
        }
    }
}

