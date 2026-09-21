#!/usr/bin/env python3
# Created by euijjang97 on 2026-09-21.
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
names = ["WorkbookDetail", "WorkbookUseCase", "WorkbookViewModel", "Loadable", "AlertPrompt", "ErrorContext"]
files = [next(root.rglob(name + ".swift")) for name in names]
files += list((root / "Core/Foundation/Sources/Error/Types").glob("*.swift"))
source = "import Observation\n" + "\n".join(
    "\n".join(line for line in path.read_text().splitlines()
              if line not in ["import UMCFoundation", "import ActivityDomain", "import CoreDomain"])
    for path in files
)
source += r'''
public enum ManagementTeam: Sendable { case superAdmin, schoolPresident, schoolVicePresident }
public enum OrganizationType: Sendable { case school, chapter }
public struct ProfileRole: Sendable {
    let roleType: ManagementTeam
    let gisuId: String
    let organizationId: String?
    let organizationType: OrganizationType
}
public struct Profile: Sendable { let memberId: String; let roles: [ProfileRole] }
protocol FetchMemberProfileUseCaseProtocol: Sendable { func execute() async throws -> Profile }
@MainActor final class ErrorHandler {
    func handle(_ error: Error, context: ErrorContext) {}
}
final class Dependencies: WorkbookRepositoryProtocol, FetchMemberProfileUseCaseProtocol, @unchecked Sendable {
    var mutationCount = 0
    var detailCount = 0
    var shouldFail = false
    var scope = WorkbookReviewScope(gisuId: "3", schoolId: "4", mentorIds: ["8"])
    func list() async throws -> [WorkbookListItem] { [] }
    func execute() async throws -> Profile { Profile(memberId: "40", roles: []) }
    func reviewScope(groupId: String, memberId: String) async throws -> WorkbookReviewScope { scope }
    func mutate(_ mutation: WorkbookMutation) async throws { mutationCount += 1 }
    func detail(id: String) async throws -> WorkbookDetail {
        detailCount += 1
        if shouldFail { throw DomainError.custom(message: "offline") }
        return WorkbookDetail(
            original: OriginalWorkbookDetail(originalWorkbookId: "10", title: "Week",
                       description: nil, content: nil, url: nil, missionList: []),
            challenger: ChallengerWorkbookDetail(challengerWorkbookId: "30", originalWorkbookId: "10",
                        receivedStudyGroupId: "2", memberId: "40", isExcused: false,
                        content: nil, submissions: []))
    }
}
@main struct Run {
    @MainActor static func main() async throws {
        let dependency = Dependencies()
        let useCase = WorkbookUseCase(repository: dependency)
        let boundary = Date(timeIntervalSince1970: 1_800_000_000)
        let vm = WorkbookViewModel(useCase: useCase, profileUseCase: dependency,
            errorHandler: ErrorHandler(), workbookId: "30", endsAt: boundary, onChanged: {})
        await vm.load()
        let detail = try await dependency.detail(id: "30")
        let mission = WorkbookMission(originalWorkbookMissionId: "21", title: "Memo",
                                     description: nil, missionType: "MEMO", isNecessary: true)
        assert(vm.canSubmit(mission, detail: detail, now: boundary.addingTimeInterval(-1)))
        assert(!vm.canSubmit(mission, detail: detail, now: boundary))
        dependency.shouldFail = true
        let saved = await vm.mutate(.submit(missionId: "21", workbookId: "30", content: "hello"))
        assert(saved && vm.needsRefresh && dependency.mutationCount == 1)
        let repeated = await vm.mutate(.submit(missionId: "21", workbookId: "30", content: "hello"))
        assert(!repeated && dependency.mutationCount == 1)
        dependency.shouldFail = false
        await vm.load()
        assert(!vm.needsRefresh && dependency.mutationCount == 1)
        let withdrawn = await vm.mutate(.withdraw(id: "50"), withdrawnMissionId: "21")
        assert(withdrawn && vm.withdrawnMissionIds.contains("21"))
        assert(!vm.canSubmit(mission, detail: detail, now: boundary.addingTimeInterval(-1)))
        let mentor = try await useCase.canReview(detail.challenger, profile: Profile(memberId: "8", roles: []))
        assert(mentor)
        for (gisu, school, expected) in [("3", "4", true), ("2", "4", false), ("3", "5", false)] {
            let profile = Profile(memberId: "9", roles: [ProfileRole(roleType: .schoolPresident,
                gisuId: gisu, organizationId: school, organizationType: .school)])
            let allowed = try await useCase.canReview(detail.challenger, profile: profile)
            assert(allowed == expected)
        }
        let invalid = WorkbookViewModel(useCase: useCase, profileUseCase: dependency,
            errorHandler: ErrorHandler(), workbookId: "", endsAt: boundary, onChanged: {})
        let count = dependency.detailCount
        await invalid.load()
        assert(dependency.detailCount == count)
        print("Workbook actual VM: deadline boundary, withdrawal, IDs, mutation/refetch, scoped roles passed")
    }
}
'''
with tempfile.TemporaryDirectory(prefix="workbook-state-") as temporary:
    swift = Path(temporary) / "check.swift"
    executable = Path(temporary) / "check"
    swift.write_text(source)
    subprocess.run(["xcrun", "swiftc", "-parse-as-library", str(swift), "-o", str(executable)], check=True)
    subprocess.run([str(executable)], check=True)
