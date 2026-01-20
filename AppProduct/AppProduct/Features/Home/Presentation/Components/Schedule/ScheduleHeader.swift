//
//  ScheduleHeader.swift
//  AppProduct
//
//  Created by euijjang97 on 1/15/26.
//

import SwiftUI

struct ScheduleHeader: View {
    
    // MARK: - Property
    @Binding var month: Date
    @Binding var selectedDate: Date
    @Binding var scheduleMode: ScheduleMode
    @State var showDatePicker: Bool = false
    
    private var koreanMonth: String {
        let monthNumber = Calendar.current.component(.month, from: month)
        return "\(monthNumber)"
    }
    
    private var koreanYear: String {
        let yearNumber = Calendar.current.component(.year, from: month)
        return "\(yearNumber)"
    }
    
    // MARK: - Constant
    enum Constants {
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
    
    /// 캘린더 표시 타이틀
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
    
    /// 리스트 <-> 캘린더 전환 스위치
    private var headerSwitch: some View {
        Picker(selection: $scheduleMode, content: {
            Image(systemName: "calendar")
                .tag(ScheduleMode.grid)
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
