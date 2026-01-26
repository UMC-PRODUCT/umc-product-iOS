//
//  ScheduleHeader.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

/// 일정 캘린더의 헤더 뷰
///
/// 현재 표시 중인 연월을 표시하고, 날짜 변경 및 캘린더 보기 모드(리스트/그리드)를 전환할 수 있는 기능을 제공합니다.
struct ScheduleHeader: View {
    
    // MARK: - Properties
    
    /// 현재 표시 중인 월
    @Binding var month: Date
    /// 현재 선택된 날짜
    @Binding var selectedDate: Date
    /// 일정 표시 모드 (그리드/리스트)
    @Binding var scheduleMode: ScheduleMode
    /// 날짜 선택 시트 표시 여부
    @State var showDatePicker: Bool = false
    
    /// 현재 월 문자열 (예: "1", "12")
    private var koreanMonth: String {
        let monthNumber = Calendar.current.component(.month, from: month)
        return "\(monthNumber)"
    }
    
    /// 현재 연도 문자열 (예: "2026")
    private var koreanYear: String {
        let yearNumber = Calendar.current.component(.year, from: month)
        return "\(yearNumber)"
    }
    
    // MARK: - Constants
    
    enum Constants {
        /// 모드 전환 세그먼트 컨트롤 크기
        static let segmentSize: CGFloat = 80
    }
    
    // MARK: - Body
    var body: some View {
        HStack {
            headerTitle
            Spacer()
            headerSwitch
        }
        .sheet(isPresented: $showDatePicker, content: {
            DateSheetPicker(month: $month, selectedDate: $selectedDate)
                .presentationDetents([.height(300)])
                .presentationDragIndicator(.visible)
        })

    }
    
    /// 캘린더 표시 타이틀 버튼
    /// 클릭 시 날짜 선택 시트를 띄웁니다.
    private var headerTitle: some View {
        Button(action: {
            showDatePicker = true
        }, label: {
            Text("\(koreanYear)년 \(koreanMonth)월 일정")
                .font(.body)
                .foregroundStyle(.grey900)
                .fontWeight(.semibold)
                .glass()
        })
        .buttonStyle(.glass)
    }
    
    /// 보기 모드 전환 스위치 (캘린더 / 리스트)
    private var headerSwitch: some View {
        Picker(selection: $scheduleMode, content: {
            // 그리드 뷰 모드
            Image(systemName: "calendar")
                .tag(ScheduleMode.grid)
            // 리스트 뷰 모드
            Image(systemName: "list.bullet")
                .tag(ScheduleMode.horizon)
        }, label: {
            Text("View Mode")
        })
        .pickerStyle(.segmented)
        .labelsHidden()
        .frame(width: Constants.segmentSize)
    }
}

/// 날짜 변경을 위한 시트 뷰 (Date Picker 포함)
fileprivate struct DateSheetPicker: View {
    @Environment(\.dismiss) var dismiss
    @Binding var month: Date
    @Binding var selectedDate: Date
    
    var body: some View {
        VStack(spacing: DefaultSpacing.spacing16, content: {
            title
            datePicker
        })
        .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
    
    private var title: some View {
        HStack(content: {
            Spacer()
            
            Text("날짜 선택")
                .appFont(.bodyEmphasis, color: .grey900)
            
            Spacer()
        })
        .overlay(alignment: .trailing, content: {
            Button(role: .confirm, action: {
                dismiss()
            })
            .buttonStyle(.borderedProminent)
            .tint(.indigo500)
        })
    }
    
    private var datePicker: some View {
        DatePicker("", selection: $selectedDate, displayedComponents: .date)
            .datePickerStyle(.wheel)
            .labelsHidden()
            .onChange(of: selectedDate, { _, new in
                month = new
            })
    }
}
