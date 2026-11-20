//
//  ThreadMemberProfileViewModel.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import Observation
import CommunityDomain
import UMCFoundation

/// 스레드에서 연 다른 회원 프로필 시트의 내용 상태 (#1681).
///
/// 차단·신고는 시트 틀(`MemberSafetyProfileView`)이 따로 맡아, 여기서 조회가 실패해도
/// 그대로 쓸 수 있다.
@Observable
@MainActor
final class ThreadMemberProfileViewModel {

    // MARK: - Property

    private(set) var state: Loadable<ThreadMemberProfile> = .idle

    private let memberId: String
    private let useCase: ThreadMemberProfileUseCaseProtocol

    // MARK: - Init

    init(memberId: String, useCase: ThreadMemberProfileUseCaseProtocol) {
        self.memberId = memberId
        self.useCase = useCase
    }

    // MARK: - Function

    /// 읽는 중이면 다시 읽지 않는다. 실패 뒤 「다시 시도」로 다시 부른다.
    func load() async {
        if case .loading = state { return }
        state = .loading
        do {
            state = .loaded(try await useCase.loadProfile(memberId: memberId))
        } catch is CancellationError {
            state = .idle
        } catch let error as AppError {
            state = .failed(error)
        } catch {
            state = .failed(.unknown(message: error.localizedDescription))
        }
    }
}
