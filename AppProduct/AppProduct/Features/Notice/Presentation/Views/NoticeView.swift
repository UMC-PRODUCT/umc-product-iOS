//
//  NoticeView.swift
//  AppProduct
//
//  Created by 이예지 on 1/14/26.
//

import SwiftUI

// MARK: - NoticeView
/// 공지사항 메인 화면
struct NoticeView: View {

    // MARK: - Properties
    @State var viewModel: NoticeViewModel
    @State private var search: String = ""

    private enum Constants {
        static let searchPlaceholder: String = "제목, 내용 검색"
    }

    // MARK: - Body
    var body: some View {
        List(viewModel.noticeItems) { item in
            NoticeItem(model: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(DefaultConstant.defaultListPadding)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .searchable(text: $search, prompt: Constants.searchPlaceholder)
        .searchToolbarBehavior(.minimize)
        .toolbar {
            ToolBarCollection.GenerationFilter(viewModel: viewModel)
            ToolBarCollection.NoticeMainFilter(viewModel: viewModel)
        }
        .safeAreaBar(edge: .top) {
            if showSubFilter {
                NoticeSubFilter(viewModel: viewModel)
                    .equatable()
                    .padding(.vertical, 8)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Computed Properties
    /// 서브필터 표시 여부 (중앙/지부/학교일 때만 표시)
    private var showSubFilter: Bool {
        switch viewModel.selectedNoticeMainFilter {
        case .all, .part: return false
        case .central, .branch, .school: return true
        }
    }
}



// MARK: - NoticeSubFilter
/// 서브필터 영역 (전체, 운영진 공지 칩 + 파트 메뉴)
private struct NoticeSubFilter: View, Equatable {

    @Bindable var viewModel: NoticeViewModel

    static func == (lhs: NoticeSubFilter, rhs: NoticeSubFilter) -> Bool {
        lhs.viewModel.selectedNoticeSubFilter == rhs.viewModel.selectedNoticeSubFilter &&
        lhs.viewModel.selectedPart == rhs.viewModel.selectedPart
    }

    private enum Constants {
        static let hstackSpacing: CGFloat = 8
    }

    private var subFilterItems: [NoticeSubFilterType] {
        [.all, .management]
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

    /// 칩버튼 생성
    @ViewBuilder
    private func filterChip(for filter: NoticeSubFilterType) -> some View {
        ChipButton(
            filter.labelText,
            isSelected: viewModel.selectedNoticeSubFilter == filter
        ) {
            viewModel.selectedNoticeSubFilter = filter
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

    var body: some View {
        Menu {
            partPicker
        } label: {
            menuLabel
        }
    }

    /// 파트 Picker
    private var partPicker: some View {
        Picker("파트 선택", selection: $viewModel.selectedPart) {
            ForEach(Part.allCases) { part in
                Text(part.name)
                    .tag(part as Part?)
            }
        }
        .pickerStyle(.inline)
    }

    /// 메뉴 라벨
    private var menuLabel: some View {
        HStack(spacing: Constants.hstackSpacing) {
            Text(viewModel.selectedPart?.name ?? "파트")
                .appFont(.subheadline, weight: .bold)
            Image(systemName: "chevron.down")
                .font(.system(size: Constants.chevronSize))
        }
        .foregroundStyle(.grey600)
        .padding(Constants.chipPadding)
        .background {
            Capsule()
                .fill(.grey200)
        }
        .glassEffect(.regular, in: Capsule())
    }
}

// MARK: - Preview
extension NoticeViewModel {
    /// Preview용 Mock 데이터
    static let mock: NoticeViewModel = {
        let vm = NoticeViewModel()
        vm.configure(
            generations: (8...12).map { Generation(value: $0) },
            current: Generation(value: 9)
        )
        return vm
    }()
}

#Preview {
    NoticeView(viewModel: .mock)
}
