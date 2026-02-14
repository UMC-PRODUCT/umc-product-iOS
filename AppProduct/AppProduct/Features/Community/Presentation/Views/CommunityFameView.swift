//
//  CommunityFameView.swift
//  AppProduct
//
//  Created by 김미주 on 1/23/26.
//

import SwiftUI

struct CommunityFameView: View {
    // MARK: - Properties
    
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) var errorHandler
    
    @State private var vm: CommunityFameViewModel

    private enum Constants {
        static let weekPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
        /// 실패 상태 문구
        static let failedTitle: String = "불러오지 못했어요"
        static let failedSystemImage: String = "exclamationmark.triangle"
        static let failedDescription: String = "목록을 불러오지 못했습니다. 잠시 후 다시 시도해주세요."
        /// 재시도 버튼 문구/크기
        static let retryTitle: String = "다시 시도"
        static let retryMinimumWidth: CGFloat = 72
        static let retryMinimumHeight: CGFloat = 20
    }
    
    // MARK: - Init
    
    init(container: DIContainer) {
        _vm = State(initialValue: CommunityFameViewModel(container: container))
    }
    
    // MARK: - Init
    
    init(container: DIContainer) {
        _vm = State(initialValue: CommunityFameViewModel(container: container))
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch vm.fameItems {
            case .idle, .loading:
                ProgressView("명예의전당 로딩 중...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                listSection(vm: vm)
            case .failed:
                failedContent()
            }
        }
        .task {
            #if DEBUG
            if let debugState = CommunityFameDebugState.fromLaunchArgument() {
                debugState.apply(to: vm)
                return
            }
            #endif

            await vm.fetchFameItems(query: .init(week: 1, school: nil, part: nil))
        }
        .toolbar {
            ToolBarCollection.CommunityWeekFilter(
                weeks: vm.availableWeeks,
                selection: Binding(
                    get: { vm.selectedWeek }, set: { vm.selectedWeek = $0 }
                )
            )
            
            ToolBarCollection.CommunityUnivFilter(
                selectedUniversity: Binding(
                    get: { vm.selectedUniversity }, set: { vm.selectedUniversity = $0 }
                ),
                universities: vm.availableUniversities
            )
            ToolBarCollection.CommunityPartFilter(
                selectedPart: Binding(
                    get: { vm.selectedPart }, set: { vm.selectedPart = $0 }
                ),
                parts: vm.availableParts
            )
        }
    }

    // MARK: - SubViews

    private func listSection(vm: CommunityFameViewModel) -> some View {
        Group {
            if vm.groupedByUniversity.isEmpty {
                emptyList
            } else {
                List {
                    ForEach(vm.groupedByUniversity, id: \.university) { group in
                        Section {
                            ForEach(group.items) { item in
                                CommunityFameItem(model: item) {
                                    // TODO: 보기 버튼 액션
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        } header: {
                            Text(group.university)
                                .appFont(.title3Emphasis, color: .black)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
    }

    private var emptyList: some View {
        ContentUnavailableView {
            Label("명예의 전당 목록이 없습니다.", systemImage: "text.page.slash")
        } description: {
            Text("매 주차가 종료되면 베스트 워크북이 선정됩니다.")
        }
    }
    
    /// Failed - 데이터 로드 실패
    private func failedContent() -> some View {
        RetryContentUnavailableView(
            title: Constants.failedTitle,
            systemImage: Constants.failedSystemImage,
            description: Constants.failedDescription,
            retryTitle: Constants.retryTitle,
            isRetrying: vm.fameItems.isLoading,
            minRetryButtonWidth: Constants.retryMinimumWidth,
            minRetryButtonHeight: Constants.retryMinimumHeight
        ) {
            await vm.fetchFameItems(query: .init(week: 1, school: nil, part: nil))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}
