//
//  Session.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/5/26.
//

import Foundation

struct Session: Identifiable {
    let id: UUID
    let icon: String
    let title: String
    let week: Int
    let startTime: Date
    let endTime: Date
    let location: Coordinate
}
