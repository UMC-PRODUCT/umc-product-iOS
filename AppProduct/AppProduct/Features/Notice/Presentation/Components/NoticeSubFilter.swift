//
//  NoticeSubFilter.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import SwiftUI

// MARK: - NoticeSubFilter
/// 서브필터 영역 (전체, 운영진 공지 칩 + 파트 메뉴)
struct NoticeSubFilter: View, Equatable {

    @Bindable var viewModel: NoticeViewModel

    static func == (lhs: NoticeSubFilter, rhs: NoticeSubFilter) -> Bool {
        lhs.viewModel.selectedSubFilter == rhs.viewModel.selectedSubFilter &&
        lhs.viewModel.selectedPart == rhs.viewModel.selectedPart
    }

    private enum Constants {
        static let hstackSpacing: CGFloat = 8
    }

    private var subFilterItems: [NoticeSubFilterType] {
        [.all, .staff]
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Constants.hstackSpacing) {
                ForEach(subFilterItems) { filter in
                    filterChip(for: filter)
                }
                PartFilterMenu(viewModel: viewModel)
                    .equatable()
            }
            .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
        }
    }

    @ViewBuilder
    private func filterChip(for filter: NoticeSubFilterType) -> some View {
        ChipButton(
            filter.labelText,
            isSelected: viewModel.selectedSubFilter == filter
        ) {
            viewModel.selectSubFilter(filter)
        }
        .buttonSize(.medium)
    }
}

// MARK: - PartFilterMenu
/// 파트 선택 메뉴
private struct PartFilterMenu: View, Equatable {

    @Bindable var viewModel: NoticeViewModel

    static func == (lhs: PartFilterMenu, rhs: PartFilterMenu) -> Bool {
        lhs.viewModel.selectedPart == rhs.viewModel.selectedPart
    }

    private enum Constants {
        static let hstackSpacing: CGFloat = 4
        static let chevronSize: CGFloat = 10
        static let chipPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
    }

    private var partBinding: Binding<NoticePart?> {
        Binding(
            get: { viewModel.selectedPart },
            set: { viewModel.selectPart($0) }
        )
    }

    var body: some View {
        Menu {
            partPicker
        } label: {
            menuLabel
        }
    }

    private var partPicker: some View {
        Picker("파트 선택", selection: partBinding) {
            Label("파트", systemImage: "person.2.fill")
                .tag(nil as NoticePart?)
            ForEach(NoticePart.allCases) { part in
                Label(part.displayName, systemImage: part.iconName)
                    .tag(Optional(part))
            }
        }
        .pickerStyle(.inline)
    }

    private var isPartSelected: Bool {
        viewModel.selectedPart != nil
    }

    private var menuLabel: some View {
        HStack(spacing: Constants.hstackSpacing) {
            Image(systemName: viewModel.selectedPart?.iconName ?? "person.2.fill")
                .appFont(.subheadline)
            Text(viewModel.selectedPart?.displayName ?? "파트")
                .appFont(.subheadlineEmphasis)
            Image(systemName: "chevron.down")
                .font(.system(size: Constants.chevronSize))
        }
        .foregroundStyle(isPartSelected ? .grey000 : .grey600)
        .padding(Constants.chipPadding)
        .clipShape(Capsule())
        .background {
            Capsule()
                .fill(isPartSelected ? .indigo500 : .grey200)
        }
        .glassEffect(.clear.interactive(), in: Capsule())
    }
}
