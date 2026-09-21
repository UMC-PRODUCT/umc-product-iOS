//
//  OperatorStudyManagementViewModel.swift
//  ActivityPresentation
//
//  Created by jaewon Lee on 6/27/26.
//

import ActivityDomain
import CoreDomain
import Foundation
import UMCFoundation

/// 운영진 스터디 관리 화면의 상태를 관리하는 ViewModel
///
/// 스터디 그룹 CRUD(생성/수정/삭제) 및 멘토·멤버 변경을 처리합니다.
/// 모든 액션은 `OperatorStudyManagementUseCaseProtocol` 에만 의존하며(Repository 직접 의존 금지),
/// 서버 식별자는 전 레이어 `String` 으로 통일합니다.
@MainActor
@Observable
final class OperatorStudyManagementViewModel {

    // MARK: - Property

    private enum Constants {
        static let groupManagementPageSize = 20
        /// 제출 현황 페이지 크기 (스터디원 기준, 서버 최대 100)
        static let submissionPageSize = 20
        /// 낙관적 삽입으로 만든 로컬 placeholder 그룹의 serverID 접두사.
        /// 서버 호출 대상이 아님을 구분하는 표식 — 백그라운드 새로고침으로 곧 교체됩니다.
        static let localGroupIDPrefix = "new_"

        /// 그룹 생성 실패를 로컬 Alert 로 소화해도 되는 "권한 없음" 업무 코드.
        ///
        /// `NetworkError` 경로의 `statusCode == 403` 게이트와 같은 역할이다.
        /// `RepositoryError.serverError` 의 첫 값은 HTTP 상태가 아니라 업무 코드이므로,
        /// 서버가 403(FORBIDDEN)으로 정의한 코드만 여기 담는다.
        ///
        /// - Note: 접두사(`AUTHORIZATION-`) 매칭을 쓰지 않는다. 같은 접두사에 권한과 무관한
        ///   코드가 섞여 있고(`-0003` 400, `-0004` 500, `-0010` 404, `-0011` 501), 반대로
        ///   스터디 그룹 전용 권한 거부는 다른 접두사(`ORGANIZATION-0031`)를 쓰기 때문이다.
        ///   판별이 애매한 코드는 넣지 않는다 — 누락은 전역 Alert 로 끝나지만, 과다 포함은
        ///   errorHandler(세션 만료·로깅)를 우회시킨다.
        static let permissionDeniedServerCodes: Set<String> = [
            "AUTHORIZATION-0001",  // PERMISSION_DENIED
            "AUTHORIZATION-0002",  // RESOURCE_ACCESS_DENIED (@CheckAccess 거부)
            "ORGANIZATION-0031"    // STUDY_GROUP_ACCESS_DENIED (학교 운영진 아님)
        ]
    }

    private let errorHandler: ErrorHandler
    private let useCase: OperatorStudyManagementUseCaseProtocol

    /// 현재 사용자 기수 ID 제공자 (서버 응답 `String`) — 테스트에서 주입 가능.
    private let gisuIdProvider: () -> String?

    /// 현재 사용자 챌린저 ID 제공자 (서버 응답 `String`) — 테스트에서 주입 가능.
    ///
    /// 일정 등록 권한(담당 멘토 여부) 판정에만 쓴다.
    private let challengerIdProvider: () -> String?

    /// 기수 ID → 기수 값 역매핑 저장소 — 화면에 기수를 표시할 때만 쓴다.
    private let genRepository: ChallengerGenRepositoryProtocol?

    /// 스터디 그룹 관리 로딩 상태
    private(set) var studyGroupDetailsState: Loadable<[StudyGroupInfo]> = .idle

    /// 스터디 그룹 관리 상태
    private(set) var studyGroupDetails: [StudyGroupInfo] = []

    /// 스터디 그룹 목록 추가 페이지 로딩 여부
    private(set) var isLoadingMoreStudyGroupDetails = false

    /// 편집 중인 그룹 (시트 표시용)
    var editingGroup: StudyGroupInfo?

    /// 편집 시트 이름 입력 상태
    var editingName: String = ""

    /// 멤버 추가 대상 그룹 (시트 표시용)
    var addMemberGroup: StudyGroupInfo?

    /// 멤버 변경 API 호출 대상 그룹 (시트 dismiss 이후 사용)
    private var memberUpdateTargetGroup: StudyGroupInfo?

    /// 시트에서 선택된 챌린저 목록
    var selectedChallengers: [ChallengerInfo] = []

    /// 멘토 추가 대상 그룹 (시트 표시용)
    var addMentorGroup: StudyGroupInfo?

    /// 멘토 변경 API 호출 대상 그룹 (시트 dismiss 이후 사용)
    private var mentorUpdateTargetGroup: StudyGroupInfo?

    /// 멘토 시트에서 선택된 챌린저 목록
    var selectedMentors: [ChallengerInfo] = []

    /// 확인 다이얼로그
    var alertPrompt: AlertPrompt?

    /// 스터디 그룹 상세 목록 다음 페이지 커서 (서버 응답 `String`)
    private var studyGroupDetailsNextCursor: String?

    /// 스터디 그룹 상세 목록 다음 페이지 존재 여부
    private var studyGroupDetailsHasNext = false

    // MARK: - Property (제출 현황)

    /// 제출 현황 로딩 상태
    private(set) var submissionsState: Loadable<[StudyMemberSubmission]> = .idle

    /// 제출 현황 목록 (행 단위 = 스터디원)
    private(set) var submissions: [StudyMemberSubmission] = []

    /// 제출 현황 추가 페이지 로딩 여부
    private(set) var isLoadingMoreSubmissions = false

    /// 그룹 필터 후보 (관리 가능한 스터디 그룹 이름 목록)
    private(set) var studyGroupNames: [StudyGroupName] = []

    /// 선택된 그룹 필터 (`nil` 이면 관리 가능한 전체 그룹)
    private(set) var selectedSubmissionGroupId: String?

    /// 선택된 주차 필터 (비어 있으면 전체 주차)
    private(set) var selectedSubmissionWeekNos: [String] = []

    private(set) var submissionWeeksState: Loadable<[String]> = .idle
    var availableSubmissionWeekNos: [String] { submissionWeeksState.value ?? [] }
    private var loadedWeeksGroupId: String?

    /// 제출 현황 다음 페이지 커서 (직전 페이지 마지막 `studyGroupMemberId`)
    private var submissionNextCursor: String?

    /// 제출 현황 다음 페이지 존재 여부
    private var submissionHasNext = false

    /// 현재 목록이 어떤 그룹 필터의 결과인지 (조회 성공 시점에 기록)
    private var loadedSubmissionGroupId: String?

    /// 현재 목록이 어떤 주차 필터의 결과인지 (조회 성공 시점에 기록)
    private var loadedSubmissionWeekNos: [String] = []

    /// 제출 현황 첫 페이지 조회가 진행 중인지 여부 (재진입 가드 전용)
    ///
    /// 화면 상태(`submissionsState`)를 가드로 쓰면 안 된다 — 취소된 요청이 그 상태를 이전 값으로
    /// 되돌리기 때문에, 취소와 재진입이 엇갈리면 in-flight 가 없는데도 `.loading` 이 남아 이후
    /// 조회가 영구히 막힌다(stuck loading). 실제 in-flight 여부는 이 플래그만 안다.
    private var isReloadingSubmissions = false

    /// 제출 현황 요청 토큰 (latest-wins)
    ///
    /// 그룹/주차 필터를 빠르게 바꾸면 이전 필터의 응답이 뒤늦게 도착할 수 있습니다. 요청 시점의
    /// 토큰을 캡처해 두고 `await` 이후 현재 토큰과 다르면 결과를 버려, 오래된 응답이 최신 목록을
    /// 덮어쓰지 못하게 합니다.
    private var submissionRequestID = 0

    // MARK: - Initializer

    /// - Parameters:
    ///   - errorHandler: 전역 에러 핸들러
    ///   - useCase: 운영진 스터디 관리 UseCase
    ///   - gisuIdProvider: 현재 기수 ID 제공자 (기본값: `AppStorageKey.gisuIdString()`)
    ///   - challengerIdProvider: 현재 챌린저 ID 제공자
    ///     (기본값: `AppStorageKey.challengerIdString()`)
    ///   - genRepository: 기수 ID → 기수 값 역매핑 저장소 (표시용, 없으면 기수를 표시하지 않음)
    init(
        errorHandler: ErrorHandler,
        useCase: OperatorStudyManagementUseCaseProtocol,
        gisuIdProvider: @escaping () -> String? = { AppStorageKey.gisuIdString() },
        challengerIdProvider: @escaping () -> String? = { AppStorageKey.challengerIdString() },
        genRepository: ChallengerGenRepositoryProtocol? = nil
    ) {
        self.errorHandler = errorHandler
        self.useCase = useCase
        self.gisuIdProvider = gisuIdProvider
        self.challengerIdProvider = challengerIdProvider
        self.genRepository = genRepository
    }

    // MARK: - Computed Property

    /// 현재 사용자 기수 ID (서버 응답 `String`). 서버 전달·검증 전용 — 화면에 쓰지 않는다.
    func generation(for group: StudyGroupInfo) -> String? {
        guard let gisuId = group.gisuId else { return nil }
        return genRepository?.gen(forGisuId: gisuId)
    }

    var currentGisuId: String? { gisuIdProvider() }

    /// 화면에 표시할 현재 기수 값(`gen`).
    ///
    /// `currentGisuId` 는 서버 PK 라 그대로 쓰면 「11기」가 「3기」로 보인다(#1356).
    /// 역매핑에 실패하면 `nil` — 기수를 모르는 채로 숫자를 지어내지 않는다.
    var currentGeneration: String? {
        guard let gisuId = currentGisuId else { return nil }
        return genRepository?.gen(forGisuId: gisuId)
    }

    /// 화면에 떠 있는 목록이 지금 선택된 필터의 결과인지 여부.
    ///
    /// 둘이 어긋나면(취소로 필터 적용이 무산된 경우) 재진입 시 반드시 다시 조회해야 한다.
    private var isLoadedListMatchingCurrentFilter: Bool {
        loadedSubmissionGroupId == selectedSubmissionGroupId
            && loadedSubmissionWeekNos == selectedSubmissionWeekNos
            && loadedWeeksGroupId == selectedSubmissionGroupId
            && submissionWeeksState.value != nil
    }

    // MARK: - Function (일정 등록 권한)

    /// 해당 그룹에 일정을 등록할 수 있는지 — 담당 멘토 본인만, 서버에 실재하는 그룹에만 가능하다.
    ///
    /// 챌린저 ID 를 알 수 없으면(로그인 정보 부재 등) 권한 없음으로 본다. 신원을 확인하지
    /// 못한 상태를 통과시키면 남의 스터디 일정을 등록할 수 있게 되기 때문이다.
    ///
    /// - Note: 낙관적 삽입 placeholder(`new_` 접두사)는 아직 서버 식별자가 없어 제외한다.
    ///   레거시는 `Int(group.serverID)` 변환 실패로 이 경우를 조용히 막았는데, 식별자가
    ///   `String` 이 되며 그 변환이 사라졌으므로 여기서 명시적으로 판정한다.
    func canRegisterSchedule(for group: StudyGroupInfo) -> Bool {
        guard isPersistedServerGroup(group.serverID) else { return false }
        guard let challengerId = challengerIdProvider(), !challengerId.isEmpty else {
            return false
        }
        return group.mentors.contains { $0.challengerID == challengerId }
    }

    /// 일정 등록 권한이 없을 때 안내 다이얼로그를 띄운다.
    func presentScheduleRegistrationDenied() {
        alertPrompt = AlertPrompt(
            title: "권한 없음",
            message: "담당 파트장(멘토)만 일정을 등록할 수 있습니다.",
            positiveBtnTitle: "확인"
        )
    }

    // MARK: - Function (조회 / 페이지네이션)

    /// 스터디 그룹 관리 탭 진입 시 그룹 목록 및 상세 조회
    func fetchGroupManagementData() async {
        studyGroupDetailsState = .loading
        isLoadingMoreStudyGroupDetails = false
        studyGroupDetailsNextCursor = nil
        studyGroupDetailsHasNext = false

        do {
            let firstPage = try await useCase.fetchStudyGroupDetailsPage(
                cursor: nil,
                size: Constants.groupManagementPageSize
            )
            studyGroupDetails = firstPage.content
            studyGroupDetailsNextCursor = firstPage.nextCursor
            studyGroupDetailsHasNext = firstPage.hasNext
            studyGroupDetailsState = .loaded(studyGroupDetails)
        } catch let error as AppError {
            studyGroupDetailsState = .failed(error)
        } catch let error as DomainError {
            studyGroupDetailsState = .failed(.domain(error))
        } catch let error as NetworkError {
            studyGroupDetailsState = .failed(.network(error))
        } catch let error as RepositoryError {
            studyGroupDetailsState = .failed(.repository(error))
        } catch {
            studyGroupDetailsState = .failed(.unknown(
                message: "스터디 그룹 관리 데이터를 불러오지 못했습니다."
            ))
        }
    }

    /// 스터디 그룹 관리 목록 마지막 카드 도달 시 다음 페이지를 로드합니다.
    /// - Parameter currentGroupID: 현재 표시된 카드의 로컬 식별자
    func loadMoreGroupManagementDataIfNeeded(currentGroupID: UUID) async {
        guard case .loaded = studyGroupDetailsState else { return }
        guard studyGroupDetails.last?.id == currentGroupID else { return }
        guard studyGroupDetailsHasNext else { return }
        guard !isLoadingMoreStudyGroupDetails else { return }

        isLoadingMoreStudyGroupDetails = true
        defer { isLoadingMoreStudyGroupDetails = false }

        do {
            let nextPage = try await useCase.fetchStudyGroupDetailsPage(
                cursor: studyGroupDetailsNextCursor,
                size: Constants.groupManagementPageSize
            )

            let existingServerIDs = Set(studyGroupDetails.map(\.serverID))
            let newGroups = nextPage.content.filter {
                !existingServerIDs.contains($0.serverID)
            }
            if !newGroups.isEmpty {
                studyGroupDetails.append(contentsOf: newGroups)
                studyGroupDetailsState = .loaded(studyGroupDetails)
            }

            studyGroupDetailsNextCursor = nextPage.nextCursor
            studyGroupDetailsHasNext = nextPage.hasNext
        } catch let error as DomainError {
            presentAlert(title: "불러오지 못했어요", message: error.userMessage)
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "fetchMoreStudyGroupManagement"
            ))
        }
    }

    // MARK: - Function (제출 현황)

    /// 제출 현황 화면 진입 시 첫 페이지와 그룹 필터 후보를 조회합니다.
    ///
    /// 섹션을 오갈 때마다 `.task` 가 다시 실행되는데, 그때마다 새로 조회하면 스크롤로 쌓아 둔
    /// 페이지가 통째로 버려집니다. 그래서 **현재 필터로 이미 채워 둔 목록이 있으면** 재조회를
    /// 건너뜁니다. 목록이 다른 필터의 결과라면(취소로 필터 적용이 무산된 경우) 그대로 두면
    /// 칩과 목록이 어긋난 채 굳으므로 반드시 다시 조회합니다.
    ///
    /// 그룹 이름 목록은 조회를 건너뛰는 경우에도 시도합니다 — 첫 조회 때 이름만 실패하면
    /// 필터 칩이 영영 비어 있게 되기 때문입니다.
    func fetchSubmissions() async {
        if isReloadingSubmissions { return }

        if case .loaded = submissionsState, isLoadedListMatchingCurrentFilter {
            await loadStudyGroupNamesIfNeeded()
            return
        }

        // 목록을 먼저 조회한다. ``reloadSubmissions(groupId:weekNos:)`` 가 await 이전에
        // in-flight 플래그를 세우므로, 곧바로 이어진 두 번째 호출이 위 재진입 가드에 걸린다.
        await reloadSubmissions(
            groupId: selectedSubmissionGroupId,
            weekNos: selectedSubmissionWeekNos
        )
        await loadStudyGroupNamesIfNeeded()
    }

    /// 실패한 조회를 처음부터 다시 시도합니다 (재시도 버튼 전용 — 로드 여부와 무관하게 실행).
    func retrySubmissions() async {
        if isReloadingSubmissions { return }
        await reloadSubmissions(
            groupId: selectedSubmissionGroupId,
            weekNos: selectedSubmissionWeekNos
        )
        await loadStudyGroupNamesIfNeeded()
    }

    /// 그룹 필터를 바꾸고 첫 페이지부터 다시 조회합니다.
    ///
    /// - Parameter groupId: 조회할 그룹 (`nil` 이면 관리 가능한 전체 그룹)
    func selectSubmissionGroup(_ groupId: String?) async {
        guard selectedSubmissionGroupId != groupId else { return }
        await reloadSubmissions(groupId: groupId, weekNos: selectedSubmissionWeekNos)
    }

    /// 주차 필터를 토글하고 첫 페이지부터 다시 조회합니다.
    ///
    /// - Parameter weekNo: 토글할 주차 번호 (서버 응답 `String`)
    func toggleSubmissionWeek(_ weekNo: String) async {
        guard availableSubmissionWeekNos.contains(weekNo) else { return }
        var weekNos = selectedSubmissionWeekNos
        if let index = weekNos.firstIndex(of: weekNo) {
            weekNos.remove(at: index)
        } else {
            weekNos.append(weekNo)
        }
        await reloadSubmissions(groupId: selectedSubmissionGroupId, weekNos: weekNos)
    }

    /// 제출 현황 목록 마지막 카드 도달 시 다음 페이지를 로드합니다.
    ///
    /// - Parameter currentMemberID: 현재 표시된 카드의 `studyGroupMemberId`
    func loadMoreSubmissionsIfNeeded(currentMemberID: String) async {
        guard case .loaded = submissionsState else { return }
        guard submissions.last?.id == currentMemberID else { return }
        guard submissionHasNext else { return }
        guard !isLoadingMoreSubmissions else { return }

        let requestID = submissionRequestID
        isLoadingMoreSubmissions = true
        defer { isLoadingMoreSubmissions = false }

        do {
            let nextPage = try await useCase.fetchStudyMemberSubmissions(
                studyGroupId: selectedSubmissionGroupId,
                weekNos: selectedSubmissionWeekNos,
                cursor: submissionNextCursor,
                size: Constants.submissionPageSize
            )
            // 필터가 바뀐 뒤 도착한 이전 필터의 페이지는 목록에 붙이지 않는다.
            guard requestID == submissionRequestID else { return }

            let existingIDs = Set(submissions.map(\.studyGroupMemberId))
            let newRows = nextPage.content.filter {
                !existingIDs.contains($0.studyGroupMemberId)
            }
            if !newRows.isEmpty {
                submissions.append(contentsOf: newRows)
                submissionsState = .loaded(submissions)
            }

            submissionNextCursor = nextPage.nextCursor
            submissionHasNext = nextPage.hasNext
        } catch is CancellationError {
            // 뷰 라이프사이클 취소 — 실패가 아니므로 목록을 그대로 둔다.
        } catch let error as DomainError {
            // 성공 경로와 마찬가지로 필터가 바뀐 뒤 도착한 실패는 무시한다. 사용자가 이미 다른
            // 조건을 보고 있는데 이전 조건의 실패 안내가 뜨면 오해를 준다.
            guard requestID == submissionRequestID else { return }
            presentAlert(title: "불러오지 못했어요", message: error.userMessage)
        } catch {
            guard requestID == submissionRequestID else { return }
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "fetchMoreStudyMemberSubmissions"
            ))
        }
    }

    // MARK: - Function (멤버 / 멘토 변경)

    /// Sheet dismiss 시 호출 — 변경된 스터디원 목록을 서버에 반영
    func applySelectedChallengers() async {
        guard let targetGroup = memberUpdateTargetGroup,
              let index = studyGroupDetails.firstIndex(
                  where: { $0.id == targetGroup.id }
              )
        else {
            resetMemberSelection()
            return
        }

        guard isPersistedServerGroup(targetGroup.serverID) else {
            presentAlert(title: "변경 실패", message: "유효하지 않은 그룹 ID입니다.")
            resetMemberSelection()
            return
        }
        let serverGroupId = targetGroup.serverID

        let currentMemberIDs = Set(
            studyGroupDetails[index].members.compactMap(\.memberID).filter(Self.isUsableID)
        )
        guard selectedChallengers.allSatisfy({ Self.isUsableID($0.memberId) }) else {
            presentAlert(title: "변경 실패", message: "선택한 회원의 ID를 확인하지 못했습니다.")
            resetMemberSelection()
            return
        }
        let updatedMemberIDs = Set(selectedChallengers.map(\.memberId))

        if currentMemberIDs == updatedMemberIDs {
            resetMemberSelection()
            return
        }

        let toAdd = updatedMemberIDs.subtracting(currentMemberIDs)
        let toRemove = currentMemberIDs.subtracting(updatedMemberIDs)

        let failures = await applyMembershipChanges(
            groupId: serverGroupId,
            toAdd: toAdd,
            toRemove: toRemove,
            add: useCase.addStudyGroupMember,
            remove: useCase.removeStudyGroupMember,
            addFailureMessage: "멤버 추가 실패",
            removeFailureMessage: "멤버 제거 실패"
        )

        if failures.isEmpty {
            var seen = Set<String>()
            studyGroupDetails[index].members = selectedChallengers
                .filter { seen.insert($0.memberId).inserted }
                .map {
                    studyGroupMember(from: $0)
                }
        } else {
            presentAlert(
                title: "일부 변경 실패",
                message: failures.joined(separator: "\n")
            )
            refreshStudyGroupManagementDataInBackground()
        }

        resetMemberSelection()
    }

    /// 멘토 시트 dismiss 시 호출 — 변경된 멘토 목록을 서버에 반영
    func applySelectedMentors() async {
        guard let targetGroup = mentorUpdateTargetGroup,
              let index = studyGroupDetails.firstIndex(
                  where: { $0.id == targetGroup.id }
              )
        else {
            resetMentorSelection()
            return
        }

        guard isPersistedServerGroup(targetGroup.serverID) else {
            presentAlert(title: "변경 실패", message: "유효하지 않은 그룹 ID입니다.")
            resetMentorSelection()
            return
        }
        let serverGroupId = targetGroup.serverID

        guard !selectedMentors.isEmpty else {
            presentAlert(title: "변경 실패", message: "최소 1명의 멘토가 필요합니다.")
            resetMentorSelection()
            return
        }

        let currentMemberIDs = Set(
            studyGroupDetails[index].mentors.compactMap(\.memberID).filter(Self.isUsableID)
        )
        guard selectedMentors.allSatisfy({ Self.isUsableID($0.memberId) }) else {
            presentAlert(title: "변경 실패", message: "선택한 회원의 ID를 확인하지 못했습니다.")
            resetMentorSelection()
            return
        }
        let updatedMemberIDs = Set(selectedMentors.map(\.memberId))

        if currentMemberIDs == updatedMemberIDs {
            resetMentorSelection()
            return
        }

        let toAdd = updatedMemberIDs.subtracting(currentMemberIDs)
        let toRemove = currentMemberIDs.subtracting(updatedMemberIDs)

        let failures = await applyMembershipChanges(
            groupId: serverGroupId,
            toAdd: toAdd,
            toRemove: toRemove,
            add: useCase.addStudyGroupMentor,
            remove: useCase.removeStudyGroupMentor,
            addFailureMessage: "멘토 추가 실패",
            removeFailureMessage: "멘토 제거 실패"
        )

        if failures.isEmpty {
            var seen = Set<String>()
            studyGroupDetails[index].mentors = selectedMentors
                .filter { seen.insert($0.memberId).inserted }
                .map {
                    studyGroupMember(from: $0, role: .leader)
                }
        } else {
            presentAlert(
                title: "일부 변경 실패",
                message: failures.joined(separator: "\n")
            )
            refreshStudyGroupManagementDataInBackground()
        }

        resetMentorSelection()
    }

    /// 멤버 단건 삭제 (chip context menu)
    func removeMember(_ member: StudyGroupMember, from group: StudyGroupInfo) async {
        guard isPersistedServerGroup(group.serverID),
              let memberId = member.memberID, Self.isUsableID(memberId),
              let index = studyGroupDetails.firstIndex(where: { $0.id == group.id })
        else {
            presentAlert(title: "삭제 실패", message: "유효하지 않은 식별자입니다.")
            return
        }

        do {
            try await useCase.removeStudyGroupMember(
                groupId: group.serverID,
                memberId: memberId
            )
            studyGroupDetails[index].members.removeAll { $0.id == member.id }
        } catch let error as DomainError {
            presentAlert(title: "삭제 실패", message: error.userMessage)
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "removeStudyGroupMember"
            ))
        }
    }

    /// 멘토 단건 삭제 (chip context menu)
    ///
    /// 마지막 멘토 삭제는 차단합니다.
    func removeMentor(_ mentor: StudyGroupMember, from group: StudyGroupInfo) async {
        guard let index = studyGroupDetails.firstIndex(where: { $0.id == group.id }) else {
            return
        }

        guard studyGroupDetails[index].mentors.count > 1 else {
            presentAlert(title: "삭제 불가", message: "최소 1명의 멘토는 유지되어야 합니다.")
            return
        }

        guard isPersistedServerGroup(group.serverID),
              let memberId = mentor.memberID, Self.isUsableID(memberId)
        else {
            presentAlert(title: "삭제 실패", message: "유효하지 않은 식별자입니다.")
            return
        }

        do {
            try await useCase.removeStudyGroupMentor(
                groupId: group.serverID,
                mentorId: memberId
            )
            studyGroupDetails[index].mentors.removeAll { $0.id == mentor.id }
        } catch let error as DomainError {
            presentAlert(title: "삭제 실패", message: error.userMessage)
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "removeStudyGroupMentor"
            ))
        }
    }

    // MARK: - Function (그룹 CRUD)

    /// 그룹 이름 수정 적용
    /// - Parameters:
    ///   - groupID: 수정할 그룹 ID
    ///   - name: 새 그룹명
    func updateGroup(groupID: UUID, name: String) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            presentAlert(title: "수정 실패", message: "그룹 이름을 입력해 주세요.")
            return false
        }

        guard let oldGroup = studyGroupDetails.first(where: { $0.id == groupID }) else {
            presentAlert(title: "수정 실패", message: "그룹 정보를 찾을 수 없습니다.")
            return false
        }

        guard isPersistedServerGroup(oldGroup.serverID) else {
            presentAlert(title: "수정 실패", message: "유효한 그룹 식별자가 아닙니다.")
            return false
        }

        do {
            try await useCase.updateStudyGroup(
                groupId: oldGroup.serverID,
                name: trimmedName
            )
        } catch let error as DomainError {
            presentAlert(title: "수정 실패", message: error.userMessage)
            return false
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "updateStudyGroup"
            ))
            return false
        }

        guard let index = studyGroupDetails.firstIndex(where: { $0.id == groupID }) else {
            presentAlert(title: "수정 실패", message: "그룹이 삭제되어 수정할 수 없습니다.")
            return false
        }

        let old = studyGroupDetails[index]
        studyGroupDetails[index] = StudyGroupInfo(
            id: old.id,
            serverID: old.serverID,
            gisuId: old.gisuId,
            studyPart: old.studyPart,
            name: trimmedName,
            part: old.part,
            createdDate: old.createdDate,
            mentors: old.mentors,
            members: old.members
        )
        return true
    }

    /// 새 스터디 그룹 생성 (ChallengerInfo → StudyGroupMember 변환)
    /// - Parameters:
    ///   - name: 그룹명
    ///   - part: 파트
    ///   - mentors: 담당 파트장(멘토) 목록 (1명 이상)
    ///   - members: 스터디원 목록
    func createGroup(
        name: String,
        part: UMCPartType,
        mentors: [ChallengerInfo],
        members: [ChallengerInfo]
    ) async -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            presentAlert(title: "그룹 생성 실패", message: "그룹 이름을 입력해 주세요.")
            return false
        }

        guard let mentorSelection = validatedSelection(mentors),
              let memberSelection = validatedSelection(members) else {
            presentAlert(
                title: "그룹 생성 실패",
                message: "선택한 회원의 ID가 올바르지 않습니다. 회원을 다시 선택해 주세요."
            )
            return false
        }
        guard !mentorSelection.ids.isEmpty else {
            presentAlert(
                title: "그룹 생성 실패",
                message: "최소 1명의 담당 파트장(멘토)이 필요합니다."
            )
            return false
        }
        guard !memberSelection.ids.isEmpty else {
            presentAlert(title: "그룹 생성 실패", message: "최소 1명의 스터디원이 필요합니다.")
            return false
        }

        guard let gisuId = gisuIdProvider(), Self.isUsableID(gisuId) else {
            presentAlert(
                title: "그룹 생성 실패",
                message: "현재 기수 정보를 확인할 수 없습니다."
            )
            return false
        }

        do {
            try await useCase.createStudyGroup(
                gisuId: gisuId,
                name: trimmedName,
                part: part,
                memberIds: memberSelection.ids,
                mentorIds: mentorSelection.ids
            )
            appendCreatedGroupToLocalState(
                gisuId: gisuId,
                name: trimmedName,
                part: part,
                mentors: mentorSelection.challengers,
                members: memberSelection.challengers
            )
            refreshStudyGroupManagementDataInBackground()

            return true
        } catch let error as DomainError {
            presentAlert(title: "그룹 생성 실패", message: error.userMessage)
            return false
        } catch let error as NetworkError {
            if presentStudyGroupCreateAlert(from: error) {
                return false
            }
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "createStudyGroup"
            ))
            return false
        } catch let error as RepositoryError {
            if presentStudyGroupCreateAlert(from: error) {
                return false
            }
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "createStudyGroup"
            ))
            return false
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "createStudyGroup"
            ))
            return false
        }
    }

    /// 그룹 삭제 API 호출
    func deleteGroup(_ group: StudyGroupInfo) async {
        guard isPersistedServerGroup(group.serverID) else {
            presentAlert(title: "삭제 실패", message: "유효하지 않은 그룹 ID입니다.")
            return
        }

        do {
            try await useCase.deleteStudyGroup(groupId: group.serverID)
            removeGroupFromLocalState(group.serverID)
        } catch let error as DomainError {
            presentAlert(title: "삭제 실패", message: error.userMessage)
        } catch {
            errorHandler.handle(error, context: ErrorContext(
                feature: "Activity",
                action: "deleteStudyGroup"
            ))
        }
    }

    // MARK: - Function (시트 표시)

    /// 그룹 편집 시트 표시
    func showEditSheet(for group: StudyGroupInfo) {
        editingName = group.name
        editingGroup = group
    }

    /// 멤버 추가 시트 표시
    func showAddMemberSheet(for group: StudyGroupInfo) {
        memberUpdateTargetGroup = group
        selectedChallengers = group.members.map { challengerInfo(from: $0, part: group.part, generation: generation(for: group)) }
        addMemberGroup = group
    }

    /// 멘토 추가 시트 표시
    func showAddMentorSheet(for group: StudyGroupInfo) {
        mentorUpdateTargetGroup = group
        selectedMentors = group.mentors.map { challengerInfo(from: $0, part: group.part, generation: generation(for: group)) }
        addMentorGroup = group
    }

    private func validatedSelection(
        _ challengers: [ChallengerInfo]
    ) -> (ids: [String], challengers: [ChallengerInfo])? {
        var ids: [String] = []
        var selected: [ChallengerInfo] = []
        var seen = Set<Int64>()
        for challenger in challengers {
            let rawID = challenger.memberId
            guard !rawID.isEmpty, rawID.allSatisfy({ $0.isASCII && $0.isNumber }),
                  let id = Int64(rawID), id > 0 else { return nil }
            if seen.insert(id).inserted {
                ids.append(String(id))
                selected.append(challenger)
            }
        }
        return (ids, selected)
    }

    // MARK: - Private (로컬 상태 반영)

    private func appendCreatedGroupToLocalState(
        gisuId: String,
        name: String,
        part: UMCPartType,
        mentors: [ChallengerInfo],
        members: [ChallengerInfo]
    ) {
        let localServerID = "\(Constants.localGroupIDPrefix)\(UUID().uuidString)"
        let mentorMembers: [StudyGroupMember] = mentors.map { mentor in
            studyGroupMember(
                from: mentor,
                role: .leader
            )
        }
        let localGroup = StudyGroupInfo(
            serverID: localServerID,
            gisuId: gisuId,
            studyPart: part.apiValue,
            name: name,
            part: part,
            createdDate: Date(),
            mentors: mentorMembers,
            members: members.map { studyGroupMember(from: $0) }
        )

        switch studyGroupDetailsState {
        case .loaded:
            studyGroupDetails.insert(localGroup, at: 0)
            studyGroupDetailsState = .loaded(studyGroupDetails)
        case .idle:
            studyGroupDetails = [localGroup]
            studyGroupDetailsState = .loaded(studyGroupDetails)
        case .loading, .failed:
            break
        }
    }

    private func refreshStudyGroupManagementDataInBackground() {
        // 새로고침 전에 사용자가 스크롤로 로드해 둔 항목 수(로드 윈도우)를 기억한다.
        // 낙관적 placeholder(`new_`)는 아직 서버에 없으므로 목표 길이 계산에서 제외한다.
        let targetCount = max(
            studyGroupDetails.filter { isPersistedServerGroup($0.serverID) }.count,
            Constants.groupManagementPageSize
        )

        Task { [weak self] in
            guard let self else { return }

            do {
                // 첫 페이지만 덮어써 뒤쪽 페이지를 잘라내던 문제를 방지한다.
                // 첫 페이지부터 다시 페이지네이션해 기존 로드 윈도우 길이를 복원한다.
                var restored: [StudyGroupInfo] = []
                var seenServerIDs = Set<String>()
                var cursor: String?
                var hasNext = true

                repeat {
                    let page = try await self.useCase.fetchStudyGroupDetailsPage(
                        cursor: cursor,
                        size: Constants.groupManagementPageSize
                    )
                    for group in page.content {
                        guard seenServerIDs.insert(group.serverID).inserted else { continue }
                        restored.append(group)
                    }
                    cursor = page.nextCursor
                    hasNext = page.hasNext
                } while hasNext && restored.count < targetCount

                self.studyGroupDetails = restored
                self.studyGroupDetailsNextCursor = cursor
                self.studyGroupDetailsHasNext = hasNext
                self.studyGroupDetailsState = .loaded(restored)
            } catch {
                // 생성 자체는 성공했으나 목록 재동기화에 실패한 경우.
                // 낙관적 `new_` placeholder 가 남아 관리(수정/삭제)가 막히므로,
                // 실패를 삼키지 않고 사용자에게 노출해 수동 새로고침을 유도한다.
                self.errorHandler.handle(error, context: ErrorContext(
                    feature: "Activity",
                    action: "refreshStudyGroupManagementAfterCreate"
                ))
            }
        }
    }

    /// 삭제 성공 후 로컬 상태에서 그룹 삭제 반영
    private func removeGroupFromLocalState(_ serverID: String) {
        studyGroupDetails.removeAll { $0.serverID == serverID }
        studyGroupDetailsState = .loaded(studyGroupDetails)
    }

    // MARK: - Private (그룹 생성 실패 메시지)

    private func presentStudyGroupCreateAlert(from error: NetworkError) -> Bool {
        guard case .requestFailed(let statusCode, let data) = error else {
            return false
        }

        // 로컬 Alert 로 소화하는 대상은 403(권한) 에러뿐이다.
        // 그 외 상태코드(401 세션 만료·404·409·5xx 등)는 서버 응답 본문에 message 필드가
        // 있더라도 여기서 처리하지 않고 false 를 반환해, 호출부가 errorHandler(로깅/세션 처리)로
        // 흘려보내도록 한다.
        guard statusCode == 403 else { return false }

        let message = authorizationFailureMessage(from: data)
            ?? decodeServerMessage(from: data)

        guard let message else { return false }

        presentAlert(title: "그룹 생성 실패", message: message)
        return true
    }

    private func presentStudyGroupCreateAlert(from error: RepositoryError) -> Bool {
        guard case .serverError(let code, let message) = error else {
            return false
        }

        // 로컬 Alert 로 소화하는 대상은 권한 거부 코드뿐이다(형제 `NetworkError` 오버로드의
        // `statusCode == 403` 게이트와 동일 범위). 그 외 실패(세션 만료·5xx·미정의 코드)는
        // message 가 있더라도 여기서 처리하지 않고 false 를 반환해, 호출부가
        // errorHandler(로깅/세션 처리)로 흘려보내도록 한다.
        let errorCode = code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard Constants.permissionDeniedServerCodes.contains(errorCode) else {
            return false
        }

        let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return false }

        presentAlert(title: "그룹 생성 실패", message: trimmed)
        return true
    }

    /// 403 그룹 생성 실패 중 `AUTHORIZATION-0002` 코드에 대한 권한 안내 메시지.
    ///
    /// 호출부(`presentStudyGroupCreateAlert(from:)`)가 이미 `statusCode == 403` 을 보장하므로
    /// 여기서는 에러 코드만 판별한다. 다른 403 코드는 nil 을 반환해, 호출부가 서버 메시지
    /// fallback(`decodeServerMessage`)으로 처리하게 한다.
    private func authorizationFailureMessage(from data: Data?) -> String? {
        let payload = decodeServerErrorPayload(from: data)
        let errorCode = payload?.code?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard errorCode == "AUTHORIZATION-0002" else {
            return nil
        }

        return """
        현재 계정 권한으로는 스터디 그룹을 생성할 수 없습니다.
        서버 권한 수정 전까지 총괄 계정에서는 생성이 제한될 수 있습니다.
        """
    }

    private func decodeServerMessage(from data: Data?) -> String? {
        let payload = decodeServerErrorPayload(from: data)
        let message = payload?.message ?? payload?.result ?? payload?.error
        let trimmed = message?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func decodeServerErrorPayload(from data: Data?) -> ServerErrorPayload? {
        guard let data,
              let payload = try? JSONDecoder().decode(ServerErrorPayload.self, from: data) else {
            return nil
        }
        return payload
    }

    private struct ServerErrorPayload: Decodable {
        let code: String?
        let message: String?
        let result: String?
        let error: String?
    }

    // MARK: - Private (Helper)

    /// 멤버/멘토 추가·제거를 순차 적용하고 실패 메시지를 모읍니다.
    /// `add`/`remove` 는 대상 UseCase 메서드(`(groupId, memberId)`)이며,
    /// 실패 시 도메인 메시지 또는 기본 메시지를 누적해 반환합니다.
    private func applyMembershipChanges(
        groupId: String,
        toAdd: Set<String>,
        toRemove: Set<String>,
        add: (String, String) async throws -> Void,
        remove: (String, String) async throws -> Void,
        addFailureMessage: String,
        removeFailureMessage: String
    ) async -> [String] {
        var failures: [String] = []
        for memberId in toAdd {
            do {
                try await add(groupId, memberId)
            } catch let error as DomainError {
                failures.append(error.userMessage)
            } catch {
                failures.append(addFailureMessage)
            }
        }
        for memberId in toRemove {
            do {
                try await remove(groupId, memberId)
            } catch let error as DomainError {
                failures.append(error.userMessage)
            } catch {
                failures.append(removeFailureMessage)
            }
        }
        return failures
    }

    /// 유효한 서버 식별자(비어있지 않고 `"0"` 이 아님) 여부.
    /// 레거시 `Int > 0` 판정을 `String` 세계로 옮긴 것 — `"0"`/빈 문자열은 미해석 ID 로 간주.
    private static func isUsableID(_ id: String) -> Bool {
        !id.isEmpty && id != "0"
    }

    /// 서버에 실재하는 그룹인지 — 낙관적 삽입 placeholder 는 서버 호출 대상이 아님.
    private func isPersistedServerGroup(_ serverID: String) -> Bool {
        !serverID.isEmpty && !serverID.hasPrefix(Constants.localGroupIDPrefix)
    }

    // MARK: - Function (제출 현황 · 내부)

    /// 현재 필터로 첫 페이지부터 다시 조회한다. 호출마다 새 요청 토큰을 발급한다.
    ///
    /// `.task` 취소로 던져지는 에러는 실패가 아니므로 이전 상태로 되돌려, 화면 이탈·필터 연타
    /// 직후에 허위 에러 카드가 뜨지 않게 한다 (형제 ViewModel 의 취소-우선 롤백 관례).
    /// - Parameters:
    ///   - groupId: 적용할 그룹 필터
    ///   - weekNos: 적용할 주차 필터
    private func reloadSubmissions(groupId: String?, weekNos: [String]) async {
        submissionRequestID += 1
        let requestID = submissionRequestID
        // 롤백 대상이 `.loading` 이면(로딩 중 필터를 탭한 경우) 취소 시 in-flight 없는 `.loading`
        // 으로 되돌아가 화면이 스피너에 갇힌다. 되돌릴 수 있는 상태만 스냅샷으로 남긴다.
        let previousState: Loadable<[StudyMemberSubmission]> =
            submissions.isEmpty ? .idle : .loaded(submissions)
        let previousGroupId = selectedSubmissionGroupId
        let previousWeekNos = selectedSubmissionWeekNos
        // 커서도 함께 되돌린다. 아래에서 초기화만 하고 복원하지 않으면, 취소된 필터 변경 뒤
        // 남는 목록은 `hasNext == false` 라 스크롤해도 다음 페이지를 못 부른다.
        let previousCursor = submissionNextCursor
        let previousHasNext = submissionHasNext
        let previousWeeksState = submissionWeeksState
        let previousWeeksGroupId = loadedWeeksGroupId

        // 필터 적용과 그 롤백을 한 곳에 둔다. 필터만 바뀌고 조회가 취소되면 칩은 새 필터를,
        // 목록은 옛 필터의 결과를 가리켜 둘이 어긋난 채로 굳는다.
        selectedSubmissionGroupId = groupId
        selectedSubmissionWeekNos = weekNos

        isReloadingSubmissions = true
        defer {
            if requestID == submissionRequestID { isReloadingSubmissions = false }
        }

        submissionsState = .loading
        isLoadingMoreSubmissions = false
        submissionNextCursor = nil
        submissionHasNext = false

        do {
            if loadedWeeksGroupId != groupId || submissionWeeksState.value == nil {
                submissionWeeksState = .loading
                let weeks = try await useCase.fetchStudySubmissionWeeks(studyGroupId: groupId)
                guard requestID == submissionRequestID else { return }
                let options = Array(Set(weeks)).sorted {
                    (Int($0) ?? 0) < (Int($1) ?? 0)
                }
                submissionWeeksState = .loaded(options)
                loadedWeeksGroupId = groupId
            }
            selectedSubmissionWeekNos = weekNos.filter(availableSubmissionWeekNos.contains)
            let page = try await useCase.fetchStudyMemberSubmissions(
                studyGroupId: selectedSubmissionGroupId,
                weekNos: selectedSubmissionWeekNos,
                cursor: nil,
                size: Constants.submissionPageSize
            )
            guard requestID == submissionRequestID else { return }

            submissions = page.content
            submissionNextCursor = page.nextCursor
            submissionHasNext = page.hasNext
            submissionsState = .loaded(submissions)
            loadedSubmissionGroupId = groupId
            loadedSubmissionWeekNos = selectedSubmissionWeekNos
        } catch is CancellationError {
            guard requestID == submissionRequestID else { return }
            submissionWeeksState = previousWeeksState.isLoading ? .idle : previousWeeksState
            loadedWeeksGroupId = previousWeeksGroupId
            rollbackSubmissions(
                state: previousState,
                groupId: previousGroupId,
                weekNos: previousWeekNos,
                cursor: previousCursor,
                hasNext: previousHasNext
            )
        } catch let error as NSError
            where error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled {
            guard requestID == submissionRequestID else { return }
            submissionWeeksState = previousWeeksState.isLoading ? .idle : previousWeeksState
            loadedWeeksGroupId = previousWeeksGroupId
            rollbackSubmissions(
                state: previousState,
                groupId: previousGroupId,
                weekNos: previousWeekNos,
                cursor: previousCursor,
                hasNext: previousHasNext
            )
        } catch let error as AppError {
            guard requestID == submissionRequestID else { return }
            submissionsState = .failed(error)
        } catch let error as DomainError {
            guard requestID == submissionRequestID else { return }
            submissionsState = .failed(.domain(error))
        } catch let error as NetworkError {
            guard requestID == submissionRequestID else { return }
            submissionsState = .failed(.network(error))
        } catch let error as RepositoryError {
            guard requestID == submissionRequestID else { return }
            submissionsState = .failed(.repository(error))
        } catch {
            guard requestID == submissionRequestID else { return }
            submissionsState = .failed(.unknown(
                message: "제출 현황을 불러오지 못했습니다."
            ))
        }
        if submissionWeeksState.isLoading, case .failed(let error) = submissionsState {
            submissionWeeksState = .failed(error)
        }
    }

    /// 취소된 조회 이전으로 목록·필터·페이지 커서를 한꺼번에 되돌린다.
    ///
    /// 하나라도 빠뜨리면 화면이 서로 다른 조회를 가리키게 된다 — 목록만 되돌리면 칩과 어긋나고,
    /// 커서를 빠뜨리면 남은 목록이 다음 페이지를 못 부른다. 그래서 한 함수로 묶는다.
    private func rollbackSubmissions(
        state: Loadable<[StudyMemberSubmission]>,
        groupId: String?,
        weekNos: [String],
        cursor: String?,
        hasNext: Bool
    ) {
        submissionsState = state
        selectedSubmissionGroupId = groupId
        selectedSubmissionWeekNos = weekNos
        submissionNextCursor = cursor
        submissionHasNext = hasNext
    }

    /// 그룹 필터 후보를 한 번만 조회한다.
    ///
    /// 필터 보조 정보라 실패해도 화면을 막지 않는다 — 후보가 비면 "전체" 만 노출된다.
    private func loadStudyGroupNamesIfNeeded() async {
        guard studyGroupNames.isEmpty else { return }
        studyGroupNames = (try? await useCase.fetchStudyGroupNames()) ?? []
    }

    private func presentAlert(title: String, message: String) {
        alertPrompt = AlertPrompt(
            title: title,
            message: message,
            positiveBtnTitle: "확인"
        )
    }

    private func resetMemberSelection() {
        selectedChallengers = []
        memberUpdateTargetGroup = nil
    }

    private func resetMentorSelection() {
        selectedMentors = []
        mentorUpdateTargetGroup = nil
    }

    private func challengerInfo(
        from member: StudyGroupMember,
        part: UMCPartType,
        generation: String?
    ) -> ChallengerInfo {
        ChallengerInfo(
            memberId: member.memberID ?? member.serverID,
            challengerId: member.challengerID ?? member.memberID ?? member.serverID,
            gen: generation ?? "",
            name: member.name,
            nickname: member.nickname ?? member.name,
            schoolName: member.university,
            profileImage: member.profileImageURL,
            part: part
        )
    }

    private func studyGroupMember(
        from challenger: ChallengerInfo,
        role: StudyGroupMember.MemberRole = .member
    ) -> StudyGroupMember {
        StudyGroupMember(
            serverID: challenger.memberId,
            challengerID: challenger.challengerId,
            memberID: challenger.memberId,
            name: challenger.name,
            nickname: challenger.nickname,
            university: challenger.schoolName,
            profileImageURL: challenger.profileImage,
            role: role
        )
    }
}
