//
//  DateCell.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// Grid 용 셀
struct DateCell: View {
    let date: Date
    let isSelected: Bool
    let isCurrentMonth: Bool
    let hasSchedule: Bool
    let isToday: Bool

    enum Constants {
        static let cellSize: CGFloat = 40
        static let circleSize: CGFloat = 6
        static let todayBorderWidth: CGFloat = 2
    }
    
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing4, content: {
            Text(day)
                .appFont(.callout, color: textColor)
                .frame(maxWidth: .infinity)
                .frame(height: Constants.cellSize)
                .padding(Constants.todayBorderWidth)
                .background {
                    if isSelected {
                        Color.indigo500.glassEffect(.regular.interactive(), in: .circle)
                    } else {
                        Color.clear
                    }
                }
                .clipShape(Circle())
                .overlay {
                    if isToday && !isSelected {
                        Circle()
                            .strokeBorder(Color.indigo500, lineWidth: Constants.todayBorderWidth)
                    }
                }

            Circle()
                .fill(hasSchedule ? pointColor : .clear)
                .frame(width: Constants.circleSize, height: Constants.circleSize)
        })
        .opacity(isCurrentMonth ? 1.0 : 0.3)
    }
    
    private var textColor: Color {
        isSelected ? .white : .grey900
    }
    
    private var backgroundColor: Color {
        isSelected ? .indigo500 : .clear
    }
    
    private var pointColor: Color {
        isSelected ? .white : .red500
    }
}

#Preview {
    HStack {
        DateCell(date: .now, isSelected: true, isCurrentMonth: true, hasSchedule: false, isToday: true)
        DateCell(date: .now, isSelected: false, isCurrentMonth: true, hasSchedule: false, isToday: true)
        DateCell(date: .now, isSelected: false, isCurrentMonth: true, hasSchedule: true, isToday: false)
    }
}
