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

    // MARK: - Property

    /// 일정 등록 뷰 모델
    @State var viewModel: ScheduleRegistrationViewModel

    /// 전역 에러 핸들러
    @Environment(ErrorHandler.self) var errorHandler
    @Environment(\.dismiss) var dismiss

    @AppStorage(AppStorageKey.gisuId) private var gisuId: Int = 0
    @AppStorage(AppStorageKey.memberRole) private var memberRole: ManagementTeam = .challenger
    private let mode: Mode

    enum Mode {
        case create
        case edit
    }

    private enum Constants {
        static let createLoadingMessage: String = "일정 생성 중입니다."
        static let editLoadingMessage: String = "일정 수정 중입니다."
    }

    // MARK: - Init

    /// 초기화 메서드
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        mode: Mode = .create,
        prefill: ScheduleDetailData? = nil,
        prefillRoadAddress: String? = nil
    ) {
        self.mode = mode
        let viewModel = ScheduleRegistrationViewModel(
            container: container,
            errorHandler: errorHandler
        )
        if let prefill {
            viewModel.applyPrefill(from: prefill, roadAddress: prefillRoadAddress)
        }
        self._viewModel = .init(wrappedValue: viewModel)
    }
    
    // MARK: - Body

    var body: some View {
        formContent
        .scrollDismissesKeyboard(.immediately) // 스크롤 시 키보드 내림
        .navigation(naviTitle: navigationTitle, displayMode: .inline)
        .toolbar { toolbarContent }
        .alertPrompt(item: $viewModel.alertPrompt)
        .overlay { submittingOverlay }
        // 생성 성공 시 화면 자동 닫기
        .onChange(of: viewModel.submitState) {
            if case .loaded = viewModel.submitState {
                dismiss()
            }
        }
    }

    // MARK: - Content

    private var formContent: some View {
        Form {
            section(.title, .place)
            section(.allDay, .date)
            section(.participation)
            section(.tag)
            section(.memo)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if mode == .edit {
            ToolBarCollection.RejectBtn(action: {})
            ToolBarCollection.ConfirmBtn(
                action: {
                    Task {
                        await viewModel.updateSchedule()
                    }
                },
                disable: isActionDisabled,
                dismissOnTap: false,
            )
        } else {
            ToolBarCollection.AddBtn(
                action: { submitCreateAction() },
                disable: isActionDisabled
            )
        }
    }

    @ViewBuilder
    private var submittingOverlay: some View {
        if isSubmitting {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                Progress(
                    progressColor: .white,
                    message: mode == .edit ? Constants.editLoadingMessage : Constants.createLoadingMessage,
                    messageColor: .white,
                    size: .regular
                )
                .padding(24)
            }
            .allowsHitTesting(true)
        }
    }

    // MARK: - Section Builder

    @ViewBuilder
    private func section(_ types: ScheduleGenerationType...) -> some View {
        Section {
            ForEach(types, id: \.self) { type in
                sectionView(type)
            }
        }
    }

    // MARK: - Helper

    private var navigationTitle: NavigationModifier.Navititle {
        mode == .create ? .registration : .registrationEdit
    }

    private var isSubmitting: Bool {
        if case .loading = viewModel.submitState {
            return true
        }
        return false
    }

    private var isActionDisabled: Bool {
        let hasRequired = !viewModel.title.isEmpty && !viewModel.tag.isEmpty
        if mode == .edit {
            return !hasRequired || !viewModel.hasChangesInEditMode || isSubmitting
        }
        return !hasRequired || isSubmitting
    }

    // MARK: - Action

    private func submitCreateAction() {
        // 챌린저: 출석부 없이 바로 생성, 운영진: Alert으로 출석부 포함 여부 선택
        if memberRole == .challenger {
            Task {
                await viewModel.submitSchedule(
                    gisuId: gisuId,
                    requiresApproval: false
                )
            }
        } else {
            viewModel.alertAction(gisuId: gisuId)
        }
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
            PlaceSelectView(place: $viewModel.place)
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

/// 일정 제목을 입력받는 서브 뷰입니다.
fileprivate struct TitleView: View, Equatable {
    /// 입력된 제목 텍스트 (바인딩)
    @Binding var text: String
    
    /// 값 변경 감지를 위한 Equatable 프로토콜 구현
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.text == rhs.text
    }
    
    var body: some View {
        TextField("", text: $text, prompt: placeholer)
            .submitLabel(.return) // 키보드 'return' 버튼
            .tint(.indigo500)     // 커서 색상
            .appFont(.body, color: .black)
    }
    
    /// 플레이스홀더 텍스트 뷰
    private var placeholer: Text {
        Text(ScheduleGenerationType.title.placeholder ?? "")
            .font(ScheduleGenerationType.title.placeholderFont)
            .foregroundStyle(ScheduleGenerationType.title.placeholderColor)
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
///
/// 시작 날짜/시간 행과 종료 날짜/시간 행, 그리고 각각의 Picker를 포함합니다.
fileprivate struct DateTimeSection: View {
    
    // MARK: - Property
    
    @Binding var isAllDay: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    
    // Picker 표시 상태 바인딩 (하나가 열리면 나머지는 닫히는 로직을 상위에서 제어)
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
            generateDatePicker(
                condition: showEndDatePicker,
                date: $endDate,
                minimumDate: startDate
            )
            generateTimePicker(
                condition: showEndTimePicker,
                date: $endDate,
                minimumDate: startDate
            )
        }
        .onChange(of: startDate) { _, newValue in
            if endDate < newValue {
                endDate = newValue
            }
        }
        .onChange(of: endDate) { _, newValue in
            if newValue < startDate {
                endDate = startDate
            }
        }
    }
    
    /// 시작 날짜/시간 표시 행
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
    
    /// 종료 날짜/시간 표시 행
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
    private func generateDatePicker(
        condition: Bool,
        date: Binding<Date>,
        minimumDate: Date? = nil
    ) -> some View {
        if condition {
            if let minimumDate {
                DatePickerRow(
                    date: date,
                    range: minimumDate...Date.distantFuture
                )
            } else {
                DatePickerRow(date: date, range: nil)
            }
        }
    }
    
    /// 시간 선택 피커 생성
    @ViewBuilder
    private func generateTimePicker(
        condition: Bool,
        date: Binding<Date>,
        minimumDate: Date? = nil
    ) -> some View {
        if condition {
            if let minimumDate {
                TimePickerRow(
                    date: date,
                    range: minimumDate...Date.distantFuture
                )
            } else {
                TimePickerRow(date: date, range: nil)
            }
        }
    }
}

// MARK: - Tag Section

/// 태그 선택 섹션 (아이콘 선택 등)
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

/// 참여자(챌린저) 선택 및 관리 섹션
fileprivate struct PariticipantSection: View {
    
    /// 선택된 참여자 리스트 바인딩
    @Binding var challenger: [ChallengerInfo]
    
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

/// 메모 입력 섹션 (TextEditor)
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
                // 메모가 비어있을 때 플레이스홀더 표시
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
    ScheduleRegistrationView(container: DIContainer(), errorHandler: ErrorHandler())
        .environment(ErrorHandler())
}
