//
//  ScheduleData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation

struct ScheduleData: Equatable, Identifiable {
    var id: UUID = .init()
    let title: String
    let subTitle: String
}
