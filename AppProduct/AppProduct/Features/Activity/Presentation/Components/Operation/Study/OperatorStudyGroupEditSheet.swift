//
//  OperatorStudyGroupEditSheet.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/11/26.
//

import SwiftUI

/// 스터디 그룹 정보 수정 시트
///
/// 그룹 이름과 소속 파트를 수정할 수 있는 시트입니다.
struct OperatorStudyGroupEditSheet: View {
    // MARK: - Property

    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var selectedPart: UMCPartType

    /// 수정 대상 그룹 정보
    let detail: StudyGroupInfo
    /// 저장 완료 콜백 (이름, 파트 전달)
    let onSave: (String, UMCPartType) -> Void

    fileprivate enum Constants {
        static let allParts: [UMCPartType] = UMCPartType.allCases
    }

    // MARK: - Initializer

    /// - Parameters:
    ///   - detail: 수정할 그룹 정보 (초기값으로 사용)
    ///   - onSave: 저장 시 호출될 콜백
    init(
        detail: StudyGroupInfo,
        onSave: @escaping (String, UMCPartType) -> Void
    ) {
        self.detail = detail
        self.onSave = onSave
        _name = State(initialValue: detail.name)
        _selectedPart = State(initialValue: detail.part)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                nameSection
                partSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("그룹 정보 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolBarCollection.CancelBtn {}
                ToolBarCollection.ConfirmBtn {
                    onSave(name, selectedPart)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Sections

    private var nameSection: some View {
        Section {
            TextField("그룹 이름", text: $name)
        } header: {
            Text("그룹 이름")
                .appFont(.calloutEmphasis, color: .black)
        }
    }

    private var partSection: some View {
        Section {
            Picker("소속 파트", selection: $selectedPart) {
                ForEach(Constants.allParts, id: \.self) { part in
                    Text(part.name).tag(part)
                }
            }
        } header: {
            Text("소속 파트")
                .appFont(.calloutEmphasis, color: .black)
        }
    }
}
