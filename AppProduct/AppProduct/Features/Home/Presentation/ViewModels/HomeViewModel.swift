//
//  HomeViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation

/// 홈 화면의 전반적인 상태와 비즈니스 로직을 관리하는 뷰 모델입니다.
///
/// 기수 정보, 패널티 현황, 일정 데이터, 최근 공지사항 등을 관리하며
/// 뷰의 상태 변화를 트리거합니다.
@Observable
final class HomeViewModel {

    // MARK: - Property

    private let container: DIContainer
    private let useCaseProvider: HomeUseCaseProviding
    private let genRepository: ChallengerGenRepositoryProtocol

    /// 프로필에서 받은 역할 정보 (공지 API 호출 시 사용)
    private(set) var roles: [ChallengerRole] = []

    /// 기수 정보 데이터 (로딩 상태 포함)
    private(set) var seasonData: Loadable<[SeasonType]> = .idle

    /// 기수별 패널티 정보 데이터 (로딩 상태 포함)
    private(set) var generationData: Loadable<[GenerationData]> = .idle

    /// 날짜별 일정 데이터 딕셔너리
    /// - Key: 날짜 (Date)
    /// - Value: 해당 날짜의 일정 리스트 ([ScheduleData])
    var scheduleByDates: [Date: [ScheduleData]] = [:]

    /// 최근 공지사항 데이터 (로딩 상태 포함)
    private(set) var recentNoticeData: Loadable<[RecentNoticeData]> = .idle

    /// 일정이 등록된 날짜들의 집합
    var scheduleDates: Set<Date> {
        Set(scheduleByDates.keys)
    }

    // MARK: - Init

    init(container: DIContainer) {
        self.container = container
        self.useCaseProvider = container.resolve(HomeUseCaseProviding.self)
        self.genRepository = container.resolve(ChallengerGenRepositoryProtocol.self)
    }

    // MARK: - Function

    /// 홈 화면 진입 시 전체 데이터 로드
    ///
    /// 프로필 조회 후 역할 정보를 기반으로 일정, 공지를 병렬 조회합니다.
    @MainActor
    func fetchAll() async {
        await fetchProfile()

        async let scheduleTask: () = fetchSchedules()
        async let noticeTask: () = fetchRecentNotices()
        _ = await (scheduleTask, noticeTask)
    }

    /// 프로필 조회 (기수 카드 + 역할 정보 + AppStorage 저장)
    @MainActor
    func fetchProfile() async {
        seasonData = .loading
        do {
            let result = try await useCaseProvider
                .fetchMyProfileUseCase.execute()
            roles = result.roles
            seasonData = .loaded(result.seasonTypes)
            saveProfileToStorage(result)
            syncGenerationMappings(result.roles)
            applyGenerationsFromProfile(result.generations)
        } catch let error as AppError {
            seasonData = .failed(error)
        } catch {
            seasonData = .failed(.unknown(message: error.localizedDescription))
        }
    }

    // MARK: - Private Function

    /// 프로필 정보를 AppStorage(UserDefaults)에 저장
    ///
    /// 최신 기수(max gisu) 기준으로 역할 정보를 저장합니다.
    /// 다른 Feature에서 `@AppStorage(AppStorageKey.xxx)`로 즉시 접근 가능합니다.
    private func saveProfileToStorage(_ result: HomeProfileResult) {
        guard let latestRole = result.roles
            .max(by: { $0.gisu < $1.gisu }) else { return }
        let defaults = UserDefaults.standard
        defaults.set(latestRole.gisuId, forKey: AppStorageKey.gisuId)
        defaults.set(result.memberId, forKey: AppStorageKey.memberId)
        defaults.set(
            latestRole.challengerId,
            forKey: AppStorageKey.challengerId
        )
        defaults.set(result.schoolId, forKey: AppStorageKey.schoolId)
        defaults.set(
            latestRole.responsiblePart?.apiValue ?? "",
            forKey: AppStorageKey.responsiblePart
        )
        defaults.set(
            latestRole.roleType.rawValue,
            forKey: AppStorageKey.memberRole
        )
        defaults.set(
            latestRole.organizationType.rawValue,
            forKey: AppStorageKey.organizationType
        )
        defaults.set(
            latestRole.organizationId,
            forKey: AppStorageKey.organizationId
        )
        NotificationCenter.default.post(name: .memberProfileUpdated, object: nil)
    }

    /// 프로필 응답의 기수 데이터를 홈 화면 상태로 반영합니다.
    @MainActor
    private func applyGenerationsFromProfile(_ generations: [GenerationData]) {
        generationData = .loading
        generationData = .loaded(generations.sorted { $0.gen < $1.gen })
    }

    /// 역할 정보로 (gen, gisuId) 매핑을 SwiftData(CloudKit)에 동기화합니다.
    @MainActor
    private func syncGenerationMappings(_ roles: [ChallengerRole]) {
        let pairs = roles.map { (gen: $0.gisu, gisuId: $0.gisuId) }
        do {
            try genRepository.replaceMappings(pairs)
        } catch {
            // 매핑 저장 실패는 홈 화면 표시에 치명적이지 않으므로 상태를 깨지 않습니다.
            print("[Home] failed to sync generation mappings: \(error)")
        }
    }

    /// 월별 일정 조회
    ///
    /// - Parameters:
    ///   - year: 조회 연도 (nil이면 현재 연도)
    ///   - month: 조회 월 (nil이면 현재 월)
    @MainActor
    func fetchSchedules(year: Int? = nil, month: Int? = nil) async {
        let calendar = Calendar.current
        let now = Date()
        let y = year ?? calendar.component(.year, from: now)
        let m = month ?? calendar.component(.month, from: now)
        do {
            scheduleByDates = try await useCaseProvider
                .fetchSchedulesUseCase.execute(year: y, month: m)
        } catch {
            scheduleByDates = [:]
        }
    }

    /// 최근 공지 조회 (최신 기수 기준)
    @MainActor
    func fetchRecentNotices() async {
        guard let latestRole = roles.max(by: { $0.gisu < $1.gisu })
        else { return }
        recentNoticeData = .loading
        do {
            let query = NoticeListRequestDTO(
                gisuId: latestRole.gisuId,
                size: 5
            )
            let result = try await useCaseProvider
                .fetchRecentNoticesUseCase.execute(query: query)
            recentNoticeData = .loaded(result)
        } catch let error as AppError {
            recentNoticeData = .failed(error)
        } catch {
            recentNoticeData = .failed(
                .unknown(message: error.localizedDescription)
            )
        }
    }

    /// 특정 날짜에 해당하는 일정 목록을 반환합니다.
    ///
    /// - Parameter date: 조회하려는 날짜
    /// - Returns: 해당 날짜의 일정 데이터 배열 (없으면 빈 배열 반환)
    func getSchedules(_ date: Date) -> [ScheduleData] {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        return scheduleByDates[normalizedDate] ?? []
    }
}
