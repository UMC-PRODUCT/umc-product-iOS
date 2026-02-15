//
//  VotingFormSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 1/28/26.
//

import SwiftUI

struct VotingFormSheetView: View, Equatable {

    // MARK: - Property
    @Binding var formData: VoteFormData
    @Environment(\.dismiss) private var dismiss
    var onCancel: () -> Void
    var onConfirm: () -> Void
    var onDelete: (() -> Void)? = nil
    var isEditingConfirmedVote: Bool = false
    
    @State private var alertPrompt: AlertPrompt?

    // MARK: - Constant
    fileprivate enum Constants {
        static let questionBottomMargin: CGFloat = 4
        static let trashSize: CGFloat = 16
        static let trashPadding: CGFloat = 12
        static let optionHPadding: CGFloat = 8
        static let toggleTopMargin: CGFloat = 16
        static let dateTopMargin: CGFloat = 4
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.formData == rhs.formData
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: DefaultSpacing.spacing12) {
                titleSection
                optionsSection
                if formData.canAddOption {
                    addOptionButton
                }
                toggleSection
                dateSection
                Spacer()
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.top, DefaultConstant.defaultContentTopMargins)
            .navigation(naviTitle: .vote, displayMode: .inline)
            .toolbar {
                ToolBarCollection.CancelBtn(action: {
                    showCancelAlert()
                })
                ToolBarCollection.ConfirmBtn(action: {
                    onConfirm()
                    dismiss()
                }, disable: !formData.canConfirm
                )
            }
            .alertPrompt(item: $alertPrompt)
        }
    }
    
    // MARK: - Title Section
    private var titleSection: some View {
        VStack {
            TextField(
                "",
                text: $formData.title,
                prompt: Text("투표 제목을 입력하세요")
            )
            .appFont(.calloutEmphasis)
            .padding(.horizontal, Constants.optionHPadding)
            
            Divider()
        }
        .padding(.bottom, Constants.questionBottomMargin)
    }
    
    // MARK: - Options
    private var optionsSection: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            ForEach($formData.options) { $option in
                optionRow(option: $option)
                    .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity)))
            }
        }
    }

    private func optionRow(option: Binding<VoteOptionItem>) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            TextField(
                "",
                text: option.text,
                prompt: Text("항목 \(optionIndex(for: option.wrappedValue) + 1)")
            )
            .appFont(.callout)
            .padding(DefaultConstant.defaultTextFieldPadding)
            
            if canDeleteOption(at: optionIndex(for: option.wrappedValue)) {
                Button {
                    removeOption(option.wrappedValue)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: Constants.trashSize))
                        .foregroundStyle(.red)
                        .padding(Constants.trashPadding)
                }
            }
        }
        .padding(.horizontal, Constants.optionHPadding)
        .background {
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.grey100)
        }
    }

    // MARK: - Add Option Button
    private var addOptionButton: some View {
        Button {
            addOption()
        } label: {
            Label("항목 추가", systemImage: "plus")
                .appFont(.callout, color: .black)
                .frame(maxWidth: .infinity)
                .padding(DefaultConstant.defaultTextFieldPadding)
                .background {
                    RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                        .fill(.clear)
                        .strokeBorder(.grey300, style: StrokeStyle(lineWidth: 1, dash: [7]))
                }
        }
        .disabled(!formData.canAddOption)
    }

    // MARK: - Toggle Section
    private var toggleSection: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            toggleItem(title: "익명 투표", isOn: $formData.isAnonymous)

            toggleItem(title: "복수 선택 허용", isOn: $formData.allowMultipleSelection)
        }
        .padding(.top, Constants.toggleTopMargin)
    }

    private func toggleItem(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            Text(title)
                .appFont(.subheadline)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(.indigo500)
        }
    }
    
    // MARK: - Date Section
    private var dateSection: some View {
        VStack(spacing: DefaultSpacing.spacing16) {
            HStack {
                Text("투표 시작일")
                    .appFont(.subheadline)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { formData.startDate },
                        set: { newDate in
                            formData.startDate = Calendar.current.startOfDay(for: newDate)
                        }
                    ),
                    in: Date()...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
            }
            
            HStack {
                Text("투표 마감일")
                    .appFont(.subheadline)
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: Binding(
                        get: { formData.endDate },
                        set: { newDate in
                            let calendar = Calendar.current
                            let startOfDay = calendar.startOfDay(for: newDate)
                            formData.endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: startOfDay) ?? newDate
                        }
                    ),
                    in: Calendar.current.date(byAdding: .day, value: 1, to: formData.startDate)!...,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
            }
        }
        .padding(.top, Constants.dateTopMargin)
    }

    // MARK: - Function
    private func optionIndex(for option: VoteOptionItem) -> Int {
        formData.options.firstIndex(where: { $0.id == option.id }) ?? 0
    }

    private func canDeleteOption(at index: Int) -> Bool {
        index >= VoteFormData.minOptionCount
    }

    private func addOption() {
        guard formData.canAddOption else { return }
        formData.options.append(VoteOptionItem())
    }

    private func removeOption(_ option: VoteOptionItem) {
        guard formData.canRemoveOption else { return }
        formData.options.removeAll { $0.id == option.id }
    }
    
    private func showCancelAlert() {
        if isEditingConfirmedVote {
            // 확정된 투표를 수정 중이면 삭제 확인
            alertPrompt = AlertPrompt(
                title: "투표 삭제",
                message: "투표를 삭제하시겠습니까?\n삭제 후에는 복구할 수 없습니다.",
                positiveBtnTitle: "삭제",
                positiveBtnAction: {
                    self.onDelete?()
                    self.dismiss()
                },
                negativeBtnTitle: "취소",
                isPositiveBtnDestructive: true
            )
        } else {
            // 새로 만드는 중이면 변경사항 폐기 확인
            alertPrompt = AlertPrompt(
                title: "투표 작성 취소",
                message: "작성 중인 투표를 취소하시겠습니까?\n입력한 내용이 저장되지 않습니다.",
                positiveBtnTitle: "취소",
                positiveBtnAction: {
                    self.onCancel()
                    self.dismiss()
                },
                negativeBtnTitle: "계속 작성",
                isPositiveBtnDestructive: true
            )
        }
    }
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    @Previewable @State var formData = VoteFormData()
    
    NavigationStack {
        VotingFormSheetView(
            formData: $formData,
            onCancel: {
                formData = VoteFormData()
                print("취소됨")
            },
            onConfirm: {
                print("저장됨: \(formData)")
            }
        )
    }
}
