//
//  UMCPartType.swift
//  AppProduct
//
//  Created by euijjang97 on 1/24/26.
//

import Foundation

enum UMCPartType: Equatable, Hashable {
    case pm
    case design
    case server(type: ServerType)
    case front(type: FrontType)
    
    var name: String {
        switch self {
        case .pm:
            return "PM"
        case .design:
            return "Design"
        case .server(let type):
            return type.rawValue
        case .front(let type):
            return type.rawValue
        }
    }
    
    enum ServerType: String, Equatable, Hashable {
        case spring = "Spring"
        case node = "NodeJS"
    }
    
    enum FrontType: String, Equatable, Hashable {
        case web = "Web"
        case android = "Android"
        case ios = "iOS"
    }
}
