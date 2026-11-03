// Created by euijjang97 on 11/1/26.
import ActivityDomain
import CoreDesignSystem
import CoreDI
import CoreDomain
import CoreUIComponents
import SwiftUI
import UMCFoundation

/// 기수·조직 범위에 맞는 서버 검색과 상벌점 상세 진입을 제공합니다.
struct OperatorMemberManagementView: View {
    @State private var viewModel: MemberAdministrationViewModel
    @State private var showFilters = false
    @State private var searchText = ""

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.init(viewModel: MemberAdministrationViewModel(
            useCase: container.resolve(MemberAdministrationUseCaseProtocol.self),
            membersUseCase: container.resolve(FetchMembersUseCaseProtocol.self),
            session: container.resolve(UserSessionManager.self)
        ))
    }

    init(viewModel: MemberAdministrationViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        List {
            if viewModel.filterOptionsState == .ready || viewModel.generations.count > 1 {
                Section {
                    Button { showFilters = true } label: {
                        HStack(spacing: DefaultSpacing.spacing12) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .foregroundStyle(.tint)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                                Text("멤버 필터").font(.headline)
                                Text(viewModel.filterSummary).font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.footnote).foregroundStyle(.tertiary)
                                .accessibilityHidden(true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityElement(children: .combine)
                }
            }
            switch viewModel.filterOptionsState {
            case .loading:
                loadingRow("조회 범위를 확인하는 중…")
            case .failed(let reason):
                failureSection(
                    viewModel.generations.isEmpty ? "조회 범위를 불러올 수 없어요" : "조직을 불러올 수 없어요",
                    reason: reason
                )
            case .ready:
                if viewModel.isLoading {
                    loadingRow("멤버를 찾는 중…")
                } else if let error = viewModel.errorMessage {
                    failureSection("멤버 목록을 불러올 수 없어요", reason: error)
                } else if viewModel.members.isEmpty {
                    ContentUnavailableView(
                        "조회된 멤버가 없어요", systemImage: "person.2",
                        description: Text("현재 조회 범위에서 검색어나 필터를 변경해 보세요.")
                    )
                } else {
                    memberSection
                }
            }
        }
        .searchable(text: $searchText, prompt: "이름 또는 닉네임")
        .searchToolbarBehavior(.minimize)
        .task { await viewModel.load() }
        .task(id: searchText) {
            guard !searchText.isEmpty || !viewModel.filter.keyword.isEmpty else { return }
            do { try await Task.sleep(for: .milliseconds(300)) } catch { return }
            viewModel.filter.keyword = searchText
            await viewModel.search()
        }
        .refreshable { await viewModel.retry() }
        .sheet(isPresented: $showFilters) {
            MemberAdministrationFilterSheet(viewModel: viewModel)
        }
        .sheet(item: $viewModel.selectedMember) { member in
            MemberAdministrationDetailSheet(member: member, viewModel: viewModel)
        }
    }
    private func loadingRow(_ title: String) -> some View {
        ProgressView(title).frame(maxWidth: .infinity)
    }

    private func failureSection(_ title: String, reason: String) -> some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            Image(systemName: "exclamationmark.circle")
                .font(.title)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title).font(.headline)
            if !reason.isEmpty, reason != MemberAdministrationViewModel.genericErrorMessage {
                Text(reason).font(.subheadline).foregroundStyle(.secondary)
            }
            Button {
                Task { await viewModel.retry() }
            } label: {
                Label("다시 시도", systemImage: "arrow.clockwise")
                    .font(.body.weight(.medium))
                    .frame(minHeight: DefaultConstant.minimumTouchTarget)
            }
            .buttonStyle(.borderless)
            .labelStyle(.titleAndIcon)
            .tint(.teal700)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .padding(.vertical, DefaultSpacing.spacing24)
        .listRowBackground(Color.clear)
    }

    private var memberSection: some View {
        Section("멤버") {
            ForEach(viewModel.members) { item in
                Button { Task { await viewModel.select(item) } } label: {
                    MemberAdministrationRow(item: item)
                }
                .buttonStyle(.plain)
            }
            if viewModel.isLoadingNextPage {
                loadingRow("다음 멤버를 불러오는 중…")
            } else if viewModel.hasMore {
                if let reason = viewModel.nextPageError {
                    Text("다음 멤버를 불러올 수 없어요").font(.headline)
                    Text(reason).font(.subheadline).foregroundStyle(.secondary)
                }
                Button(viewModel.nextPageError == nil ? "더 불러오기" : "다음 페이지 다시 불러오기") {
                    Task { await viewModel.loadMore() }
                }
            }
        }
    }
}

private struct MemberAdministrationRow: View {
    let item: AdminMember
    private var member: MemberManagementItem { item.member }
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(alignment: .top, spacing: DefaultSpacing.spacing12) {
            MemberImagePresenter(memberManagementItem: member)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                Text([member.nickname, member.name].filter { !$0.isEmpty }.joined(separator: " / "))
                    .font(.headline)
                Text([member.school, member.generation].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.subheadline).foregroundStyle(.secondary)
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) { badges }
                } else {
                    FlowLayout(spacing: DefaultSpacing.spacing4) { badges }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DefaultSpacing.spacing4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var badges: some View {
        if member.part != .admin { MemberTag(part: member.part) }
        if member.infra && member.part.canHaveInfra {
            Text(UMCPartType.infraName).font(.caption)
        }
        if member.managementTeam != .challenger { MemberTag(role: member.managementTeam) }
    }
}
