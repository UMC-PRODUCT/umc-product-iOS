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
            membersState = .loaded(mockData)
        } catch {
            membersState = .failed(.unknown(message: error.localizedDescription))
        }
        #endif
    }

    func selectStudyGroup(_ group: StudyGroupItem) {
        selectedStudyGroup = group
        // TODO: 선택된 그룹에 따른 멤버 필터링 로직 추가
    }
}
