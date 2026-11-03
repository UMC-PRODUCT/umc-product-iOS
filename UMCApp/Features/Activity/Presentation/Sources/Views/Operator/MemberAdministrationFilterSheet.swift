// Created by euijjang97 on 11/3/26.
import ActivityDomain
import CoreDesignSystem
import SwiftUI
import UMCFoundation

/// 조회 범위는 권한에 맞는 선택지만 제공하며, 변경한 조건은 즉시 검색에 반영합니다.
struct MemberAdministrationFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let viewModel: MemberAdministrationViewModel

    var body: some View {
        NavigationStack {
            Form {
                if !viewModel.generations.isEmpty {
                    Section("조회 범위") {
                        optionRow("기수", options: viewModel.generations, selection: generation)
                        if viewModel.filterOptionsState == .ready {
                            organizationRows
                        }
                    }
                }
                switch viewModel.filterOptionsState {
                case .loading:
                    ProgressView(viewModel.generations.isEmpty ? "기수를 불러오는 중…" : "학교와 지부를 불러오는 중…")
                case .failed(let error):
                    retrySection(
                        viewModel.generations.isEmpty ? "조회 범위를 불러올 수 없어요" : "학교와 지부를 불러올 수 없어요",
                        reason: error.userMessage
                    )
                case .ready:
                    Section {
                        Picker("파트", selection: part) {
                            Text("전체 파트").tag(String?.none)
                            ForEach(UMCPartType.allCases.filter { $0 != .admin }, id: \.apiValue) {
                                Text($0.name).tag(Optional($0.apiValue))
                            }
                        }
                    } footer: {
                        Text("조건을 바꾸면 멤버 목록에 바로 반영돼요.")
                    }
                    if viewModel.canResetFilters {
                        Button("필터 초기화", systemImage: "arrow.counterclockwise") {
                            Task { await viewModel.resetFilters() }
                        }
                    }
                    if let error = viewModel.searchError {
                        retrySection("멤버 목록을 불러올 수 없어요", reason: error.userMessage)
                    } else if viewModel.isLoading {
                        ProgressView("멤버를 찾는 중…")
                    }
                }
            }
            .navigationTitle("멤버 필터")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents(detents)
        .presentationDragIndicator(.visible)
    }

    private var detents: Set<PresentationDetent> {
        if dynamicTypeSize.isAccessibilitySize { return [.large] }
        if viewModel.generations.isEmpty { return [.height(DefaultSpacing.spacing288), .large] }
        return [.medium, .large]
    }

    @ViewBuilder
    private var organizationRows: some View {
        if !viewModel.availableChapters.isEmpty {
            optionRow("지부", options: viewModel.availableChapters,
                      all: viewModel.canSelectAllChapters ? "전체 지부" : nil, selection: chapter)
        }
        optionRow("학교", options: viewModel.availableSchools,
                  all: viewModel.canSelectAllSchools ? "전체 학교" : nil, selection: school)
    }

    @ViewBuilder
    private func optionRow(_ title: String, options: [MemberFilterOption],
                           all: String? = nil, selection: Binding<String?>) -> some View {
        if options.isEmpty {
            LabeledContent(title, value: all ?? "선택할 항목 없음")
        } else if options.count == 1, all == nil, let only = options.first {
            LabeledContent(title, value: only.name)
        } else {
            Picker(title, selection: selection) {
                if let all { Text(all).tag(String?.none) }
                ForEach(options) { Text($0.name).tag(Optional($0.id)) }
            }
        }
    }

    private func retrySection(_ title: String, reason: String) -> some View {
        Section {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text(title).font(.headline)
                Text(reason).font(.subheadline).foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Button {
                Task { await viewModel.retry() }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
            }
        }
    }

    private var generation: Binding<String?> {
        Binding(get: { viewModel.filter.gisuId }, set: { id in
            guard let id, id != viewModel.filter.gisuId else { return }
            viewModel.filter.gisuId = id
            Task { await viewModel.changeGeneration() }
        })
    }

    private var chapter: Binding<String?> {
        Binding(get: { viewModel.filter.chapterId }, set: { id in
            guard id != viewModel.filter.chapterId else { return }
            viewModel.filter.chapterId = id
            viewModel.filter.schoolId = nil
            Task { await viewModel.search() }
        })
    }

    private var school: Binding<String?> {
        Binding(get: { viewModel.filter.schoolId }, set: { id in
            guard id != viewModel.filter.schoolId else { return }
            viewModel.filter.schoolId = id
            Task { await viewModel.search() }
        })
    }

    private var part: Binding<String?> {
        Binding(get: { viewModel.filter.part }, set: { value in
            guard value != viewModel.filter.part else { return }
            viewModel.filter.part = value
            Task { await viewModel.search() }
        })
    }
}
