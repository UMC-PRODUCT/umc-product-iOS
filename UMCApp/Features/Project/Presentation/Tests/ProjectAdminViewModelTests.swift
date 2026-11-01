//
//  ProjectAdminViewModelTests.swift
//  ProjectPresentationTests
//
//  Created by euijjang97 on 9/20/26.
//

import Foundation
import ProjectData
import ProjectDomain
import Testing
import UMCFoundation
@testable import ProjectPresentation

#if DEBUG
@Suite("ProjectAdminViewModel")
@MainActor
struct ProjectAdminViewModelTests {

    @Test("운영진은 관리 프로젝트 권한과 지부 통계를 함께 조회한다")
    func operatorLoadsDashboard() async throws {
        let viewModel = makeViewModel(role: .chapterPresident)

        await viewModel.fetch()

        let dashboard = try #require(viewModel.dashboard.value)
        #expect(dashboard.projects.map(\.id) == ["101"])
        #expect(dashboard.permission(for: "101") != nil)
        #expect(dashboard.statistics?.chapterId == "5")
        #expect(viewModel.matchingRounds.value?.map(\.id) == ["11"])
        #expect(viewModel.matchingStatistics.value?.chapterId == "5")
    }

    @Test("챌린저는 운영 API 대신 빈 대시보드를 받는다")
    func challengerReceivesEmptyDashboard() async throws {
        let viewModel = makeViewModel(role: .challenger)

        await viewModel.fetch()

        let dashboard = try #require(viewModel.dashboard.value)
        #expect(viewModel.canAccess == false)
        #expect(dashboard.projects.isEmpty)
        #expect(viewModel.matchingRounds.value?.isEmpty == true)
    }

    @Test(
        "매칭 차수 폼은 이름과 시간 순서가 모두 유효해야 저장할 수 있다"
    )
    func validatesMatchingRoundForm() {
        var form = ProjectMatchingRoundForm()
        #expect(form.isValid == false)

        form.name = "1차 매칭"
        #expect(form.isValid)

        form.decisionDeadline = form.endsAt
        #expect(form.isValid == false)

        form.decisionDeadline = form.endsAt.addingTimeInterval(-1)
        #expect(form.isValid == false)
    }

    @Test("결과 발표는 결정 마감에서 정확히 5분 이후부터 허용한다")
    func validatesResultPublicationInterval() {
        var form = ProjectMatchingRoundForm()
        form.name = "1차 매칭"
        form.resultPublishAt = form.decisionDeadline.addingTimeInterval(299)
        #expect(!form.isValid)

        form.resultPublishAt = form.decisionDeadline.addingTimeInterval(300)
        #expect(form.isValid)

        form.resultPublishAt = form.decisionDeadline.addingTimeInterval(301)
        #expect(form.isValid)
    }

    @Test("기존 차수의 미설정 발표일은 메타데이터 수정 시 생략한다")
    func preservesLegacyMissingResultPublication() throws {
        let round = ProjectMatchingRound(
            id: "11", name: "1차", description: nil, type: .planDeveloper,
            phase: .first, chapterId: "5",
            startsAt: .init(timeIntervalSince1970: 0),
            endsAt: .init(timeIntervalSince1970: 3600),
            decisionDeadline: .init(timeIntervalSince1970: 7200),
            autoDecisionExecutedAt: nil, autoDecisionExecutedMemberId: nil,
            createdAt: nil, updatedAt: nil
        )
        var form = ProjectMatchingRoundForm(round: round)
        form.name = "수정한 이름"
        form.description = "수정한 설명"
        #expect(form.isValid)
        #expect(form.resultPublishAtForUpdate == nil)
        let request = UpdateProjectMatchingRoundRequestDTO(
            update: .init(name: form.name, resultPublishAt: form.resultPublishAtForUpdate)
        )
        let object = try #require(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(request)) as? [String: Any]
        )
        #expect(object["name"] as? String == "수정한 이름")
        #expect(object["resultPublishAt"] == nil)

        form.resultPublishAt = form.decisionDeadline.addingTimeInterval(299)
        #expect(!form.isValid)
        form.resultPublishAt = form.decisionDeadline.addingTimeInterval(600)
        #expect(form.isValid)
        #expect(form.resultPublishAtForUpdate == form.resultPublishAt)
    }

    @Test("관리 프로젝트가 100개를 넘으면 마지막 페이지까지 합친다")
    func loadsEveryManagedProjectPage() async throws {
        let firstItems = (0..<100).map { makeProject(id: String($0)) }
        let lastItem = makeProject(id: "100")
        var requestedPages: [Int] = []

        let projects = try await ProjectManagedPageLoader.fetchAll(pageSize: 100) { page, size in
            requestedPages.append(page)
            return ProjectPage(
                items: page == 0 ? firstItems : [lastItem],
                page: String(page),
                size: String(size),
                totalElements: "101",
                totalPages: "2",
                hasNext: page == 0,
                hasPrevious: page > 0
            )
        }

        #expect(requestedPages == [0, 1])
        #expect(projects.count == 101)
        #expect(projects.last?.id == "100")
    }

    @Test("권한 조회는 서버 상한인 100개씩 나눈다")
    func splitsPermissionRequestsAtServerLimit() async throws {
        let projectIds = (0...100).map { String($0) }
        var requestedBatches: [[String]] = []

        _ = try await ProjectPermissionBatchLoader.fetchAll(projectIds: projectIds) { batch in
            requestedBatches.append(batch)
            return []
        }

        #expect(requestedBatches.map(\.count) == [100, 1])
        #expect(requestedBatches.flatMap { $0 } == projectIds)
    }

    private func makeViewModel(role: ManagementTeam) -> ProjectAdminViewModel {
        let repository = MockProjectRepository()
        return ProjectAdminViewModel(
            projectUseCase: ProjectUseCase(
                repository: repository,
                storageRepository: UnusedProjectStorageRepository()
            ),
            matchingRoundUseCase: ProjectMatchingRoundUseCase(repository: repository),
            role: role,
            gisuId: "9",
            chapterId: "5"
        )
    }
}

private func makeProject(id: String) -> ProjectSummary {
    ProjectSummary(
        id: id,
        name: "프로젝트 \(id)",
        description: nil,
        thumbnailImageURL: nil,
        status: .inProgress,
        productOwner: nil,
        partQuotas: [],
        partQuotaStatus: nil
    )
}
/// 운영진 통계·일정 테스트에서는 파일 업로드를 호출하지 않는다.
private struct UnusedProjectStorageRepository: StorageRepositoryProtocol {
    private enum Failure: Error {
        case unexpectedStorageCall
    }

    func prepareUpload(
        fileName: String,
        contentType: String,
        fileSize: Int,
        category: StorageFileCategory
    ) async throws -> StoragePrepareUploadResponseDTO {
        throw Failure.unexpectedStorageCall
    }

    func uploadFile(
        to url: String,
        data: Data,
        method: String,
        headers: [String: String]?,
        contentType: String?
    ) async throws {
        throw Failure.unexpectedStorageCall
    }

    func confirmUpload(fileId: String) async throws {
        throw Failure.unexpectedStorageCall
    }

    func deleteFile(fileId: String) async throws {
        throw Failure.unexpectedStorageCall
    }
}
#endif
