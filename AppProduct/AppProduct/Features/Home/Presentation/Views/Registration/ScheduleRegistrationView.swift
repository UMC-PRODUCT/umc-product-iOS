//
//  RegistrationView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/22/26.
//

import SwiftUI

/// 일정 생성 화면
///
/// 새로운 일정을 생성하거나 기존 일정을 편집할 때 사용되는 화면입니다.
/// 제목, 장소, 날짜, 시간, 참여자, 태그, 메모 등의 정보를 입력받습니다.
struct ScheduleRegistrationView: View {
    
    // MARK: - Properties
    
    /// 일정 등록 뷰 모델
    @State var viewModel: ScheduleRegistrationViewModel
    
    /// 전역 에러 핸들러
    @Environment(ErrorHandler.self) var errorHandler
    
    // MARK: - Init
    
    /// 초기화 메서드
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    // MARK: - Body
    
    var body: some View {
        Form {
            // 섹션 1: 제목 및 장소
            Section {
                sectionView(.title)
                sectionView(.place)
            }
            
            // 섹션 2: 날짜 및 시간
            Section {
                sectionView(.allDay)
                sectionView(.date)
            }
            
            // 섹션 3: 참여자
            Section {
                sectionView(.participation)
            }
            
            // 섹션 4: 태그
            Section {
                sectionView(.tag)
            }
            
            // 섹션 5: 메모
            Section {
                sectionView(.memo)
            }
        }
        .scrollDismissesKeyboard(.immediately) // 스크롤 시 키보드 내림
    }
    
    // MARK: - Section Components
    
    /// 각 섹션 타입에 맞는 뷰를 반환합니다.
    /// - Parameter type: 일정 생성 화면의 섹션 타입 (제목, 장소, 시간 등)
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
            Memo(memo: $viewModel.memo)
                .equatable()
        case .participation:
            PariticipantSection(challenger: $viewModel.participatn)
        case .tag:
            TagSection(tag: $viewModel.tag)
        }
    }
}

// MARK: - Subviews

/// 제목 입력 뷰
fileprivate struct TitleView: View, Equatable {
    /// 입력된 제목 텍스트바인딩
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

// MARK: - Place View

/// 장소 선택 뷰 (지도 검색 기능 포함)
fileprivate struct PlaceView: View, Equatable {
    
    /// 선택된 장소 정보 바인딩
    @Binding var place: PlaceSearchInfo
    
    /// 지도 검색 모달 표시 여부
    @State var showSearchMap: Bool = false
    
    /// 에러 핸들러 (지도 검색 중 에러 발생 시 처리)
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
        })
        .sheet(isPresented: $showSearchMap, content: {
            SearchMapView(errorHandler: errorHandler, placeSelected: { place in
                self.place = place
            })
            .presentationDragIndicator(.visible)
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

// MARK: - All Day Toggle

/// "하루 종일" 설정 토글 뷰
fileprivate struct AllDayToggle: View, Equatable {
    /// 토글 상태 바인딩
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


// MARK: - DateTime Section

/// 시작/종료 날짜 및 시간 선택 섹션
fileprivate struct DateTimeSection: View {
    
    // MARK: - Properties
    
    @Binding var isAllDay: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    // Picker 표시 상태 바인딩
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
    
    /// 날짜 선택 피커 생성
    @ViewBuilder
    private func generateDatePicker(condition: Bool, date: Binding<Date>) -> some View {
        if condition {
            DatePickerRow(date: date)
        }
    }
    
    /// 시간 선택 피커 생성
    @ViewBuilder
    private func generateTimePicker(condition: Bool, date: Binding<Date>) -> some View {
        if condition {
            TimePickerRow(date: date)
        }
    }
}

// MARK: - Tag Section

/// 태그 선택 섹션
fileprivate struct TagSection: View {
    
    /// 선택된 태그 리스트 바인딩
    @Binding var tag: [ScheduleIconCategory]
    
    /// 태그 선택 시트 표시 여부
    @State var showTagList: Bool = false
  
    private enum Constants {
        static let tagText: String = "태그"
        static let chevronImage: String = "chevron.right"
    }
    
    var body: some View {
        Button(action: {
            showTagList.toggle()
        }, label: {
            HStack {
                Text(Constants.tagText)
                    .foregroundStyle(.black)
                Spacer()
                tagCount
            }
        })
        .sheet(isPresented: $showTagList, content: {
            TagListView(tagList: $tag)
                .presentationDragIndicator(.visible)
                .interactiveDismissDisabled()
        })
    }
    
    /// 선택된 태그 개수 표시
    private var tagCount: some View {
        HStack(spacing: DefaultSpacing.spacing8, content: {
            if !tag.isEmpty {
                Text("\(tag.count)개 선택됨")
                    .appFont(.callout, color: .grey500)
            }
            
            Image(systemName: Constants.chevronImage)
                .foregroundStyle(.grey500)
        })
    }
}

// MARK: - Participant Section

/// 참여자 선택 섹션
fileprivate struct PariticipantSection: View {
    
    /// 선택된 참여자 리스트 바인딩
    @Binding var challenger: [Participant]
    
    /// 참여자 선택 시트 표시 여부
    @State var showPariticipant: Bool = false
    
    private enum Constants {
        static let challengerText: String = "초대받은 챌린저"
        static let chevronImage: String = "chevron.right"
    }
    
    var body: some View {
        Button(action: {
            showPariticipant.toggle()
        }, label: {
            HStack {
                Text(Constants.challengerText)
                    .foregroundStyle(.black)
                Spacer()
                participant
            }
        })
        .sheet(isPresented: $showPariticipant, content: {
            SelectedChallengerView(challenger: $challenger)
                .interactiveDismissDisabled()
        })
    }
    
    /// 선택된 참여자 수 표시
    private var participant: some View {
        HStack(spacing: DefaultSpacing.spacing8, content: {
            if !challenger.isEmpty {
                Text("\(challenger.count)명")
                    .appFont(.callout, color: .grey500)
            }
            
            Image(systemName: Constants.chevronImage)
                .foregroundStyle(.grey500)
        })
    }
    
}

// MARK: - Memo Section

/// 메모 입력 섹션
fileprivate struct Memo: View, Equatable {
    /// 입력된 메모 텍스트 바인딩
    @Binding var memo: String
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.memo == rhs.memo
    }
    
    private enum Constants {
        static let textEditorHeight: CGFloat = 200
        static let editorPadding: CGFloat = 4
        static let placeholderPadding: EdgeInsets = .init(top: 8, leading: 4, bottom: 8, trailing: 4)
    }
    
    var body: some View {
        TextEditor(text: $memo)
            .overlay(alignment: .topLeading, content: {
                if memo.isEmpty {
                    Text(ScheduleGenerationType.memo.placeholder ?? "")
                        .font(ScheduleGenerationType.memo.placeholderFont)
                        .foregroundStyle(ScheduleGenerationType.memo.placeholderColor)
                        .padding(Constants.placeholderPadding)
                }
            })
            .frame(height: Constants.textEditorHeight)
    }
}

#Preview {
    ScheduleRegistrationView()
        .environment(ErrorHandler())
}
