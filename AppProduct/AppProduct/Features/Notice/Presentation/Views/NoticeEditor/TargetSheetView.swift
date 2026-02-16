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

    // MARK: - Constants

    /// 타겟 선택 시트의 레이아웃/문구 상수 모음
    private enum Constants {
        static let rootContentSpacing: CGFloat = DefaultSpacing.spacing24
        static let sectionSpacing: CGFloat = DefaultSpacing.spacing12
        static let chipSpacing: CGFloat = DefaultSpacing.spacing12
        static let horizontalPadding: CGFloat = 12
        static let topPadding: CGFloat = DefaultSpacing.spacing16
        static let bottomPadding: CGFloat = DefaultSpacing.spacing24

        static let branchGuideMessage: String = "선택하지 않으면 전체 지부에게 전송됩니다."
        static let schoolGuideMessage: String = "선택하지 않으면 전체 학교에게 전송됩니다."
        static let partGuideMessage: String = "선택하지 않으면 전체 파트원에게 전송됩니다."
    }

    // MARK: - Helper

    private var navigationTitle: NavigationModifier.Navititle {
        switch sheetType {
        case .branch:
            return .branchSelection
        case .school:
            return .schoolSelection
        case .part:
            return .partSelection
        }
    }

    private var navigationSubtitle: String {
        switch sheetType {
        case .branch:
            return Constants.branchGuideMessage
        case .school:
            return Constants.schoolGuideMessage
        case .part:
            return Constants.partGuideMessage
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: Constants.rootContentSpacing) {
                sheetContent
                Spacer(minLength: 0)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.top, Constants.topPadding)
            .padding(.bottom, Constants.bottomPadding)
            .navigation(naviTitle: navigationTitle, displayMode: .inline)
            .navigationSubtitle(navigationSubtitle)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolBarCollection.ConfirmBtn(
            action: { dismiss() },
            dismissOnTap: false
        )
    }

    // MARK: - Content

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

    // MARK: - Section Builders

    /// 지부 대상 선택 섹션
    private var branchFilterSection: some View {
        selectionSection {
            FlowLayout(spacing: Constants.chipSpacing) {
                ForEach(viewModel.branchOptions, id: \.self) { branch in
                    ChipButton(branch.name, isSelected: viewModel.isBranchSelected(branch)) {
                        viewModel.toggleBranch(branch)
                    }
                    .buttonSize(.medium)
                }
            }
        }
    }

    /// 학교 대상 선택 섹션
    private var schoolFilterSection: some View {
        selectionSection {
            FlowLayout(spacing: Constants.chipSpacing) {
                ForEach(viewModel.schoolOptions, id: \.self) { school in
                    ChipButton(school.name, isSelected: viewModel.isSchoolSelected(school)) {
                        viewModel.toggleSchool(school)
                    }
                    .buttonSize(.medium)
                }
            }
        }
    }

    /// 파트 대상 선택 섹션
    private var partFilterSection: some View {
        selectionSection {
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
        }
    }

    // MARK: - Shared Section

    /// 타겟 선택 칩 레이아웃을 공통화합니다.
    @ViewBuilder
    private func selectionSection<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
