//
//  DatePill.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 가로 스크롤 리스트 캘린더 헝
struct DatePill: View {
    
    @Environment(\.colorScheme) var color

    let date: Date
    let isSelected: Bool
    let hasSchedule: Bool
    
    private var weekDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    enum Constants {
        static let circleSize: CGFloat = 6
        static let mainSize: CGSize = .init(width: 80, height: 140)
    }
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing16, content: {
            Text(weekDay)
                .appFont(.caption1Emphasis, color: fontSelectedColor)
            
            VStack(spacing: DefaultSpacing.spacing8, content: {
                Text(day)
                    .appFont(.title2Emphasis, color: isSelected ? .white : .grey600)
                
                Circle()
                    .fill(hasSchedule ? (isSelected ? .white : .indigo500) : .clear)
                    .frame(width: Constants.circleSize)
            })
        })
        .frame(width: Constants.mainSize.width, height: Constants.mainSize.height)
        .glassEffect(.regular.interactive().tint(isSelected ? .indigo500 : .clear), in: .capsule)
    }
    
    private var fontSelectedColor: Color {
        if color == .dark {
            return .white
        } else {
            return isSelected ? .grey000 : .grey600
        }
    }
}

#Preview {
    HStack {
        DatePill(date: .now, isSelected: true, hasSchedule: true)
        DatePill(date: .now, isSelected: false, hasSchedule: true)
    }
}
