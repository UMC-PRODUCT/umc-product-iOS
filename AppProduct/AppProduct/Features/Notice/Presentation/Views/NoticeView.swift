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
    @State var viewModel = NoticeViewModel()
    @State private var search: String = ""
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let listTopPadding: CGFloat = 10
    }

    // MARK: - Constants
    private enum Constants {
        static let listTopPadding: CGFloat = 10
        static let searchPlaceholder: String = "제목, 내용 검색"
    }
    // MARK: - Body
    var body: some View {
        Group {
            switch viewModel.noticeItems {
            case .idle:
                Color.clear.task {
                    print("API 함수")
                }
            case .loading:
                progressView
            case .loaded(let noticeItem):
                noticeCotent(noticeItem)
            case .failed(_):
                Color.clear
            }
        }
        .searchable(text: $search, prompt: Constants.searchPlaceholder)
        .searchToolbarBehavior(.minimize)
        .toolbar {
            ToolBarCollection.GenerationFilter(
                title: viewModel.selectedGeneration.title,
                generations: viewModel.generations,
                selection: $viewModel.selectedGeneration
            )
            ToolBarCollection.TopBarCenterMenu(
                      icon: viewModel.selectedNoticeMainFilter.labelIcon,
                      title: viewModel.selectedNoticeMainFilter.labelText,
                      items: viewModel.mainFilterItems,
                      selection: $viewModel.selectedNoticeMainFilter,
                      itemLabel: { $0.labelText },
                      itemIcon: { $0.labelIcon }
                  )
        }
        .safeAreaBar(edge: .top) {
            if showSubFilter {
                NoticeSubFilter(viewModel: viewModel)
                    .equatable()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: -
    private var progressView: some View {
        ProgressView(label: {
            Text("공지를 불러오고 있어요")
                .appFont(.callout)
        })
        .controlSize(.large)
        .tint(.indigo500)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: -
    @ViewBuilder
    private func noticeCotent(_ data: [NoticeItemModel]) -> some View {
        if data.isEmpty {
            unavailableContent
        } else {
            availableContent(data)
        }
    }
    
    // MARK: -
    private func availableContent(_ data: [NoticeItemModel]) -> some View {
        List(data) { item in
            NoticeItem(model: item)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(DefaultConstant.defaultListPadding)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    // MARK: -
    private var unavailableContent: some View {
        ContentUnavailableView(
            "아직 등록된 공지사항이 없어요",
            systemImage: "exclamationmark.triangle.text.page",
            description: Text("운영진이 공지사항을 등록하면 이곳에 표시됩니다")
        )
        .tint(.indigo200.opacity(0.5))
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

    @Bindable var viewModel = NoticeViewModel()

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

    @Bindable var viewModel = NoticeViewModel()

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

    /// 파트가 실제로 선택되었는지 (기본값 "파트"가 아닌 경우)
    private var isPartSelected: Bool {
        viewModel.selectedPart != .all && viewModel.selectedPart != nil
    }
    
    /// 메뉴 라벨
    private var menuLabel: some View {
        HStack(spacing: Constants.hstackSpacing) {
            Text(viewModel.selectedPart?.name ?? "파트")
                .appFont(.subheadline, weight: .bold)
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

// MARK: - Preview
#Preview("Loading") {
    NavigationStack {
        NoticeView(viewModel: {
            let vm = NoticeViewModel()
            vm.noticeItems = .loading
            return vm
        }())
    }
}

#Preview("Loaded - 데이터 있음") {
    NavigationStack {
        NoticeView(viewModel: {
            let vm = NoticeViewModel()
            vm.noticeItems = .loaded([
                NoticeItemModel(generation: 9, tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "2026년도 UMC 신년회 안내", content: "안녕하세요! UMC 너드 및 챌린저 여러분 안녕하세요! 회장 웰시입니다! 신년회까지 어느덧 몇 주 남지 않았습니다 🥳 오늘은 신년회에 앞서 몇 가지 전달드릴 사항이 있어 공지드립니다.", writer: "웰시/최지은", hasLink: true, hasVote: false, viewCount: 32),
                NoticeItemModel(generation: 9, tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "9기 스터디 후기 이벤트 리마인드", content: "9기 가천대 UMC 챌린저 여러분 안녕하세요. 나나입니다! 아직 9기 스터디 후기를 작성하지 않으신 분들께 리마인드 안내드립니다!", writer: "나나/이예나", hasLink: true, hasVote: false, viewCount: 48),
                NoticeItemModel(generation: 9, tag: .central, mustRead: true, isAlert: true, date: Date(), title: "UMC 9기 ✨Demo Day✨ 안내", content: "안녕하세요, UMC 9기 챌린저 여러분! 총괄 챗챗입니다~", writer: "쳇쳇/전채운", hasLink: false, hasVote: false, viewCount: 123),
                NoticeItemModel(generation: 9, tag: .part(.ios), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️ 10주차 워크북 배포가 완료되었습니다! 10주차는 정규 워크북만 있습니다! 10주차는 iOS 워크북 ‼️최초로‼️ 부담 하나 없이 30분안에 끝낼 수 있는 개념과 과제입니다!", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
                NoticeItemModel(generation: 10, tag: .part(.ios), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! UMC 10기 iOS 챌린저 여러분! 중앙파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 98),
                NoticeItemModel(generation: 10, tag: .part(.android), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! Android 챌린저 여러분! 리암입니다.🌪️ 다들 지금까지의 워크북은 잘 익히셨나요?? 7, 8주차 워크북은 본격적으로 DB에 대해 탐구해보는 워크북입니다.", writer: "리암/조성준", hasLink: false, hasVote: false, viewCount: 6),
                NoticeItemModel(generation: 9, tag: .part(.nodejs), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! Node 챌린저 여러분! 옌찌입니다.👻 10주차 스터디가 이번주로 다들 끝나네요! 다들 너무 수고 많으셨어요!", writer: "옌찌/장예은", hasLink: false, hasVote: false, viewCount: 8),
                NoticeItemModel(generation: 9, tag: .part(.springboot), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요 노을입니다 💛 ❗❗ 8주차 피드백 완료되었고, Infra 워크북 2개와 부록 하나가 추가되었습니다 ❗❗이제 각자 PR에 리뷰가 즉각 반영되었을겁니다..ㅎㅎ", writer: "노을/노창준", hasLink: false, hasVote: false, viewCount: 12)
            ])
            return vm
        }())
    }
}

#Preview("Loaded - 빈 데이터") {
    NavigationStack {
        NoticeView(viewModel: {
            let vm = NoticeViewModel()
            vm.noticeItems = .loaded([])
            return vm
        }())
    }
}
