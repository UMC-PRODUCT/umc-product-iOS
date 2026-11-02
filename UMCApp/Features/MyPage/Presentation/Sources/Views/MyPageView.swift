//
//  MyPageView.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 8/10/26.
//

import BusinessCardDomain
import BusinessCardPresentation
import CoreDesignSystem
import CoreDI
import CoreRouting
import CoreUIComponents
import MyPageDomain
import SwiftUI
import UMCFoundation

/// MyPage 탭 루트 화면 (v3 — 명함 중심).
///
/// 명함 카드 + 「명함 관리」 + 「나의 활동」 + 「커뮤니티 활동」 섹션이 루트다.
/// 기존 섹션 7종(외부 링크·설정·법률·정보·
/// 소셜 연동·회원 관리·UMC 채널)은 ``MyPageSettingsView``로 옮겨갔고, 툴바 ⚙ 버튼으로 진입한다.
///
/// - Important: 탐색 스택은 상위 `MyPageFeatureView`의 상세 열이 소유한다.
struct MyPageView: View {

    // MARK: - Property

    @State private var viewModel: MyPageViewModel

    /// 명함 앞/뒷면 전환. 카드 소유이며 뒤집힘 여부는 다른 화면 상태에 얽히지 않는다.
    @State private var isCardFlipped = false

    @Environment(PathStore.self) private var pathStore

    private let showsOverview: Bool
    private let onShowOverview: () -> Void
    private let onSelectDestination: (MyPageDestination) -> Void
    private let container: DIContainer
    private let onOpenBusinessCard: (BusinessCardEntry) -> Void
    private let onOpenStudy: () -> Void
    private let onOpenProjects: () -> Void

    // MARK: - Init

    /// - Parameters:
    ///   - container: 섹션·목적지 화면이 UseCase를 resolve할 DI 컨테이너
    ///   - onOpenBusinessCard: 명함 카드 버튼·「받은 명함」 행이 App 셸에 명함 진입을 요청한다.
    ///   - onOpenStudy: 「나의 스터디」 행이 App 셸에 스터디 화면 진입을 요청한다.
    ///   - onOpenProjects: 「내 프로젝트」 행이 App 셸에 Project 화면 진입을 요청한다.
    ///   - viewModel: 프리뷰/테스트용 주입 지점 (기본값: container로 생성)
    init(
        container: DIContainer,
        onOpenBusinessCard: @escaping (BusinessCardEntry) -> Void,
        onOpenStudy: @escaping () -> Void,
        onOpenProjects: @escaping () -> Void,
        viewModel: MyPageViewModel? = nil,
        showsOverview: Bool = false,
        onShowOverview: @escaping () -> Void = {},
        onSelectDestination: @escaping (MyPageDestination) -> Void
    ) {
        self.showsOverview = showsOverview
        self.onShowOverview = onShowOverview
        self.onSelectDestination = onSelectDestination
        self.container = container
        self.onOpenBusinessCard = onOpenBusinessCard
        self.onOpenStudy = onOpenStudy
        self.onOpenProjects = onOpenProjects
        _viewModel = State(initialValue: viewModel ?? MyPageViewModel(container: container))
    }

    // MARK: - Body

    var body: some View {
        Group {
            if showsOverview {
                profileOverview
            } else {
                sidebar
            }
        }
        // 시안(12766:98169)은 34pt 타이틀과 ⚙ 버튼이 **한 행**이다 — Toolbar-Top 하나가
        // Title 과 Trailing 을 나란히 담는다. `.large` 는 타이틀을 바 아래 별도 행으로
        // 내려 둘이 위아래로 갈리므로 `.inlineLarge`(툴바 안의 큰 타이틀)를 쓴다.
        .navigationInlineLarge(naviTitle: showsOverview ? NavigationTitle.MyPage.profileOverview : .root)
        .umcDefaultBackground()
        .alertPrompt(item: showsOverview ? .constant(nil) : $viewModel.alertPrompt)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    onSelectDestination(.settings)
                } label: {
                    Image(systemName: "gearshape")
                }
                .accessibilityLabel("설정")
            }
        }
        .task {
            guard !showsOverview else { return }
            await viewModel.fetchProfile()
        }
        .task {
            guard !showsOverview else { return }
            await viewModel.loadBusinessCard()
        }
        // 내 정보 편집에서 이미지·링크를 수정하고 돌아오면 카드가 옛 스냅샷으로 남는다.
        // 수정 API가 세션 캐시를 갱신해 두므로 여기서는 추가 왕복 없이 최신 값을 다시 읽는다.
        // 명함도 같은 정본 프로필 캐시에서 파생되므로 함께 다시 읽는다.
        .onChange(of: pathStore.depth(of: .mypage)) { previousDepth, currentDepth in
            guard !showsOverview, currentDepth < previousDepth else { return }
            Task {
                await viewModel.fetchProfile()
                await viewModel.loadBusinessCard()
            }
        }
    }

    // MARK: - View Component

    private var sidebar: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metrics.sectionGroupSpacing) {
                Button(action: onShowOverview) {
                    HStack(spacing: DefaultSpacing.spacing12) {
                        Image(systemName: "person.crop.circle")
                            .font(.title)
                        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                            Text(viewModel.profileData.value?.challengerInfo.nickname ?? "내 프로필")
                                .appFont(.body, weight: .semibold, color: .grey900)
                            Text("프로필 개요")
                                .appFont(.caption1, color: .grey500)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding(.vertical, DefaultSpacing.spacing8)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
                BusinessCardSection(
                    receivedCardCount: viewModel.activityStat.receivedCardCount,
                    onReceivedCards: { onOpenBusinessCard(.receivedCards) },
                    onCardEdit: cardEditAction,
                    isCardEditPending: viewModel.isCardEditPending
                )
                MyActivitySection(
                    studyCount: viewModel.activityStat.studyCount,
                    activityCount: viewModel.activityStat.activityCount,
                    onStudyTap: onOpenStudy,
                    onActivityTap: activityLogsAction,
                    isActivityPending: viewModel.isCardEditPending,
                    onCertificateTap: { onSelectDestination(.certificates) },
                    onProjectTap: onOpenProjects
                )
                MyActiveLogSection { onSelectDestination(.myActivePosts(logType: $0)) }
            }
            .padding(.horizontal, Metrics.contentHorizontalPadding)
            .padding(.vertical, DefaultSpacing.spacing16)
        }
    }

    /// 빈 선택 화면 대신, 현재 프로필 스냅샷으로 구성한 실제 개요를 표시한다.
    private var profileOverview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing24) {
                cardContent
                if let profile = viewModel.profileData.value {
                    VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
                        Text("내 정보")
                            .appFont(.body, weight: .semibold, color: .grey900)
                        LabeledContent("이름", value: profile.challengerInfo.name)
                        LabeledContent("닉네임", value: profile.challengerInfo.nickname)
                        LabeledContent("학교", value: profile.challengerInfo.schoolName)
                        LabeledContent("활동 이력", value: "\(profile.activityLogs.count)개")
                    }
                    .padding(DefaultSpacing.spacing16)
                    .background(Color.white, in: .rect(cornerRadius: DefaultConstant.cornerRadius))
                }
            }
            .adaptiveReadableWidth(maximum: 600)
            .padding(DefaultSpacing.spacing16)
        }
    }

    @ViewBuilder
    private var cardContent: some View {
        switch viewModel.myCard {
        case .idle, .loading:
            ProgressView()
                .frame(maxWidth: .infinity)

        case .loaded(let card):
            // 「명함 교환」·「QR 코드」는 이번 릴리즈 제외(#1329). `onExchange`/`onQR` 를
            // 넘기지 않으면 `hasActions == false` 라 버튼 행이 빠진다 — 되살릴 때
            // 이 두 인자만 다시 넘기면 된다.
            // RealityKit 3D 경로는 #1349 에서 철거됐다. 명함을 그리는 뷰는 이제 이것
            // 하나뿐이고, 필요한 Y축 원근 회전은 이 2D 카드가 스스로 한다(#1348).
            BusinessCardFaceView(
                card: card,
                isFlipped: isCardFlipped,
                qrImage: viewModel.qrImage,
                onFlip: { isCardFlipped.toggle() }
            )

        case .failed(let error):
            RetryContentUnavailableView(
                title: "명함을 불러오지 못했어요",
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: error.userMessage,
                isRetrying: viewModel.isCardRetryInFlight,
                retryAction: { await Self.retryCardAndProfile(viewModel: viewModel) }
            )
        }
    }

    // MARK: - Function

    /// 내 정보 편집으로 이동하는 액션. 스냅샷이 아직 없으면(로딩 중·실패) `nil` —
    /// `BusinessCardSection`이 이를 받아 행을 비활성화한다(``MyPageViewModel/isCardEditPending``
    /// 이 로딩 중인 구간의 진행 표시를 함께 맡는다). `nil`이 아닐 때도 재조회하지 않고 루트가
    /// 이미 로드해 둔 스냅샷을 싣는다 — `MyPageDestination.cardEdit`의 문서 주석과 같은 이유
    /// (어긋난 값으로 편집이 시작되는 것을 막기 위함)다.
    private var cardEditAction: (() -> Void)? {
        guard let profile = viewModel.profileData.value else { return nil }
        return { onSelectDestination(.cardEdit(profileData: profile)) }
    }

    /// 활동 이력 목록으로 이동하는 액션. ``cardEditAction``과 같은 규칙 — 스냅샷이 없으면
    /// `nil`이고, 있으면 루트가 이미 로드해 둔 배열을 그대로 싣는다. 행 우측 카운트가
    /// 세는 것과 **같은 파생**이어야 숫자와 목록이 어긋나지 않기 때문이다.
    private var activityLogsAction: (() -> Void)? {
        guard let profile = viewModel.profileData.value else { return nil }
        return {
            onSelectDestination(.activityLogs(profile.activityLogs))
        }
    }

    /// 명함 카드 로드 실패 후 재시도. 진입 시 네트워크 장애로 `profileData`도 함께
    /// `.failed`가 됐을 수 있다 — 카드만 재시도하면 「내 정보 편집」 행이 활성 외관인 채
    /// 무반응으로 남으므로(``cardEditAction``이 `profileData`를 요구) 두 로드를 함께
    /// 재시도한다. `static`으로 뽑아 뷰 렌더링 없이 테스트한다.
    static func retryCardAndProfile(viewModel: MyPageViewModel) async {
        await viewModel.fetchProfile(forceRefresh: true)
        await viewModel.loadBusinessCard(forceRefresh: true)
    }

    // MARK: - Metrics

    /// 시안 실측값 (`view-facts.md` 「마이페이지 v3 루트」).
    private enum Metrics {
        static let contentHorizontalPadding: CGFloat = 14
        /// 「명함 관리」·「나의 활동」 섹션 그룹 사이 간격.
        static let sectionGroupSpacing: CGFloat = 23
    }
}
