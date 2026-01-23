//
//  RegistrationView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import SwiftUI

/// 일정 생성 화면
struct ScheduleRegistrationView: View {
    
    // MARK: - Property
    @State var viewModel: ScheduleRegistrationViewModel
    @Environment(ErrorHandler.self) var errorHandler
    
    // MARK: - Init
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    // MARK: - Body
    var body: some View {
        Form {
            Section {
                sectionView(.title)
                sectionView(.place)
            }
            Section {
                sectionView(.allDay)
                sectionView(.date)
            }
        }
    }
    
    @ViewBuilder
    private func sectionView(_ type: ScheduleGenerationType) -> some View {
        switch type {
        case .title:
            TitleView(text: $viewModel.title)
                .equatable()
        case .place:
            PlaceView(place: $viewModel.place)
        case .allDay:
            AllDayToggle(isOn: $viewModel.isAllDay)
        case .date:
            DateTimeSection(
                isAllDay: $viewModel.isAllDay,
                startDate: $viewModel.dataRange.startDate,
                endDate: $viewModel.dataRange.endDate,
                showStartDatePicker: $viewModel.showStartDatePicker,
                showStartTimePicker: $viewModel.showStartTimePicker,
                showEndDatePicker: $viewModel.showEndDatePicker,
                showEndTimePicker: $viewModel.showEndTimePicker
            )
        case .memo:
            EmptyView()
        case .participation:
            EmptyView()
        case .category:
            EmptyView()
        }
    }
}

// MARK: - Spotify
fileprivate struct TitleView: View, Equatable {
    @Binding var text: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text == rhs.text
    }
    
    var body: some View {
        TextField("", text: $text, prompt: placeholer)
            .submitLabel(.return)
            .tint(.indigo500)
            .appFont(.body, color: .black)
    }
    
    private var placeholer: Text {
        Text(ScheduleGenerationType.title.placeholder ?? "")
            .font(ScheduleGenerationType.title.placeholderFont)
            .foregroundStyle(ScheduleGenerationType.title.placeholderColor)
    }
}

// MARK: - Place
fileprivate struct PlaceView: View, Equatable {
    @Binding var place: PlaceSearchInfo
    @State var showSearchMap: Bool = false
    @Environment(ErrorHandler.self) var errorHandler
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.place == rhs.place
    }
    
    var body: some View {
        Button(action: {
            showSearchMap = true
        }, label: {
            HStack(spacing: DefaultSpacing.spacing8) {
                if place.name.isEmpty {
                    emptyPlace
                } else {
                    selectedPlace
                }
                Spacer()
                
                if !place.name.isEmpty {
                    clearButton
                }
            }
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
        .sheet(isPresented: $showSearchMap, content: {
            SearchMapView(errorHandler: errorHandler, placeSelected: { place in
                self.place = place
            })
        })
    }
    
    private var emptyPlace: some View {
        Text(placeholder)
            .font(ScheduleGenerationType.place.placeholderFont)
            .foregroundStyle(ScheduleGenerationType.place.placeholderColor)
    }
    
    private var selectedPlace: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text(place.name)
                .appFont(.calloutEmphasis, color: .black)
            
            Text(place.address)
                .appFont(.subheadline, color: .grey600)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var clearButton: some View {
        Button(action: {
            place = PlaceSearchInfo(name: "", address: "", coordinate: .init(latitude: 0, longitude: 0))
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.grey400)
                .font(.system(size: 20))
        }
        .buttonStyle(.plain)
    }
    
    private var placeholder: String {
        ScheduleGenerationType.place.placeholder ?? ""
    }
}

fileprivate struct AllDayToggle: View, Equatable {
    @Binding var isOn: Bool
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.isOn == rhs.isOn
    }
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(ScheduleGenerationType.allDay.placeholder ?? "")
                .appFont(.body, color: .black)
        }
        .tint(.indigo500)
    }
}


// MARK: - DateTimeSection
fileprivate struct DateTimeSection: View {
    @Binding var isAllDay: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var showStartDatePicker: Bool
    @Binding var showStartTimePicker: Bool
    @Binding var showEndDatePicker: Bool
    @Binding var showEndTimePicker: Bool
    
    @ViewBuilder
    var body: some View {
        Group {
            startDateRow
            generateDatePicker(condition: showStartDatePicker, date: $startDate)
            generateTimePicker(condition: showStartTimePicker, date: $startDate)
            endDateRow
            generateDatePicker(condition: showEndDatePicker, date: $endDate)
            generateTimePicker(condition: showEndTimePicker, date: $endDate)
        }
    }
    
    private var startDateRow: some View {
        DateTimeRow(
            title: "시작",
            date: startDate,
            isAllDay: isAllDay,
            isDatePickerActive: showStartDatePicker,
            isTimePickerActive: showStartTimePicker,
            dateTap: {
                withAnimation {
                    showStartDatePicker.toggle()
                    showStartTimePicker = false
                    showEndDatePicker = false
                    showEndTimePicker = false
                }
            },
            timeTap: {
                withAnimation {
                    showStartTimePicker.toggle()
                    showStartDatePicker = false
                    showEndDatePicker = false
                    showEndTimePicker = false
                }
            }
        )
        .equatable()
    }
    
    private var endDateRow: some View {
        DateTimeRow(
            title: "종료",
            date: endDate,
            isAllDay: isAllDay,
            isDatePickerActive: showEndDatePicker,
            isTimePickerActive: showEndTimePicker,
            dateTap: {
                withAnimation {
                    showEndDatePicker.toggle()
                    showStartDatePicker = false
                    showStartTimePicker = false
                    showEndTimePicker = false
                }
            },
            timeTap: {
                withAnimation {
                    showEndTimePicker.toggle()
                    showStartDatePicker = false
                    showStartTimePicker = false
                    showEndDatePicker = false
                }
            }
        )
        .equatable()
    }
    
    @ViewBuilder
    private func generateDatePicker(condition: Bool, date: Binding<Date>) -> some View {
        if condition {
            DatePickerRow(date: date)
        }
    }
    
    @ViewBuilder
    private func generateTimePicker(condition: Bool, date: Binding<Date>) -> some View {
        if condition {
            TimePickerRow(date: date)
        }
    }
}

#Preview {
    ScheduleRegistrationView()
        .environment(ErrorHandler())
}
