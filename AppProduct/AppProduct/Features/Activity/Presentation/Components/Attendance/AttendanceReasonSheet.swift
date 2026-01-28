//
//  AttendanceReasonSheet.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/28/26.
//

import SwiftUI

/// 출석 사유 작성 시트
///
/// GPS 출석이 어려운 경우 사유를 작성하여 출석을 요청할 수 있는 시트입니다.
struct AttendanceReasonSheet: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var reason: String = ""

    let onSubmit: (String) async -> Void
    
    private enum Constants {
        static let defaultSheetFraction: CGFloat = 200
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    reasonTextField
                } header: {
                    Text("지각 사유 입력")
                        .appFont(.bodyEmphasis, color: .black)
                } footer: {
                    descriptionText
                }
            }
            .toolbar {
                ToolBarCollection.CancelBtn(action: {})
                
                ToolBarCollection.ConfirmBtn(action: {
                    Task {
                        await onSubmit(reason)
                        dismiss()
                    }
                })
            }
            .scrollContentBackground(.hidden)
            .scrollDisabled(true)
            .presentationDetents([.height(Constants.defaultSheetFraction)])
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled()
        }
    }

    // MARK: - View Components

    private var reasonTextField: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            TextField(
                "",
                text: $reason,
                prompt: Text("길이 막혀요..").foregroundStyle(.grey500)
            )
            .submitLabel(.done)
        }
    }

    private var descriptionText: some View {
        Text("위치 인증이 어려운 경우 사유를 작성하여 출석을 요청할 수 있습니다. (예: GPS 오류, 지각, 개인 사정 등)")
            .appFont(.footnote, weight: .regular, color: .gray)
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .truncationMode(.tail)
    }

    private var buttonGroup: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            MainButton("취소") {
                dismiss()
            }
            .buttonStyle(.destructive)

            MainButton("제출하기") {
                Task {
                    await onSubmit(reason)
                    dismiss()
                }
            }
            .buttonStyle(.primary)
            .disabled(reason.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
    }
}

// MARK: - Preview

#Preview {
    Text("Preview Trigger")
        .sheet(isPresented: .constant(true)) {
            NavigationStack {
                AttendanceReasonSheet { reason in
                    print("Submitted reason: \(reason)")
                }
            }
        }
}
