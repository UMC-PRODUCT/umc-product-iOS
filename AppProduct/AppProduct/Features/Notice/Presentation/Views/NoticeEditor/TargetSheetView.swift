//
//  TargetSheetView.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import SwiftUI

struct TargetSheetView: View {
    @State var viewModel: NoticeEditorViewModel
    let sheetType: TargetSheetType
    @Environment(\.dismiss) private var dismiss
    
    private enum Constants {
        static let chipSpacing: CGFloat = 8
    }
    
    private var navigationTitle: NavigationModifier.Navititle {
        switch sheetType {
        case .branch: return .branchSelection
        case .school: return .schoolSelection
        case .part: return .partSelection
        }
    }
    
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
    
    private var partFilterSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            FlowLayout(spacing: Constants.chipSpacing) {
                ForEach(Part.allCases.filter { $0 != .all }) { part in
                    ChipButton(part.name, isSelected: viewModel.isPartSelected(part)) {
                        viewModel.togglePart(part)
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
