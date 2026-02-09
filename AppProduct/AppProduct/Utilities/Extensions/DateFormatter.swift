//
//  DateFormatter.swift
//  AppProduct
//
//  Created by 김미주 on 1/12/26.
//

import Foundation

extension Date {
    /// "yyyy.MM.dd" 형식으로 변환 (예: "2026.01.17")
    func toYearMonthDay() -> String {
        formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
            .replacingOccurrences(of: "/", with: ".")
    }
    
    /// "MM.dd" 형식으로 변환 (예: "01.17")
    func toMonthDay() -> String {
        formatted(.dateTime.month(.twoDigits).day(.twoDigits))
            .replacingOccurrences(of: "/", with: ".")
    }
    
    /// "HH:mm" 24시간제 형식으로 변환 (예: "14:30")
    func toHourMinutes() -> String {
        formatted(.dateTime.hour(
            .twoDigits(amPM: .omitted)).minute(.twoDigits))
    }
    
    var timeAgoText: String {
        let now = Date()
        let interval = now.timeIntervalSince(self)
        
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)
        let days = Int(interval / 86400)
        let weeks = Int(interval / 604800)
        let month = Int(interval / 2592000)
        
        if minutes < 1 {
            return "방금 전"
        } else if minutes < 60 {
            return "\(minutes)분 전"
        } else if hours < 24 {
            return "\(hours)시간 전"
        } else if days < 7 {
            return "\(days)일 전"
        } else if weeks < 4 {
            return "\(weeks)주 전"
        } else {
            return "\(month)개월 전"
        }
    }
    
    /// "HH:mm - HH:mm" 시간 범위 형식 (예: "14:00 - 18:00")
    func timeRange(to endTime: Date) -> String {
        "\(self.toHourMinutes()) - \(endTime.toHourMinutes())"
    }

    /// "yyyy.MM.dd (E)" 형식으로 변환 (예: "24.03.23 (토)")
    func toYearMonthDayWithWeekday() -> String {
        formatted(.dateTime.year(.twoDigits).month(.twoDigits).day(.twoDigits).weekday(.abbreviated))
            .replacingOccurrences(of: "/", with: ".")
    }
}
