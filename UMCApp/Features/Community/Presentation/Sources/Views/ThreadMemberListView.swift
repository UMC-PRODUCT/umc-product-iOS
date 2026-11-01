//
//  ThreadMemberListView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/13/26.
//

import SwiftUI
import ActivityPresentation
import CommunityDomain
import CoreDI
import CoreDomain
import CoreDesignSystem
import CoreRouting
import CoreUIComponents
import UMCFoundation

// MARK: - Constants

fileprivate enum Constants {
    static let loadFailureTitle = "참여자를 불러오지 못했어요"
}

/// 스레드 참여자 목록.
///
/// 개설자·관리자에게 행 ⋯ 메뉴가 열린다(개설자 위임은 개설자만). 위임 전용 화면을 따로 두지 않고
/// 이 메뉴 하나로 처리한다 (#1131 결정 2).
struct ThreadMemberListView: View {

    // MARK: - Property

    @State private var viewModel: ThreadMemberListViewModel
    @State private var inviteViewModel: ThreadInviteViewModel

    /// 나가기·삭제가 끝났을 때 리스트 화면에 알린다. 실시간 `member.left`/`thread.deleted` 로도
    /// 행이 지워지지만, 그걸 기다리면 루트로 돌아온 직후 잠깐 남아 있는 행이 보인다.
    private let onRemoved: () -> Void

    @Environment(PathStore.self) private var pathStore
    @Environment(\.di) private var container
    @State private var profileMember: ThreadMember?

    @State private var isInviteSheetPresented = false

    // MARK: - Init

    init(
        viewModel: ThreadMemberListViewModel,
        inviteViewModel: ThreadInviteViewModel,
        onRemoved: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel)
        _inviteViewModel = State(initialValue: inviteViewModel)
        self.onRemoved = onRemoved
    }

    // MARK: - Body

    var body: some View {
        content
            .navigationTitle("참여자")
            .navigationBarTitleDisplayMode(.inline)
            .umcDefaultBackground()
            .searchable(text: $viewModel.searchText, prompt: "이름 검색")
            .safeAreaInset(edge: .bottom) {
                if viewModel.isSelecting { selectionBar }
            }
            .toolbar {
                if viewModel.canInvite {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(viewModel.isSelecting ? "선택 해제" : "선택") {
                            viewModel.toggleSelectionMode()
                        }
                        .disabled(viewModel.isManaging)
                    }
                    ToolbarItem(placement: .topBarTrailing) { inviteButton }
                }
                ToolbarItem(placement: .topBarTrailing) { leaveButton }
            }
            .alertPrompt(item: $viewModel.alertPrompt)
            .alertPrompt(item: $inviteViewModel.alertPrompt)
            // 선택 화면에 전송 버튼이 없어 닫을 때 초대한다 (`ThreadInviteViewModel` 참고).
            .sheet(isPresented: $isInviteSheetPresented, onDismiss: invite) {
                SelectedChallengerView(
                    challenger: $inviteViewModel.invitees,
                    selectableMemberIds: inviteViewModel.invitableMemberIds
                )
                .presentationDragIndicator(.visible)
                .task { await inviteViewModel.loadInvitableMembers() }
            }
            .sheet(item: $profileMember) { member in
                MemberSafetyProfileView(
                    memberId: member.id,
                    name: member.name,
                    currentMemberId: viewModel.currentMemberId,
                    store: container.resolve(MemberBlockStore.self)
                )
            }
            .task { await viewModel.load() }
            .onChange(of: viewModel.didLeave) { _, didLeave in
                guard didLeave else { return }
                onRemoved()
                // 방까지 함께 접어야 한다 — 한 단계만 pop 하면 이미 나온 스레드의 채팅방이 남는다.
                pathStore[.community] = NavigationPath()
            }
    }

    // MARK: - View Component

    /// 초대 진입점. 개설자·관리자에게 열린다 (#1136 완료 조건 1 · 시안 #36 상단 "초대").
    private var inviteButton: some View {
        Button("초대") { isInviteSheetPresented = true }
            .disabled(viewModel.isManaging || viewModel.isSelecting)
    }

    /// 나가기. 개설자는 위임 전까지 잠기고, 그 사유는 참여자 섹션 footer 로 붙인다 (#1131 결정 2).
    private var leaveButton: some View {
        Button(role: .destructive) {
            viewModel.confirmLeave()
        } label: {
            // 툴바에서는 아이콘만 보이고, 제목은 VoiceOver 라벨로 읽힌다.
            Label("스레드 나가기", systemImage: "door.left.hand.open")
        }
        .tint(.red)
        .disabled(!viewModel.canLeave || viewModel.isManaging)
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded:
            memberList(viewModel.filteredMembers)

        case .failed(let error):
            RetryContentUnavailableView(
                title: Constants.loadFailureTitle,
                systemImage: "exclamationmark.triangle",
                description: error.userMessage,
                isRetrying: false,
                error: error
            ) {
                await viewModel.load()
            }
        }
    }

    private func memberList(_ members: [ThreadMember]) -> some View {
        List {
            Section {
                ForEach(members) { member in
                    HStack {
                        if viewModel.isSelecting {
                            Button {
                                viewModel.toggleSelection(member)
                            } label: {
                                Image(systemName: viewModel.selectedMemberIds.contains(member.id)
                                      ? "checkmark.circle.fill" : "circle")
                                    .frame(
                                        width: DefaultConstant.minimumTouchTarget,
                                        height: DefaultConstant.minimumTouchTarget
                                    )
                            }
                            .buttonStyle(.borderless)
                            .disabled(!viewModel.canKick(member) || viewModel.isManaging)
                            .accessibilityLabel("\(member.name) 선택")
                            .accessibilityValue(
                                viewModel.selectedMemberIds.contains(member.id) ? "선택됨" : "선택 안 됨"
                            )
                        }
                        ThreadMemberRow(
                            member: member,
                            isMe: viewModel.isMe(member),
                            canTransferOwnership: !viewModel.isSelecting
                                && viewModel.canTransferOwnership(to: member),
                            canKick: !viewModel.isSelecting && viewModel.canKick(member),
                            onTransferOwnership: {
                                viewModel.confirmTransferOwnership(to: member)
                            },
                            onKick: { viewModel.confirmKick(member) },
                            onOpenProfile: viewModel.isSelecting ? nil : { profileMember = member }
                        )
                        .disabled(viewModel.isManaging)
                    }
                }
            } header: {
                Text("참여자 \(viewModel.members.count)명")
            } footer: {
                if let reason = viewModel.leaveBlockReason {
                    Text(reason)
                        .appFont(.caption1, color: .grey600)
                }
            }

            if members.isEmpty {
                ContentUnavailableView.search(text: viewModel.searchText)
            }
            if let message = viewModel.operationMessage {
                Section {
                    Text(message)
                        .appFont(.footnote, color: .grey600)
                        .accessibilityAddTraits(.updatesFrequently)
                }
            }
            if viewModel.canDeleteThread && !viewModel.isSelecting {
                deleteSection
            }
        }
        .listStyle(.insetGrouped)
        .refreshable { await viewModel.load() }
    }

    private var selectionBar: some View {
        HStack {
            Text("\(viewModel.selectedMemberIds.count)명 선택")
                .appFont(.subheadline, weight: .semibold)
            Spacer()
            if viewModel.isManaging {
                ProgressView()
                    .accessibilityLabel("참여자 관리 중")
            } else {
                Menu("관리", systemImage: "person.badge.key") {
                    if viewModel.canPromoteSelection {
                        Button("관리자 지정", systemImage: "person.badge.key") {
                            viewModel.confirmSelection(.promote)
                        }
                    }
                    if viewModel.canDemoteSelection {
                        Button("관리자 해제", systemImage: "person") {
                            viewModel.confirmSelection(.demote)
                        }
                    }
                    Button("내보내기", systemImage: "person.fill.xmark", role: .destructive) {
                        viewModel.confirmSelection(.kick)
                    }
                }
                .disabled(!viewModel.canManageSelection)
                .buttonStyle(.glass)
            }
        }
        .padding(DefaultSpacing.spacing16)
        .background(.bar)
    }

    /// 위임할 상대조차 없는 개설자의 출구 — 안내만 남기면 막다른 길이 된다 (#1134).
    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.confirmDeleteThread()
            } label: {
                // 색만으로 구분하지 않도록 휴지통 아이콘을 함께 둔다.
                Label("스레드 삭제", systemImage: "trash")
            }
        }
    }

    // MARK: - Function

    private func invite() {
        Task {
            guard await inviteViewModel.invite() != nil else { return }
            // 초대한 쪽에는 실시간 이벤트가 오지 않아 목록을 직접 다시 읽는다.
            await viewModel.load()
        }
    }
}
