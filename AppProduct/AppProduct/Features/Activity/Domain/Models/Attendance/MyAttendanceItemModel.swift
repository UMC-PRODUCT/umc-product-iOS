//
//  MyAttendanceItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import Foundation

// MARK: - MyAttendanceItemModel

struct MyAttendanceItemModel: Equatable, Identifiable {
    let id: UUID
    let week: Int
    let title: String
    let startTime: Date
    let endTime: Date
    let status: MyAttendanceItemStatus
    let category: ScheduleIconCategory

    // MARK: - Computed Properties

    /// 주차 표시 텍스트 (예: "1주차")
    var weekText: String {
        "\(week)주차"
    }

    /// 시간 범위 텍스트 (예: "14:00 - 18:00")
    var timeRange: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
    }
}

// MARK: - Session Conversion

extension MyAttendanceItemModel {
    /// Session에서 변환
    /// - Parameters:
    ///   - session: 변환할 세션
    ///   - category: ML 분류 결과 (기본값: .general)
    /// - Note: pending 상태는 nil 반환
    init?(from session: Session, category: ScheduleIconCategory = .general) {
        guard let itemStatus = MyAttendanceItemStatus(from: session.attendanceStatus) else {
            return nil
        }

        self.id = session.info.id
        self.week = session.info.week
        self.title = session.info.title
        self.startTime = session.info.startTime
        self.endTime = session.info.endTime
        self.status = itemStatus
        self.category = category
    }
}

// MARK: - AttendanceHistoryItem Conversion

extension MyAttendanceItemModel {
    /// AttendanceHistoryItem에서 변환
    /// - Note: beforeAttendance 상태는 nil 반환
    init?(from item: AttendanceHistoryItem) {
        guard let itemStatus = MyAttendanceItemStatus(
            from: item.status
        ) else {
            return nil
        }

        self.id = item.id
        self.week = 0
        self.title = item.scheduleName
        self.startTime = Self.parseTimeString(item.startTime)
        self.endTime = Self.parseTimeString(item.endTime)
        self.status = itemStatus
        self.category = .general
    }

    /// "HH:mm:ss" 또는 "HH:mm" → 오늘 Date 변환
    private static func parseTimeString(_ timeString: String) -> Date {
        let calendar = Calendar.current
        let now = Date()
        for format in ["HH:mm:ss", "HH:mm"] {
            let formatter = DateFormatter()
            formatter.dateFormat = format
            formatter.locale = Locale(identifier: "ko_KR")
            if let time = formatter.date(from: timeString) {
                var components = calendar.dateComponents(
                    [.year, .month, .day], from: now
                )
                let timeComponents = calendar.dateComponents(
                    [.hour, .minute, .second], from: time
                )
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                components.second = timeComponents.second
                if let date = calendar.date(from: components) {
                    return date
                }
            }
        }
        return now
    }
}

// MARK: - Preview Support

#if DEBUG
extension MyAttendanceItemModel {
    /// Preview용 직접 생성
    init(
        week: Int,
        title: String,
        startTime: Date,
        endTime: Date,
        status: MyAttendanceItemStatus,
        category: ScheduleIconCategory = .general
    ) {
        self.id = UUID()
        self.week = week
        self.title = title
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.category = category
    }
}
#endif
