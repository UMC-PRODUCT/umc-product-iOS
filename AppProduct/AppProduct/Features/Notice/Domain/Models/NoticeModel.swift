//
//  NoticeModel.swift
//  AppProduct
//
//  Created by 이예지 on 1/14/26.
//

import Foundation

struct Generation: Identifiable, Equatable, Hashable {
    let value: Int
    var id: Int { value }
    var title: String { "\(value)기" }
}

struct Part: Identifiable, Equatable {
    var name: String
    var id: String { name }
    
    static let all = Part(name: "전체")
    static let web = Part(name: "Web")
    static let ios = Part(name: "iOS")
    static let android = Part(name: "Android")
    static let design = Part(name: "Design")
    static let plan = Part(name: "Plan")
    static let nodejs = Part(name: "Node.js")
    static let springboot = Part(name: "SpringBoot")
    
    static let allCases: [Part] = [.all, .web, .ios, .android, .design, .plan, .nodejs, .springboot]
}


enum NoticeFilterType: Identifiable, Equatable {
    case all
    case core
    case branch(String)
    case school(String)
    case part(Part)
    
    var id: String {
        switch self {
        case .all:
            return "all"
        case .core:
            return "core"
        case .branch(let name):
            return "\(name)"
        case .school(let name):
            return "\(name)"
        case .part(let part):
            return "\(part.name)"
        }
    }
    
    var labelText: String {
        switch self {
        case .all:
            return "전체"
        case .core:
            return "중앙운영사무국"
        case .branch(let name):
            return name
        case .school(let name):
            return name
        case .part(let part):
            return part.name
        }
    }
}

