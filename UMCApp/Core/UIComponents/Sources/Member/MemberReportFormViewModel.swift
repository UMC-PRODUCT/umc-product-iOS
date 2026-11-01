//
//  MemberReportFormViewModel.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/1/26.
//

import CoreDomain
import Observation
import UMCFoundation

@MainActor @Observable
final class MemberReportFormViewModel {
    var draft = MemberReportDraft()
    var didSubmit = false
    private(set) var isSubmitting = false
    private(set) var failure: String?
    private let memberId: String
    @ObservationIgnored private let useCase: ReportMemberUseCaseProtocol

    init(memberId: String, useCase: ReportMemberUseCaseProtocol) {
        self.memberId = memberId
        self.useCase = useCase
    }

    var canSubmit: Bool { draft.isValid && !isSubmitting && !didSubmit }

    func submit() async {
        guard canSubmit else { return }
        isSubmitting = true
        failure = nil
        defer { isSubmitting = false }
        do {
            try await useCase.execute(memberId: memberId, draft: draft)
            didSubmit = true
        } catch let error as MemberReportError {
            failure = error.errorDescription
        } catch {
            failure = AppError.from(error).userMessage
        }
    }
}
