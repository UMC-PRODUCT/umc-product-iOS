//
//  MyPageFeatureView.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 3/6/26.
//

import CoreDI
import CoreRouting
import CoreUIComponents
import SwiftUI
import UIKit

/// 마이페이지가 요청하는 명함 진입 지점.
///
/// MyPage는 ``BusinessCardDestination``(BusinessCardPresentation 소유 목적지 enum)을 직접
/// 참조하지 않는다 — 목적지 타입까지 그 모듈에 결합시키면 App 셸의 중개 없이 Feature가
/// 서로의 네비게이션을 직접 다루게 된다. 그래서 이 중립 enum을 MyPage가 소유하고,
/// App 셸이 이를 `BusinessCardDestination`으로 번역해 탭 스택에 쌓는다.
/// (명함 카드 UI 자체는 `BusinessCardFaceView`를 재사용하므로 BusinessCardPresentation을
/// import하지만, 그건 화면 조립이지 네비게이션 결합이 아니다.)
///
/// 내 정보 편집은 여기 없다 — 프로필 스냅샷이 필요해 App 셸 번역이 부적합하므로, MyPage 내부에서
/// `MyPageDestination.cardEdit(profileData:)`로 직접 push한다.
public enum BusinessCardEntry: Hashable, Sendable {
    /// 명함첩 — 받은 명함 그리드.
    case receivedCards
    /// 내 명함 QR.
    case cardQR
    /// 근거리 명함 교환 세션.
    case exchange
}

/// MyPage 탭의 공개 진입점.
///
/// 탭 셸이 이 타입만 알면 되도록 DI 컨테이너·에러 핸들러 확보를 여기서 끝내고,
/// 실제 화면 조립은 모듈 내부의 ``MyPageView``가 맡는다.
public struct MyPageFeatureView<DetailRoot: View>: View {

    // MARK: - Property

    @Environment(\.di) private var di

    private let onOpenBusinessCard: (BusinessCardEntry) -> Void
    private let onOpenStudy: () -> Void
    private let onOpenProjects: () -> Void
    private let detailRoot: (AnyView) -> DetailRoot

    // MARK: - Init

    /// - Parameters:
    ///   - onOpenBusinessCard: 명함 카드·「받은 명함」 행 탭 시 App 셸에 명함 진입을 요청한다.
    ///     App 셸이 ``BusinessCardEntry``를 `BusinessCardDestination`으로 번역해 push한다.
    ///   - onOpenStudy: 「나의 스터디」 행 탭 시 App 셸에 스터디 화면 진입을 요청한다. 스터디의
    ///     Activity 피처의 커리큘럼을 MyPage 스택에 표시하는 조립은 App 셸이 맡는다.
    ///   - onOpenProjects: 「내 프로젝트」 행 탭 시 App 셸에 Project 화면 진입을 요청한다 (#1476).
    public init(
        onOpenBusinessCard: @escaping (BusinessCardEntry) -> Void,
        onOpenStudy: @escaping () -> Void,
        onOpenProjects: @escaping () -> Void,
        @ViewBuilder detailRoot: @escaping (AnyView) -> DetailRoot
    ) {
        self.onOpenBusinessCard = onOpenBusinessCard
        self.onOpenStudy = onOpenStudy
        self.onOpenProjects = onOpenProjects
        self.detailRoot = detailRoot
    }

    // MARK: - Body

    public var body: some View {
        MyPageSplitContent(
            container: di,
            onOpenBusinessCard: onOpenBusinessCard,
            onOpenStudy: onOpenStudy,
            onOpenProjects: onOpenProjects,
            detailRoot: detailRoot
        )
    }
}

private struct MyPageSplitContent<DetailRoot: View>: View {
    @State private var viewModel: MyPageViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var compactColumn: NavigationSplitViewColumn = .sidebar
    @State private var replaceablePath: NavigationPath?
    @State private var isOverviewSelected = false
    @Environment(PathStore.self) private var pathStore
    let container: DIContainer
    let onOpenBusinessCard: (BusinessCardEntry) -> Void
    let onOpenStudy: () -> Void
    let onOpenProjects: () -> Void
    let detailRoot: (AnyView) -> DetailRoot
    // iPhone은 한 번의 뒤로 가기로 메뉴에 복귀하는 단일 스택을 유지한다.
    // 회전 중 스택 종류를 바꾸면 상세 화면의 편집 상태가 소실되므로 크기 클래스로 분기하지 않는다.
    private let usesSplitNavigation = UIDevice.current.userInterfaceIdiom != .phone

    init(
        container: DIContainer,
        onOpenBusinessCard: @escaping (BusinessCardEntry) -> Void,
        onOpenStudy: @escaping () -> Void,
        onOpenProjects: @escaping () -> Void,
        @ViewBuilder detailRoot: @escaping (AnyView) -> DetailRoot
    ) {
        self.container = container
        self.onOpenBusinessCard = onOpenBusinessCard
        self.onOpenStudy = onOpenStudy
        self.onOpenProjects = onOpenProjects
        self.detailRoot = detailRoot
        _viewModel = State(initialValue: MyPageViewModel(container: container))
    }

    var body: some View {
        Group {
            if usesSplitNavigation {
                splitContent
            } else {
                // iPhone에서는 메뉴 자체가 루트여야 한 번의 뒤로 가기로 복귀한다.
                navigationStack(showsOverview: false)
            }
        }
        .onChange(of: pathStore.depth(of: .mypage), initial: true) { _, depth in
            compactColumn = depth == 0 && !isOverviewSelected ? .sidebar : .detail
            if depth == 0 { replaceablePath = nil }
        }
    }

    private var splitContent: some View {
        NavigationSplitView(
            columnVisibility: $columnVisibility,
            preferredCompactColumn: $compactColumn
        ) {
            page(showsOverview: false)
                .disabled(!canSelect)
                .navigationSplitViewColumnWidth(min: 280, ideal: 320, max: 380)
        } detail: {
            navigationStack(showsOverview: true)
        }
        .navigationSplitViewStyle(.balanced)
        .onChange(of: horizontalSizeClass) { _, sizeClass in
            if sizeClass == .regular { columnVisibility = .all }
        }
    }

    private func navigationStack(showsOverview: Bool) -> some View {
        NavigationStack(path: Binding(
            get: { pathStore[.mypage] },
            set: { pathStore[.mypage] = $0 }
        )) {
            detailRoot(AnyView(page(showsOverview: showsOverview)))
                .navigationDestination(for: MyPageDestination.self) { destination in
                    MyPageRoutingView(destination: destination, container: container)
                }
        }
    }

    private var canSelect: Bool {
        MyPageSplitSelection.canReplace(path: pathStore[.mypage], knownReadOnlyPath: replaceablePath)
    }

    private func page(showsOverview: Bool) -> some View {
        MyPageView(
            container: container,
            onOpenBusinessCard: { entry in openExternal { onOpenBusinessCard(entry) } },
            onOpenStudy: { openExternal(onOpenStudy) },
            onOpenProjects: { openExternal(onOpenProjects) },
            viewModel: viewModel,
            showsOverview: showsOverview,
            // 분할 열 내부가 아닌 전체 화면 폭을 기준으로 iPhone 루트 명함을 유지한다.
            showsSidebarCard: !usesSplitNavigation || horizontalSizeClass != .regular,
            onShowOverview: showOverview,
            onSelectDestination: select
        )
    }

    private func showOverview() {
        guard canSelect else { return }
        isOverviewSelected = true
        pathStore[.mypage] = NavigationPath()
        replaceablePath = nil
        compactColumn = .detail
    }

    private func select(_ destination: MyPageDestination) {
        guard canSelect else { return }
        isOverviewSelected = false
        var path = NavigationPath()
        path.append(destination)
        replaceablePath = MyPageSplitSelection.isReadOnly(destination) ? path : nil
        pathStore[.mypage] = path
        compactColumn = .detail
    }

    private func openExternal(_ action: () -> Void) {
        guard canSelect else { return }
        isOverviewSelected = false
        pathStore[.mypage] = NavigationPath()
        replaceablePath = nil
        action()
        compactColumn = .detail
    }
}

/// 편집·인증 및 알 수 없는 경로는 사이드바 선택으로 교체하지 않는다.
enum MyPageSplitSelection {
    static func canReplace(path: NavigationPath, knownReadOnlyPath: NavigationPath?) -> Bool {
        guard !path.isEmpty else { return true }
        guard let knownReadOnlyPath else { return false }
        return path == knownReadOnlyPath
    }

    static func isReadOnly(_ destination: MyPageDestination) -> Bool {
        switch destination {
        case .activityLogs, .certificates, .myActivePosts: true
        case .cardEdit, .settings, .changeEmail, .changePassword, .registerPassword: false
        }
    }
}
