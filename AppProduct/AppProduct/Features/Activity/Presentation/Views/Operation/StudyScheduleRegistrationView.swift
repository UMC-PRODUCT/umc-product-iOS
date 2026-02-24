//
//  StudyScheduleRegistrationView.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/10/26.
//

import SwiftUI

/// 스터디 일정 등록 화면
///
/// 스터디 그룹 카드에서 "스터디 일정 등록하기" 버튼을 탭하면 푸시됩니다.
/// 스터디명, 일시(시작/종료), 장소를 입력받습니다.
struct StudyScheduleRegistrationView: View {

    // MARK: - Property

    @State private var viewModel: StudyScheduleRegistrationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSubmitting = false

    // MARK: - Init

    /// - Parameters:
    ///   - container: 의존성 주입 컨테이너
    ///   - errorHandler: 전역 에러 핸들러
    ///   - studyName: 스터디 그룹 이름 (초기값)
    ///   - studyGroupId: 스터디 그룹 식별자
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        studyName: String,
        studyGroupId: Int
    ) {
        let useCase = container
            .resolve(ActivityUseCaseProviding.self)
            .fetchStudyMembersUseCase
        _viewModel = State(
            initialValue: StudyScheduleRegistrationViewModel(
                studyName: studyName,
                studyGroupId: studyGroupId,
                useCase: useCase,
                errorHandler: errorHandler
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Form {
            Section {
                studyNameField
            }

            Section {
                dateTimeSection
            }

            Section {
                PlaceSelectView(place: $viewModel.place)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigation(
            naviTitle: .studyScheduleRegistration,
            displayMode: .inline
        )
        .toolbar {
            ToolBarCollection.ConfirmBtn(
                action: submitSchedule,
                disable: !viewModel.canSubmit || isSubmitting,
                isLoading: isSubmitting,
                dismissOnTap: false
            )
        }
    }

    private func submitSchedule() {
        guard !isSubmitting else { return }
        guard viewModel.canSubmit else { return }

        Task {
            isSubmitting = true
            let isSuccess = await viewModel.submitSchedule()
            isSubmitting = false

            if isSuccess {
                dismiss()
            }
        }
    }

    // MARK: - Section Components

    /// 스터디명 입력 필드
    private var studyNameField: some View {
        TextField(
            "",
            text: $viewModel.studyName,
            prompt: Text("스터디명")
                .foregroundStyle(.grey400)
        )
        .appFont(.body, color: .black)
        .submitLabel(.next)
        .tint(.indigo500)
    }

    /// 시작/종료 날짜·시간 선택 섹션
    @ViewBuilder
    private var dateTimeSection: some View {
        // 시작 행
        DateTimeRow(
            title: "시작",
            date: viewModel.startDate,
            isAllDay: false,
            isDatePickerActive: viewModel.showStartDatePicker,
            isTimePickerActive: viewModel.showStartTimePicker,
            dateTap: {
                withAnimation {
                    viewModel.showStartDatePicker.toggle()
                    viewModel.showStartTimePicker = false
                    viewModel.showEndDatePicker = false
                    viewModel.showEndTimePicker = false
                }
            },
            timeTap: {
                withAnimation {
                    viewModel.showStartTimePicker.toggle()
                    viewModel.showStartDatePicker = false
                    viewModel.showEndDatePicker = false
                    viewModel.showEndTimePicker = false
                }
            }
        )
        .equatable()

        if viewModel.showStartDatePicker {
            DatePickerRow(date: $viewModel.startDate)
        }

        if viewModel.showStartTimePicker {
            TimePickerRow(date: $viewModel.startDate)
        }

        // 종료 행
        DateTimeRow(
            title: "종료",
            date: viewModel.endDate,
            isAllDay: false,
            isDatePickerActive: viewModel.showEndDatePicker,
            isTimePickerActive: viewModel.showEndTimePicker,
            dateTap: {
                withAnimation {
                    viewModel.showEndDatePicker.toggle()
                    viewModel.showStartDatePicker = false
                    viewModel.showStartTimePicker = false
                    viewModel.showEndTimePicker = false
                }
            },
            timeTap: {
                withAnimation {
                    viewModel.showEndTimePicker.toggle()
                    viewModel.showStartDatePicker = false
                    viewModel.showStartTimePicker = false
                    viewModel.showEndDatePicker = false
                }
            }
        )
        .equatable()

        if viewModel.showEndDatePicker {
            DatePickerRow(date: $viewModel.endDate)
        }

        if viewModel.showEndTimePicker {
            TimePickerRow(date: $viewModel.endDate)
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationStack {
        StudyScheduleRegistrationView(
            container: DIContainer(),
            errorHandler: ErrorHandler(),
            studyName: "iOS 스터디",
            studyGroupId: 1
        )
    }
    .environment(ErrorHandler())
}
#endif
