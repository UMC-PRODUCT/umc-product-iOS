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
    @State var viewModel: CommunityFameViewModel?
    
    private var communityProvider: CommunityUseCaseProviding {
        di.resolve(UsecaseProviding.self).community
    }

    private enum Constants {
        static let weekPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
    }

    // MARK: - Body

    var body: some View {
        Group {
            if let vm = viewModel {
                switch vm.fameItems {
                case .idle, .loading:
                    ProgressView("명예의전당 로딩 중...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .loaded:
                    listSection(vm: vm)
                case .failed(let error):
                    ContentUnavailableView {
                        Label("로딩 실패", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text(error.localizedDescription)
                    } actions: {
                        Button("다시 시도") {
                            Task { await vm.fetchFameItems() }
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .task {
            if viewModel == nil {
                viewModel = CommunityFameViewModel(
                    fetchFameItemsUseCase: communityProvider.fetchFameItemsUseCase
                )
            }
            await viewModel?.fetchFameItems()
        }
        .toolbar {
            if let vm = viewModel {
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
}
