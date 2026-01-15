//
//  Date+Calendar.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import Foundation

extension Date {
    func weekDaySymbols(style: DateFormatter.Style = .short) -> [String] {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        switch style {
        case .none:
            return formatter.veryShortWeekdaySymbols
        case .short:
            return formatter.shortWeekdaySymbols
        case .medium:
            return formatter.shortWeekdaySymbols
        case .long:
            return formatter.weekdaySymbols
        case .full:
            return formatter.weekdaySymbols
        @unknown default:
            return formatter.shortWeekdaySymbols
        }
    }
    
    var startOfMonth: Date {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: self) else {
            return self
        }
        return interval.start
    }
    
    var endOfMont: Date {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: self) else {
            return self
        }
        return interval.end
    }
    
    func datesInMont() -> [Date] {
        let calendar = Calendar.current
        let startOfMonth = self.startOfMonth
        
        guard let range = calendar.range(of: .day, in: .month, for: startOfMonth) else {
            return []
        }
        
        return range.compactMap { day in 
            calendar.date(byAdding: .day, value: day - 1, to: startOfMonth)
        }
    }
    
    func isSameDay(_ date: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: date)
    }
}
