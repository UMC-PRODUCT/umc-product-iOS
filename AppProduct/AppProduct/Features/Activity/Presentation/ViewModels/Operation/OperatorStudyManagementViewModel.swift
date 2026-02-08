//
//  OperatorStudyManagementViewModel.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import Foundation

@Observable
final class OperatorStudyManagementViewModel {
    // MARK: - Property

    private var container: DIContainer
    private var errorHandler: ErrorHandler
    private var useCase: FetchStudyMembersUseCaseProtocol

    private(set) var membersState: Loadable<[StudyMemberItem]> = .idle
    private(set) var studyGroups: [StudyGroupItem] = []
    var selectedStudyGroup: StudyGroupItem = .all
    private(set) var weeks: [Int] = []
    var selectedWeek: Int = 1

    /// 필터링 전 전체 멤버 목록
    private var allMembers: [StudyMemberItem] = []

    // MARK: - Initializer

    init(
        container: DIContainer,
        errorHandler: ErrorHandler,
        useCase: FetchStudyMembersUseCaseProtocol
    ) {
        self.container = container
        self.errorHandler = errorHandler
        self.useCase = useCase
    }

    // MARK: - Function

    @MainActor
    func fetchMembers() async {
        membersState = .loading

        do {
            let members = try await useCase.fetchMembers()
            let groups = try await useCase.fetchStudyGroups()
            let fetchedWeeks = try await useCase.fetchWeeks()
            allMembers = members
            studyGroups = groups
            weeks = fetchedWeeks
            filterMembers()
        } catch let error as DomainError {
            membersState = .failed(.domain(error))
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "fetchStudyMembers",
                retryAction: { [weak self] in
                    await self?.fetchMembers()
                }
            ))
        }
    }

    func selectWeek(_ week: Int) {
        filterMembers()
    }

    func selectStudyGroup(_ group: StudyGroupItem) {
        filterMembers()
    }

    func submitReview(
        member: StudyMemberItem,
        feedback: String,
        isApproved: Bool
    ) {
        // TODO: UseCase 연동
    }

    func submitBestWorkbook(
        member: StudyMemberItem,
        recommendation: String
    ) {
        // TODO: UseCase 연동
    }

    // MARK: - Private

    /// 선택된 스터디 그룹과 주차에 따라 멤버 필터링
    private func filterMembers() {
        var filtered = allMembers

        // 1. 주차 필터
        filtered = filtered.filter { $0.week == selectedWeek }

        // 2. 스터디 그룹 필터
        if let targetPart = selectedStudyGroup.part {
            filtered = filtered.filter {
                $0.part == targetPart
            }
        }

        membersState = .loaded(filtered)
    }
}
