//
//  CommunityFeatureView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 3/6/26.
//

import SwiftUI
import UIKit

import CommunityDomain
import CoreDesignSystem
import CoreDI
import CoreRouting
import CoreUIComponents
import NoticeDomain
import UMCFoundation

/// 커뮤니티 탭 진입점.
///
/// 목록과 상세의 네이티브 분할 화면을 소유하며, 상세 경로는 App의 `PathStore`를 공유한다.
/// App 소유 목적지는 `detailRoot` 빌더가 스택 루트에 등록해 Feature 역방향 의존을 만들지 않는다.
public struct CommunityFeatureView<DetailRoot: View>: View {

    // MARK: - Property

    /// 공지 링크 카드 탭. 공지 상세 목적지는 App 소유(`NavigationDestination`)라 Feature 가
    /// 직접 push 할 수 없다 — 홈 탭이 쓰는 콜백 방식을 그대로 따른다 (#1027).
    private let onNoticeSelected: (NoticeDetail) -> Void
    private let detailRoot: (AnyView) -> DetailRoot

    @Environment(PathStore.self) private var pathStore
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) private var errorHandler

    // MARK: - Init

    public init(
        onNoticeSelected: @escaping (NoticeDetail) -> Void,
        @ViewBuilder detailRoot: @escaping (AnyView) -> DetailRoot
    ) {
        self.onNoticeSelected = onNoticeSelected
        self.detailRoot = detailRoot
    }

    // MARK: - Body

    public var body: some View {
        CommunitySplitContent(
            viewModel: CommunityThreadListViewModel(
                listUseCase: di.resolve(CommunityThreadListUseCaseProtocol.self),
                roomUseCase: di.resolve(CommunityThreadRoomUseCaseProtocol.self),
                errorHandler: errorHandler,
                blockState: di.resolve(CommunityMemberBlockState.self)
            ),
            detailRoot: detailRoot
        )
        // 메시지 본문의 텍스트 링크와 링크 카드가 모두 `openURL` 로 들어온다. 여기 한 번만
        // 가로채면 두 경로가 같은 규칙을 타고, 외부 URL 은 손대지 않은 채 사파리로 나간다.
        .environment(\.openURL, OpenURLAction(handler: handle))
    }

    // MARK: - Function

    private func handle(_ url: URL) -> OpenURLAction.Result {
        guard let link = MessageLink.parse(url) else { return .systemAction }
        open(link)
        return .handled
    }

    /// - Note: 스레드는 제목을 모른 채 push 한다. 채팅방이 헤더를 받으면 principal 툴바가
    ///   `navigationTitle` 을 덮으므로, 비어 있는 건 로딩 동안뿐이다.
    /// - Note: 비멤버 차단은 여기서 하지 않는다. 리스트 탭·딥링크·링크 카드가 모두 같은
    ///   채팅방으로 모이므로 게이트는 그 안(`CommunityThreadRoomViewModel.load()`)에 둔다.
    private func open(_ link: MessageLink) {
        switch link {
        case .thread(let id):
            pathStore.push(
                CommunityDestination.threadRoom(threadId: id, title: ""),
                on: .community
            )

        case .notice:
            Task { await openNotice(link) }
        }
    }

    /// 공지 상세 목적지가 모델을 통째로 받으므로, 카드가 이미 받아 둔 메타를 다시 꺼내 쓴다.
    /// UseCase 가 링크별로 캐시하고 있어 카드가 떠 있는 상태에서의 탭은 네트워크를 타지 않는다.
    private func openNotice(_ link: MessageLink) async {
        do {
            let preview = try await di
                .resolve(MessageLinkPreviewUseCaseProtocol.self)
                .preview(for: link)
            guard let notice = preview.notice else { return }
            onNoticeSelected(notice)
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "openNoticeLink"
            ))
        }
    }
}

/// 크기 변화와 무관하게 목록·상세 스택을 같은 위치에 유지한다.
private struct CommunitySplitContent<DetailRoot: View>: View {
    @State private var viewModel: CommunityThreadListViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var selectedRoom: CommunityDestination?
    @State private var hasComposerChanges = false
    @State private var pendingThread: CommunityThread?
    @Environment(PathStore.self) private var pathStore
    @Environment(\.di) private var di
    @Environment(ErrorHandler.self) private var errorHandler
    let detailRoot: (AnyView) -> DetailRoot
    // iPhone은 목록을 루트로 둔 단일 스택이라 채팅방에서 한 번의 뒤로 가기로 목록에 복귀한다.
    // 접힌 분할 화면은 목록과 채팅방 사이에 상세 열의 빈 안내 화면을 끼워 넣는다 (#1683).
    // 회전 중 스택 종류를 바꾸면 초안·실시간 구독이 끊기므로 크기 클래스로 분기하지 않는다.
    // 마이페이지(#1658)와 같은 임시 기준이다. 선택을 상세 열 루트로 두는 전환은 #1686.
    private let usesSplitNavigation = UIDevice.current.userInterfaceIdiom != .phone

    init(
        viewModel: CommunityThreadListViewModel,
        @ViewBuilder detailRoot: @escaping (AnyView) -> DetailRoot
    ) {
        _viewModel = State(initialValue: viewModel)
        self.detailRoot = detailRoot
    }

    var body: some View {
        Group {
            if usesSplitNavigation {
                splitContent
            } else {
                navigationStack(root: threadList)
            }
        }
        .onChange(of: pathStore.depth(of: .community), initial: true) { _, depth in
            compactColumn = depth == 0 ? .sidebar : .detail
            if depth == 0 {
                selectedRoom = nil
                hasComposerChanges = false
            }
        }
        .confirmationDialog(
            "작성 중인 메시지를 지우고 다른 스레드로 이동할까요?",
            isPresented: Binding(
                get: { pendingThread != nil },
                set: { if !$0 { pendingThread = nil } }
            ),
            titleVisibility: .visible
        ) {
            if let thread = pendingThread {
                Button("지우고 이동", role: .destructive) { openThread(thread) }
            }
            Button("계속 작성", role: .cancel) { pendingThread = nil }
        }
    }

    private var splitContent: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $compactColumn
        ) {
            threadList
                .disabled(!canSelectThread)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            navigationStack(root: emptyDetail)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: horizontalSizeClass) { _, sizeClass in
            if sizeClass == .regular { columnVisibility = .all }
        }
    }

    private var threadList: some View {
        CommunityThreadListView(
            viewModel: viewModel,
            selectedThreadID: selectedThreadID,
            onThreadSelected: selectThread
        )
    }

    /// 분할 화면에서 아직 스레드를 고르지 않은 상세 열.
    private var emptyDetail: some View {
        ContentUnavailableView(
            "스레드를 선택해 주세요",
            systemImage: "bubble.left.and.bubble.right",
            description: Text("목록에서 스레드를 선택하면 대화를 확인할 수 있어요.")
        )
        .navigationTitle("커뮤니티")
        .background(
            (horizontalSizeClass == .regular ? Color.Surface.content : Color.Surface.canvas)
                .ignoresSafeArea()
        )
    }

    private func navigationStack<Root: View>(root: Root) -> some View {
        NavigationStack(path: Binding(
            get: { pathStore[.community] },
            set: { pathStore[.community] = $0 }
        )) {
            detailRoot(AnyView(root))
                .navigationDestination(for: CommunityDestination.self) { destination in
                    CommunityRoutingView(
                        destination: destination,
                        container: di,
                        errorHandler: errorHandler,
                        onThreadCreated: { viewModel.insertCreated($0) },
                        onThreadUpdated: { viewModel.applyUpdated($0) },
                        onThreadRemoved: { viewModel.removeThread(threadId: $0) },
                        onThreadToggled: { viewModel.applyToggles($0) },
                        onComposerChange: { hasComposerChanges = $0 }
                    )
                    .onAppear {
                        if case .threadRoom = destination { selectedRoom = destination }
                    }
                }
        }
    }

    private var selectedThreadID: String? {
        guard let selectedRoom, case .threadRoom(let threadID, _) = selectedRoom else { return nil }
        return threadID
    }

    private var canSelectThread: Bool {
        CommunitySplitSelection.canReplaceRoom(
            path: pathStore[.community], selectedRoom: selectedRoom
        )
    }

    private func selectThread(_ thread: CommunityThread) {
        guard canSelectThread else { return }
        if let selectedRoom, case .threadRoom(let selectedID, _) = selectedRoom,
           selectedID == thread.id {
            viewModel.markThreadRead(threadId: thread.id)
            viewModel.recordCurrentSearch()
            compactColumn = .detail
        } else if hasComposerChanges {
            pendingThread = thread
        } else {
            openThread(thread)
        }
    }

    private func openThread(_ thread: CommunityThread) {
        guard canSelectThread else { return }
        let destination = CommunityDestination.threadRoom(threadId: thread.id, title: thread.title)
        var path = NavigationPath()
        path.append(destination)
        viewModel.markThreadRead(threadId: thread.id)
        viewModel.recordCurrentSearch()
        hasComposerChanges = false
        selectedRoom = destination
        pathStore[.community] = path
        pendingThread = nil
        compactColumn = .detail
    }
}

/// 사이드바에서 교체할 수 있는 경로를 단일 채팅방으로 제한한다.
enum CommunitySplitSelection {
    /// 생성·편집·멤버 목록·링크로 쌓인 상세는 사이드바 선택으로 제거하지 않는다.
    static func canReplaceRoom(
        path: NavigationPath, selectedRoom: CommunityDestination?
    ) -> Bool {
        guard !path.isEmpty else { return true }
        guard let selectedRoom else { return false }
        var expected = NavigationPath()
        expected.append(selectedRoom)
        return path == expected
    }

}
