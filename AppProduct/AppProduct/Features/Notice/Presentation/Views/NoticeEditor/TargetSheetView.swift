//
//  TargetSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import SwiftUI

/// 공지 수신 대상 선택 시트 (지부/학교/파트)
struct TargetSheetView: View {

    // MARK: - Property
    @State var viewModel: NoticeEditorViewModel
    let sheetType: TargetSheetType
    @Environment(\.dismiss) private var dismiss
    
    private enum Constants {
        static let chipSpacing: CGFloat = 8
    }
    
    // MARK: - Helper
    private var navigationTitle: NavigationModifier.Navititle {
        switch sheetType {
        case .branch: return .branchSelection
        case .school: return .schoolSelection
        case .part: return .partSelection
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
                    sheetContent
                }
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                .padding(.top, DefaultSpacing.spacing16)
            }
            .navigation(naviTitle: navigationTitle, displayMode: .inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(role: .confirm, action: {
                        dismiss()
                    }, label: {
                        Image(systemName: "checkmark")
                    })
                }
            }
        }
    }
    
    // MARK: - Private Function
    /// 선택된 시트 타입에 맞는 필터 섹션을 반환합니다.
    @ViewBuilder
    private var sheetContent: some View {
        switch sheetType {
        case .part:
            partFilterSection
        case .branch:
            branchFilterSection
        case .school:
            schoolFilterSection
        }
    }
    
    /// 지부 대상 선택 섹션입니다.
    private var branchFilterSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            FlowLayout(spacing: Constants.chipSpacing) {
                ForEach(viewModel.branches, id: \.self) { branch in
                    ChipButton(branch, isSelected: viewModel.isBranchSelected(branch)) {
                        viewModel.toggleBranch(branch)
                    }
                    .buttonSize(.medium)
                }
            }
            
            Text("선택하지 않으면 전체 지부에게 전송됩니다.")
                .appFont(.footnote, color: .grey400)
        }
    }
    
    /// 학교 대상 선택 섹션입니다.
    private var schoolFilterSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            FlowLayout(spacing: Constants.chipSpacing) {
                ForEach(viewModel.schools, id: \.self) { school in
                    ChipButton(school, isSelected: viewModel.isSchoolSelected(school)) {
                        viewModel.toggleSchool(school)
                    }
                    .buttonSize(.medium)
                }
            }
            
            Text("선택하지 않으면 전체 학교에게 전송됩니다.")
                .appFont(.footnote, color: .grey400)
        }
    }
    
    /// 파트 대상 선택 섹션입니다.
    private var partFilterSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            FlowLayout(spacing: Constants.chipSpacing) {
                ForEach(NoticePart.allCases) { part in
                    ChipButton(
                        part.displayName,
                        isSelected: viewModel.isPartSelected(part.umcPartType)
                    ) {
                        viewModel.togglePart(part.umcPartType)
                    }
                    .buttonSize(.medium)
                }
            }
            
            Text("선택하지 않으면 전체 파트원에게 전송됩니다.")
                .appFont(.footnote, color: .grey400)
        }
        .frame(maxWidth: .infinity)
    }
}
