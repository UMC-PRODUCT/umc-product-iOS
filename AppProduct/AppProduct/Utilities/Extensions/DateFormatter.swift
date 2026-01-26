//
//  DateFormatter.swift
//  AppProduct
//
//  Created by 김미주 on 1/12/26.
//

import Foundation

extension Date {
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
    
    func timeFormatter() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: self)
    }
}
