//
//  HomeScheduleItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

struct HomeScheduleItemModel: Equatable, Identifiable {
    let id = UUID()
    let date: Date
    let title: String
    let type: String

    var isDone: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let date = calendar.startOfDay(for: date)
        return date < today
    }
}
