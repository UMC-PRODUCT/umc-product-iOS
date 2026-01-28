//
//  CommunityFameView.swift
//  AppProduct
//
//  Created by 김미주 on 1/23/26.
//

import SwiftUI

struct CommunityFameView: View {
    // MARK: - Properties

    @State var vm: CommunityFameViewModel

    private enum Constants {
        static let weekPadding: EdgeInsets = .init(top: 0, leading: 16, bottom: 0, trailing: 16)
    }

    // MARK: - Init

    init() {
        self._vm = .init(wrappedValue: .init())
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch vm.fameItems {
            case .idle:
                Color.clear.task {
                    print("hello")
                }
            case .loading:
                ProgressView()
            case .loaded:
                listSection
            case .failed:
                Color.clear
            }
        }
        .toolbar {
            ToolBarCollection.CommunityWeekFilter(
                weeks: vm.availableWeeks,
                selection: $vm.selectedWeek
            )
            ToolBarCollection.CommunityFilter(
                selectedUniversity: $vm.selectedUniversity,
                selectedPart: $vm.selectedPart,
                universities: vm.availableUniversities,
                parts: vm.availableParts
            )
        }
    }

    // MARK: - Section

    private var weekSection: some View {
        ScrollView(.horizontal) {
            HStack(spacing: DefaultSpacing.spacing8) {
                ForEach(vm.availableWeeks, id: \.self) { week in
                    ChipButton("\(week)주차", isSelected: vm.selectedWeek == week) {
                        vm.selectWeek(week)
                    }
                    .buttonStyle(.fame)
                }
            }
            .padding(Constants.weekPadding)
        }
        .scrollIndicators(.hidden)
    }

    private var listSection: some View {
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

#Preview {
    CommunityFameView()
}
