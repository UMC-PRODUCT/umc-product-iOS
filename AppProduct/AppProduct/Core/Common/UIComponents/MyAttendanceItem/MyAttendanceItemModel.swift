//
//  MyAttendanceItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

struct MyAttendanceItemModel: Equatable, Identifiable {
    let id = UUID()
    let week: String
    let title: String
    let date: Date
    let status: MyAttendanceItemStatus
}
