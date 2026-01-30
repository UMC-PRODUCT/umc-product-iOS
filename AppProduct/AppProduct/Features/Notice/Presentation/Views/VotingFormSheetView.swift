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

    // MARK: - Constant
    fileprivate enum Constants {
        static let trashSize: CGFloat = 16
        static let trashPadding: CGFloat = 12
        static let optionHPadding: CGFloat = 8
        static let toggleMargin: CGFloat = 16
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.formData == rhs.formData
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            VStack(spacing: DefaultSpacing.spacing12) {
                optionsSection
                if formData.canAddOption {
                    addOptionButton
                }
                toggleSection
                Spacer()
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            .padding(.top, DefaultConstant.defaultContentTopMargins)
            .navigation(naviTitle: .vote, displayMode: .inline)
            .toolbar {
                ToolBarCollection.CancelBtn(action: {
                    onCancel()
                    dismiss()
                })
                ToolBarCollection.ConfirmBtn(action: {
                    onConfirm()
                    dismiss()
                })
            }
        }
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
                    .foregroundStyle(.grey400)
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
        .padding(.top, Constants.toggleMargin)
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
