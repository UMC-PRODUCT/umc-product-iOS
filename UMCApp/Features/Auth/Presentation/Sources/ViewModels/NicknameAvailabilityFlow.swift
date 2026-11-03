//
//  NicknameAvailabilityFlow.swift
//  AuthPresentation
//
//  Created by euijjang97 on 11/3/26.
//

import AuthDomain
import Foundation
import UMCFoundation

@Observable
final class NicknameAvailabilityFlow {
    private let checkAvailability: (String, String) async throws -> Bool
    private(set) var state: Loadable<Bool> = .idle
    @ObservationIgnored private(set) var revision = UUID()

    var nickname = "" {
        didSet {
            // Swift의 문자열 동등 비교는 분해형과 완성형 한글을 구분하지 않는다.
            if !nickname.utf8.elementsEqual(oldValue.utf8) { invalidate() }
        }
    }

    var selectedSchool: School? {
        didSet {
            if selectedSchool?.id != oldValue?.id { invalidate() }
        }
    }

    init(checkAvailability: @escaping (String, String) async throws -> Bool) {
        self.checkAvailability = checkAvailability
    }

    var isValidNickname: Bool {
        let syllables = nickname.unicodeScalars
        return (1...4).contains(syllables.count)
            && syllables.allSatisfy { (0xAC00...0xD7A3).contains($0.value) }
    }

    var canCheck: Bool {
        isValidNickname && (Int64(selectedSchool?.id ?? "") ?? 0) > 0
            && !state.isLoading && state.value != true
    }

    @MainActor
    func check() async {
        guard canCheck, let selectedSchool else { return }
        let requestRevision = revision
        state = .loading
        do {
            let available = try await checkAvailability(selectedSchool.id, nickname)
            guard revision == requestRevision else { return }
            state = .loaded(available)
        } catch {
            guard revision == requestRevision else { return }
            state = .failed(AppError.from(error))
        }
    }

    func markUnavailable(for submittedRevision: UUID) {
        guard submittedRevision == revision else { return }
        state = .loaded(false)
    }

    private func invalidate() {
        revision = UUID()
        state = .idle
    }
}
