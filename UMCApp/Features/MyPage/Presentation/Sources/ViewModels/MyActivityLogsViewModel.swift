//
//  MyActivityLogsViewModel.swift
//  MyPagePresentation
//
//  Created by euijjang97 on 9/14/26.
//

import CoreDomain
import Foundation
import MyPageDomain

/// 활동 이력 목록(``MyActivityLogsView``)의 상태와 기록 추가 동작을 담당하는 ViewModel.
///
/// 목록의 시작점은 탭 루트가 실어 준 스냅샷이다. 기록을 추가한 뒤에만 서버에서 다시 읽는다.
@MainActor
@Observable
final class MyActivityLogsViewModel {

    // MARK: - Property

    private(set) var activityLogs: [ActivityLog]
    /// 기록 추가 API 진행 상태
    private(set) var isAdding: Bool = false
    /// 기록 추가 성공 후 버튼 성공 문구 노출 상태
    private(set) var didRecentlyAdd: Bool = false

    private let useCaseProvider: MyPageUseCaseProviding
    private var recentlyAddedResetTask: Task<Void, Never>?

    private enum Constants {
        static let recentlyAddedDuration: Duration = .seconds(2)
    }

    // MARK: - Init

    init(activityLogs: [ActivityLog], useCaseProvider: MyPageUseCaseProviding) {
        self.activityLogs = activityLogs
        self.useCaseProvider = useCaseProvider
    }

    // MARK: - Function

    /// 운영진 발급 코드로 활동 이력을 추가하고 최신 목록으로 갱신합니다.
    func addRecord(code: String) async throws {
        guard !isAdding else {
            return
        }

        isAdding = true
        defer { isAdding = false }

        try await useCaseProvider.addChallengerRecordUseCase.execute(code: code)
        // 캐시는 Repository 가 기록 추가 성공 시 무효화하므로 기본 경로로 읽어도 최신이다.
        activityLogs = try await useCaseProvider.fetchMyPageProfileUseCase
            .execute()
            .activityLogs
        showRecentlyAddedState()
    }

    /// 기록 추가 성공 문구를 잠시 노출한 뒤 기본 상태로 복귀합니다.
    private func showRecentlyAddedState() {
        recentlyAddedResetTask?.cancel()
        didRecentlyAdd = true

        recentlyAddedResetTask = Task { [weak self] in
            try? await Task.sleep(for: Constants.recentlyAddedDuration)
            guard !Task.isCancelled else { return }
            self?.didRecentlyAdd = false
        }
    }
}
