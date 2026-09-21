//
//  WorkbookRepository.swift
//  ActivityData
//
//  Created by euijjang97 on 9/21/26.
//

import ActivityDomain
import CoreNetwork
import Foundation
import Moya
import UMCFoundation

public final class WorkbookRepository: WorkbookRepositoryProtocol, @unchecked Sendable {
    private let network: any NetworkRequesting

    public init(adapter: MoyaNetworkAdapter) { network = adapter }
    init(network: any NetworkRequesting) { self.network = network }

    public func list() async throws -> [WorkbookListItem] {
        guard let gisuId = AppStorageKey.gisuIdString() else {
            throw DomainError.curriculumUnavailableForGeneration
        }
        let result: WorkbookProgressDTO = try await get(
            WorkbookRouter.progress(WorkbookProgressQuery(gisuId: gisuId))
        )
        return result.toDomain()
    }

    public func detail(id: String) async throws -> WorkbookDetail {
        _ = try identifier(id)
        let challenger: ChallengerWorkbookDetailDTO = try await get(WorkbookRouter.challenger(id))
        _ = try identifier(challenger.originalWorkbookId)
        do {
            let original: OriginalWorkbookDetailDTO = try await get(
                WorkbookRouter.original(challenger.originalWorkbookId)
            )
            return WorkbookDetail(original: original.toDomain(), challenger: challenger.toDomain())
        } catch NetworkError.requestFailed(statusCode: 403, data: _) {
            // Original read access is narrower than submission/feedback access on the server.
            return WorkbookDetail(original: nil, challenger: challenger.toDomain())
        }
    }

    public func reviewScope(groupId: String, memberId: String) async throws -> WorkbookReviewScope
    {
        _ = try identifier(groupId)
        let group: StudyGroupDetailDTO = try await get(
            StudyRouter.getStudyGroupDetail(groupId: groupId))
        return WorkbookReviewScope(
            gisuId: group.gisuId ?? "",
            schoolId: group.members.first { $0.memberId == memberId }?.schoolId ?? "",
            mentorIds: group.mentors.map(\.memberId)
        )
    }

    public func mutate(_ mutation: WorkbookMutation) async throws {
        let target: WorkbookRouter
        switch mutation {
        case .submit(let missionId, let workbookId, let content):
            target = .submit(
                MissionSubmissionRequestDTO(
                    originalWorkbookMissionId: try identifier(missionId),
                    challengerMissionId: try identifier(workbookId), content: content
                ))
        case .feedback(let submissionId, let content, let result):
            guard ["PASS", "FAIL"].contains(result) else {
                throw RepositoryError.decodingError(detail: "피드백 결과가 올바르지 않습니다.")
            }
            target = .feedback(
                MissionFeedbackRequestDTO(
                    missionSubmissionId: try identifier(submissionId), content: content,
                    result: result
                ))
        case .editSubmission(let id, let content):
            _ = try identifier(id)
            target = .editSubmission(id, content)
        case .withdraw(let id):
            _ = try identifier(id)
            target = .withdraw(id)
        case .editFeedback(let id, let content):
            _ = try identifier(id)
            target = .editFeedback(id, content)
        case .deleteFeedback(let id):
            _ = try identifier(id)
            target = .deleteFeedback(id)
        }
        let response = try await network.request(target)
        if !response.data.isEmpty {
            try JSONDecoder().decode(APIResponse<EmptyResult>.self, from: response.data)
                .validateSuccess()
        }
    }

    private func get<T: Codable>(_ target: any BaseTargetType) async throws -> T {
        let response = try await network.request(target)
        return try JSONDecoder().decode(APIResponse<T>.self, from: response.data).unwrap()
    }

    private func identifier(_ value: String) throws -> Int {
        guard let id = Int(value), id > 0 else {
            throw RepositoryError.decodingError(detail: "워크북 식별자가 없거나 올바르지 않습니다.")
        }
        return id
    }
}
