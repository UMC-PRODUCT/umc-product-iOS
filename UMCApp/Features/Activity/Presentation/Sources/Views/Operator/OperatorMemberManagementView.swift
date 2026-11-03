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
        _viewModel = State(initialValue: MemberAdministrationViewModel(
            useCase: container.resolve(MemberAdministrationUseCaseProtocol.self),
            membersUseCase: container.resolve(FetchMembersUseCaseProtocol.self),
            session: container.resolve(UserSessionManager.self)
        ))
    }

    var body: some View {
        List {
            Section {
                Button { showFilters = true } label: {
                    Label("기수·지부·학교·파트 필터", systemImage: "line.3.horizontal.decrease")
                }
                if let generation = viewModel.generations.first(where: { $0.id == viewModel.filter.gisuId }) {
                    Text(generation.name)
                        .appFont(.footnote, color: .grey500)
                }
            }
            if viewModel.isLoading {
                ProgressView("멤버를 불러오는 중…")
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.Surface.content)
            } else if let error = viewModel.errorMessage, viewModel.members.isEmpty {
                Section {
                    Text(error).appFont(.subheadline)
                    Button("다시 시도") { Task { await viewModel.retry() } }
                }
            } else if viewModel.members.isEmpty {
                ContentUnavailableView("멤버가 없습니다", systemImage: "person.3",
                                       description: Text("검색어나 필터를 변경해 보세요."))
            } else {
                Section("멤버") {
                    ForEach(viewModel.members) { item in
                        Button { Task { await viewModel.select(item) } } label: {
                            MemberAdministrationRow(item: item)
                        }
                    }
                    if viewModel.isLoadingNextPage {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Button("더 불러오기") { Task { await viewModel.loadMore() } }
                            .disabled(!viewModel.hasMore)
                    }
                    if let error = viewModel.errorMessage {
                        Text(error).appFont(.footnote, color: .red)
                    }
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
}

private struct MemberAdministrationRow: View {
    let item: AdminMember
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            CoreMemberManagementRow(memberManagementItem: item.member)
            Text("\(item.member.school) · \(item.member.generation)")
                .appFont(.footnote, color: .grey500)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, DefaultSpacing.spacing4)
    }
}
