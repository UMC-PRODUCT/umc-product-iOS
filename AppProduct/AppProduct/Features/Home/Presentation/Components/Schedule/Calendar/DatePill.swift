//
//  DatePill.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 가로 스크롤 가능한 캘린더에서 사용되는 날짜 캡슐(Pill) 뷰
///
/// 요일, 일, 일정 유무를 세로 형태의 캡슐 모양으로 표시합니다.
struct DatePill: View {

    // MARK: - Properties
    /// 표시할 날짜
    let date: Date
    /// 선택 여부
    let isSelected: Bool
    /// 해당 날짜에 일정이 있는지 여부
    let hasSchedule: Bool
    /// 오늘 날짜인지 여부
    let isToday: Bool
    
    /// 날짜 탭 시 실행될 액션
    let action: () -> Void
    
    /// 요일 문자열 반환 (예: "MON", "TUE")
    private var weekDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    /// 일 문자열 반환 (예: "1", "15")
    private var day: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }
    
    // MARK: - Constants
    
    enum Constants {
        /// 일정 표시 점 크기
        static let circleSize: CGFloat = 6
        /// 셀 전체 크기
        static let mainSize: CGSize = .init(width: 80, height: 140)
        /// 오늘 날짜 테두리 두께
        static let todayBorderWidth: CGFloat = 2
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: {
            action()
        }, label: {
            VStack(spacing: DefaultSpacing.spacing16, content: {
                // 요일 표시
                Text(weekDay)
                    .appFont(.calloutEmphasis, color: isSelected ? .grey000 : .grey600)
                
                VStack(spacing: DefaultSpacing.spacing8, content: {
                    // 날짜(일) 표시
                    Text(day)
                        .appFont(.body, weight: .medium, color: isSelected ? .white : .grey600)
                    
                    // 일정 유무 표시 점
                    Circle()
                        .fill(hasSchedule ? (isSelected ? .white : .indigo500) : .clear)
                        .frame(width: Constants.circleSize)
                })
            })
            .frame(width: Constants.mainSize.width, height: Constants.mainSize.height)
            .background {
                // 배경 캡슐 (선택 시 색상 변경)
                Capsule()
                    .fill(isSelected ? .indigo500 : .grey000)
                    .glassEffect(.regular.interactive())
            }
        })
        .overlay {
            // 오늘 날짜이고 선택되지 않았을 때 테두리 표시
            if isToday && !isSelected {
                Capsule()
                    .stroke(Color.indigo500, lineWidth: Constants.todayBorderWidth)
            }
        }
    }
}
