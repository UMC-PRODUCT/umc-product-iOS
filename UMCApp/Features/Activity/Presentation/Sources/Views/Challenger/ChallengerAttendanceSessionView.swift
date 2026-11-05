//
//  ChallengerAttendanceSessionView.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 8/2/26.
//

import ActivityDomain
import CoreDesignSystem
import CoreDI
import CoreUIComponents
import HomeDomain
import SwiftUI
import UMCFoundation

// MARK: - MapViewModelCache

/// Session별 `BaseMapViewModel` 인스턴스를 캐싱합니다.
///
/// 지도 모델은 지오펜스 모니터링을 소유하므로 body 가 재평가될 때마다 새로 만들면
/// 등록이 반복됩니다. Reference type 으로 두어 body 평가 중 mutation 을 안전하게 처리합니다.
@MainActor
private final class MapViewModelCache {
    private var cache: [Session.ID: BaseMapViewModel] = [:]

    func get(for sessionId: Session.ID) -> BaseMapViewModel? {
        cache[sessionId]
    }

    func set(_ viewModel: BaseMapViewModel, for sessionId: Session.ID) {
        cache[sessionId] = viewModel
    }
}

// MARK: - ChallengerAttendanceSessionView

/// 챌린저 출석 진입 화면
///
/// 출석 가능한 세션 목록과 나의 출석 현황을 한 화면에 세로로 배치합니다.
/// 세션 카드를 탭하면 지도·출석 버튼이 있는 상세가 펼쳐집니다.
struct ChallengerAttendanceSessionView: View {

    // MARK: - Property

    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @ScaledMetric(relativeTo: .title) private var emptyStateIconSize = DefaultSpacing.spacing32

    @State private var attendanceViewModel: ChallengerAttendanceViewModel
    @State private var mapViewModelCache = MapViewModelCache()
    @State private var expandedSessionId: Session.ID?

    /// 푸시가 지목한 일정 식별자. 해당 세션을 펼친 뒤 비운다 — 같은 일정에 대한 두 번째
    /// 푸시도 다시 동작해야 한다.
    @Binding private var focusedScheduleId: String?

    private let errorHandler: ErrorHandler
    private let sessions: [Session]
    private let schedules: [ScheduleDetailData]
    private let userId: UserID

    // MARK: - Init

    /// - Parameters:
    ///   - container: 출석 UseCase 를 resolve 할 DI 컨테이너
    ///   - errorHandler: 흐름 중단형 전역 에러 처리기
    ///   - sessions: 상위(일정 화면)가 소유한 세션 목록
    ///   - schedules: 세션과 같은 조회에서 나온 일정 원본 (출석 정책·일정 ID 조회용)
    ///   - userId: 출석 주체
    ///   - focusedScheduleId: 푸시가 지목한 일정. 목록에 있으면 그 세션을 펼치고 비운다.
    ///   - viewModel: 프리뷰/테스트용 주입 지점 (기본값: container 로 생성)
    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        sessions: [Session],
        schedules: [ScheduleDetailData],
        userId: UserID,
        focusedScheduleId: Binding<String?> = .constant(nil),
        viewModel: ChallengerAttendanceViewModel? = nil
    ) {
        self.errorHandler = errorHandler
        self.sessions = sessions
        self.schedules = schedules
        self.userId = userId
        _focusedScheduleId = focusedScheduleId
        _attendanceViewModel = State(
            initialValue: viewModel ?? ChallengerAttendanceViewModel(
                errorHandler: errorHandler,
                challengerAttendanceUseCase: container.resolve(
                    ChallengerAttendanceUseCaseProtocol.self
                )
            )
        )
    }

    // MARK: - Constants

    fileprivate enum Constants {
        static let animationResponse: Double = 0.35
        static let animationDamping: Double = 0.8
    }

    // MARK: - Computed Properties

    /// 출석 가능한 세션만 필터링 (beforeAttendance, pendingApproval)
    private var availableSessions: [Session] {
        sessions.filter(\.isAttendanceAvailable)
    }

    /// 출석이 확정된 세션만 이력 표시 모델로 변환
    ///
    /// 출석 전(`beforeAttendance`) 세션은 변환되지 않으므로, 빈 상태 판단은 원본 세션
    /// 개수가 아니라 변환 결과 개수로 해야 가이드가 정상 표시됩니다.
    private var attendanceHistoryItems: [MyAttendanceItemModel] {
        sessions.compactMap { session in
            MyAttendanceItemModel(
                from: session,
                category: session.info.category,
                attendancePolicy: attendanceViewModel
                    .attendancePolicy(for: session.info.sessionId)
            )
        }
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                AdaptiveContentLayout(
                    maximumColumns: dynamicTypeSize.isAccessibilitySize ? 1 : 2,
                    spacing: DefaultSpacing.spacing24,
                    verticalFlow: .columns,
                    layoutDirection: layoutDirection
                ) {
                    attendanceSessionSection
                    myAttendanceStatusSection
                }
                .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
                .safeAreaPadding(.bottom, DefaultConstant.defaultSafeBottom)
            }
            .contentMargins(
                .trailing,
                DefaultConstant.defaultContentTrailingMargins,
                for: .scrollContent
            )
            .contentMargins(
                .bottom,
                DefaultConstant.defaultContentBottomMargins,
                for: .scrollContent
            )
            .onChange(of: schedules, initial: true) { _, latest in
                attendanceViewModel.apply(schedules: latest)
            }
            // 지목과 목록 도착의 순서가 정해져 있지 않다 — 푸시는 화면 갱신을 촉발하면서
            // 동시에 지목을 남기므로 두 축 모두에서 같은 시도를 한다.
            .onChange(of: focusedScheduleId, initial: true) { _, _ in
                focusRequestedSession(proxy: proxy)
            }
            .onChange(of: sessions) { _, _ in
                focusRequestedSession(proxy: proxy)
            }
            .onDisappear {
                Task { await attendanceViewModel.geofenceCleanup() }
            }
        }
    }

    // MARK: - Attendance Session Section

    @ViewBuilder
    private var attendanceSessionSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            sectionHeader("출석 가능한 세션")

            // 조회 로딩·실패 UI 는 목록을 소유한 상위(`ActivityView`)가 그린다.
            if availableSessions.isEmpty {
                emptySessionView
            } else {
                ChallengerAttendanceSessionList(
                    sessions: availableSessions,
                    expandedSessionId: expandedSessionId,
                    attendanceViewModel: attendanceViewModel,
                    userId: userId,
                    mapViewModelProvider: mapViewModel(for:)
                ) { sessionId in
                    withAnimation(.spring(Spring(
                        response: Constants.animationResponse,
                        dampingRatio: Constants.animationDamping
                    ))) {
                        expandedSessionId = expandedSessionId == sessionId ? nil : sessionId
                    }
                }
                .equatable()
            }
        }
    }

    private var emptySessionView: some View {
        emptyStateCard(
            systemImage: "calendar.badge.clock",
            title: "지금은 출석할 세션이 없어요",
            description: "새로운 세션이 열리면\n여기서 출석을 체크할 수 있어요."
        )
    }

    // MARK: - My Attendance Status Section

    @ViewBuilder
    private var myAttendanceStatusSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            sectionHeader("나의 출석 현황")

            // 이력은 상위가 넘긴 `sessions` 창에서 파생하므로 그 창(출석 가능 일정 조회
            // 구간) 밖의 과거 기록은 보이지 않는다 — 빈 상태 가이드가 뜰 수 있다.
            let items = attendanceHistoryItems
            if items.isEmpty {
                emptyHistoryView
            } else {
                ChallengerMyAttendanceStatusView(models: items)
            }
        }
    }

    private var emptyHistoryView: some View {
        emptyStateCard(
            systemImage: "clock.arrow.circlepath",
            title: "표시할 출석 기록이 없어요",
            description: "출석한 세션의 기록을\n여기서 확인할 수 있어요."
        )
    }

    // MARK: - Shared View Components

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .appFont(.body, weight: .semibold, color: .grey900)
            .padding(.leading, DefaultConstant.sectionLeadingHeader)
    }

    private func emptyStateCard(
        systemImage: String,
        title: String,
        description: String
    ) -> some View {
        ContentUnavailableView {
            VStack(spacing: DefaultSpacing.spacing16) {
                Image(systemName: systemImage)
                    .font(.title)
                    .frame(width: emptyStateIconSize, height: emptyStateIconSize)
                    .foregroundStyle(Color.teal600)
                    .padding(DefaultSpacing.spacing16)
                    .background(
                        Color.teal100,
                        in: .rect(cornerRadius: DefaultConstant.cornerRadius)
                    )
                    .accessibilityHidden(true)

                Text(title)
                    .appFont(.body, weight: .semibold, color: .grey900)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, DefaultSpacing.spacing8)
        } description: {
            Text(description)
                .appFont(.subheadline, color: .grey600)
                .multilineTextAlignment(.center)
        }
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
        .background(
            Color.Surface.content,
            in: .rect(cornerRadius: DefaultConstant.cornerRadius)
        )
    }

    // MARK: - Function

    /// 푸시가 지목한 세션을 펼치고 그 자리로 스크롤합니다.
    ///
    /// 목록에서 찾지 못하면 지목을 남겨 둡니다 — 푸시가 촉발한 재조회가 끝나기 전에 비우면
    /// 뒤늦게 도착한 목록에서 다시 펼칠 기회가 사라집니다.
    private func focusRequestedSession(proxy: ScrollViewProxy) {
        guard let scheduleId = focusedScheduleId,
              let session = availableSessions.first(where: { $0.id.value == scheduleId })
        else { return }

        withAnimation(.spring(Spring(
            response: Constants.animationResponse,
            dampingRatio: Constants.animationDamping
        ))) {
            expandedSessionId = session.id
            proxy.scrollTo(session.id, anchor: .top)
        }
        focusedScheduleId = nil
    }

    /// Session별 지도 모델을 캐시에서 가져오거나 새로 생성합니다.
    ///
    /// 지오펜스는 서버 일정 ID 로 등록해야 출석 판정과 같은 대상을 가리킵니다.
    /// 아직 일정 ID 가 해석되지 않았다면 `nil` 을 돌려주고, 상세는 지도 대신
    /// 플레이스홀더를 표시합니다 — `sessionId` 를 대신 넘기면 컴파일은 되지만
    /// 지오펜스가 항상 어긋나 출석이 거부됩니다.
    private func mapViewModel(for session: Session) -> BaseMapViewModel? {
        if let cached = mapViewModelCache.get(for: session.id) {
            return cached
        }

        guard let scheduleId = attendanceViewModel.scheduleId(for: session.info.sessionId) else {
            return nil
        }

        let newViewModel = BaseMapViewModel(
            info: session.info,
            scheduleId: scheduleId,
            errorHandler: errorHandler
        )
        mapViewModelCache.set(newViewModel, for: session.id)
        return newViewModel
    }
}

#if DEBUG
// MARK: - Preview

#Preview("출석 가능 세션 + 이력") {
    ZStack {
        Color.grey100.ignoresSafeArea()

        AttendancePreviewData.sessionScreen(sessions: AttendancePreviewData.mixedSessions)
    }
}

#Preview("모든 세션 완료 (빈 상태)") {
    ZStack {
        Color.grey100.ignoresSafeArea()

        AttendancePreviewData.sessionScreen(sessions: AttendancePreviewData.completedSessions)
    }
}

#Preview("기록 없음 (빈 상태)") {
    ZStack {
        Color.grey100.ignoresSafeArea()

        AttendancePreviewData.sessionScreen(sessions: AttendancePreviewData.upcomingSessions)
    }
}

#Preview("세션 없음 · 큰 글자") {
    ZStack {
        Color.Surface.canvas.ignoresSafeArea()

        AttendancePreviewData.sessionScreen(sessions: [])
    }
    .environment(\.dynamicTypeSize, .accessibility3)
}
#endif
