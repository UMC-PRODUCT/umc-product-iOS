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
/// Liquid Glass 스타일이 적용된 버튼을 사용합니다.
struct AttendanceReasonSheet: View {

    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var reason: String = ""

    let onSubmit: (String) async -> Void

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            reasonTextField
            descriptionText
            Spacer().frame(height: 12)
            buttonGroup
        }
        .safeAreaPadding(.top, DefaultConstant.defaultSafeTop)
        .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        .presentationDetents([.fraction(0.35)])
        .presentationDragIndicator(.visible)
    }

    // MARK: - View Components

    private var descriptionText: some View {
        Text("위치 인증이 어려운 경우 사유를 작성하여 출석을 요청할 수 있습니다.\n(예: GPS 오류, 지각, 개인 사정 등)")
            .appFont(.footnote, weight: .regular, color: .grey500)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    private var reasonTextField: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing12) {
            Text("출석 사유 입력")
                .appFont(.calloutEmphasis, color: .grey600)

            TextField(
                "",
                text: $reason,
                prompt: Text("길이 막혀요..").foregroundStyle(.grey500)
            )
            .foregroundStyle(.grey900)
            .padding(DefaultConstant.defaultTextFieldPadding)
            .background(.white, in: .rect(
                cornerRadius: DefaultConstant.defaultCornerRadius))
            .contentShape(Rectangle())
            .submitLabel(.done)
        }
    }

    private var buttonGroup: some View {
        GlassEffectContainer {
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
        }
    }
}

// MARK: - Preview

#Preview {
    Text("Preview Trigger")
        .sheet(isPresented: .constant(true)) {
            AttendanceReasonSheet { reason in
                print("Submitted reason: \(reason)")
            }
        }
}
