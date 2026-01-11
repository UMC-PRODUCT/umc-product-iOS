//
//  ScheduleDatePickerModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/10/26.
//

import SwiftUI

struct ScheduleDatePickerModel: Equatable, Identifiable {
    let id = UUID()
    let type: ScheduleDatePickerType
    let date: Date
}
