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
        errorHandler: ErrorHandler
    ) {
        self.container = container
        self.errorHandler = errorHandler
    }

    // MARK: - Function

    @MainActor
    func fetchMembers() async {
        membersState = .loading

        #if DEBUG
        do {
            try await Task.sleep(for: .milliseconds(500))
            let mockData = StudyMemberItem.preview
            weeks = Array(1...10)
            studyGroups = StudyGroupItem.preview
            allMembers = mockData
            filterMembers()
        } catch {
            membersState = .failed(.unknown(message: error.localizedDescription))
        }
        #endif
    }

    func selectWeek(_ week: Int) {
        selectedWeek = week
        filterMembers()
    }

    func selectStudyGroup(_ group: StudyGroupItem) {
        selectedStudyGroup = group
        filterMembers()
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
