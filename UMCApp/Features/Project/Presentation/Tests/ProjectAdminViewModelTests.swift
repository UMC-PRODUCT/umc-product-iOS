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

    @Test("PUT 정원은 1~999만 전송한다", arguments: ["0", "1", "999", "1000", "", " ", "abc"])
    func validatesPartQuotaRange(value: String) async throws {
        let (viewModel, useCase) = try await makeQuotaViewModel()
        await viewModel.updatePartQuotas(projectId: "101", values: [.pm: value])

        let isValid = value == "1" || value == "999"
        #expect(useCase.quotaUpdates.count == (isValid ? 1 : 0))
        #expect((viewModel.commandError == nil) == isValid)
        if isValid {
            #expect(useCase.quotaUpdates.first?.first?.quota == value)
        } else {
            #expect(viewModel.commandError?.userMessage == "정원은 1명 이상 999명 이하로 입력해 주세요.")
        }
    }

    @Test("최소 TO 충돌은 서버 안내를 유지한다")
    func preservesMinimumQuotaConflict() async throws {
        let (viewModel, useCase) = try await makeQuotaViewModel()
        let message = "PM 합격자를 포함한 최소 정원보다 작게 설정할 수 없습니다."
        let data = try JSONSerialization.data(withJSONObject: [
            "code": "PROJECT-0252", "message": message
        ])
        useCase.quotaError = .network(.requestFailed(statusCode: 409, data: data))

        await viewModel.updatePartQuotas(projectId: "101", values: [.pm: "1"])

        #expect(useCase.quotaUpdates.count == 1)
        #expect(viewModel.commandError?.userMessage == message)
        #expect(!viewModel.isSubmitting)
        #expect(viewModel.dashboard.value != nil)
    }

    @Test("서버가 정원 편집을 허용하지 않으면 전송하지 않는다")
    func deniedQuotaPermissionDoesNotSubmit() async throws {
        let (viewModel, useCase) = try await makeQuotaViewModel(allowsEditing: false)
        await viewModel.updatePartQuotas(projectId: "101", values: [.pm: "1"])
        #expect(useCase.quotaUpdates.isEmpty)
    }

    private func makeQuotaViewModel(allowsEditing: Bool = true) async throws
        -> (ProjectAdminViewModel, ProjectUseCaseSpy) {
        let useCase = ProjectUseCaseSpy()
        let repository = MockProjectRepository()
        useCase.projectPage = try await repository.fetchManagedProjects(
            gisuId: "9", keyword: nil, page: 0, size: 100
        )
        useCase.permissions = allowsEditing
            ? try await repository.fetchPermissions(projectIds: ["101"]) : []
        let viewModel = ProjectAdminViewModel(
            projectUseCase: useCase,
            matchingRoundUseCase: ProjectMatchingRoundUseCase(repository: repository),
            role: .chapterPresident, gisuId: "9", chapterId: nil
        )
        await viewModel.fetch()
        return (viewModel, useCase)
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
