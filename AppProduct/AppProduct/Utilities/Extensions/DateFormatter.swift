//
//  DateFormatter.swift
//  AppProduct
//
//  Created by 김미주 on 1/12/26.
//

import Foundation

extension Date {
    // yyyy.MM.dd
    func toYearMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: self)
    }

    func toMonthDay() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM.dd"
        return formatter.string(from: self)
    }
}
