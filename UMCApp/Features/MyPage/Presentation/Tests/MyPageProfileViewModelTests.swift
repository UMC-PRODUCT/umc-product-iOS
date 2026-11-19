//
//  MyPageProfileViewModelTests.swift
//  MyPagePresentationTests
//
//  Created by 김동민 on 7/13/26.
//

import Testing
import Foundation
import UIKit
import UMCFoundation
import AuthDomain
import BusinessCardDomain
import CoreDomain
import CoreNetwork
import MyPageDomain
@testable import MyPagePresentation

@MainActor
@Suite("MyPageProfileViewModel — 제출 가능 여부 / 이미지·연락처 수정 / 활동 이력 추가")
struct MyPageProfileViewModelTests {

    // MARK: - canSubmit

    @Test("변경이 없으면 canSubmit은 false")
    func canSubmitFalseWithoutChanges() async {
        let viewModel = makeViewModel(profile: makeStubProfileData())
        await viewModel.loadContactSettings()
        #expect(viewModel.canSubmit == false)
    }

    @Test("이미지를 선택하면 canSubmit은 true")
    func canSubmitTrueAfterImageSelection() async {
        let viewModel = makeViewModel(profile: makeStubProfileData())

        await viewModel.didLoadImage(image: makeStubImage())

        #expect(viewModel.canSubmit == true)
    }

    @Test("연락처·링크를 불러온 뒤 링크가 바뀌면 canSubmit은 true")
    func canSubmitTrueAfterLinkChange() async {
        let viewModel = makeViewModel(profile: makeStubProfileData())
        await viewModel.loadContactSettings()

        viewModel.contactSettings.links[.github] = CardContactItem(
            value: "https://github.com/tester", isPublic: true
        )

        #expect(viewModel.canSubmit == true)
    }

    @Test("공개 여부만 바꿔도 canSubmit은 true")
    func canSubmitTrueAfterVisibilityChange() async {
        let viewModel = makeViewModel(profile: makeStubProfileData())
        await viewModel.loadContactSettings()

        viewModel.contactSettings.isEmailPublic = false

        #expect(viewModel.canSubmit == true)
    }

    /// 비교할 저장값이 없으면 무엇이 바뀌었는지 알 수 없다 — 빈 값으로 저장해 서버 값을 지우면 안 된다.
    @Test("연락처·링크를 불러오기 전에는 입력이 바뀌어도 canSubmit은 false")
    func canSubmitFalseBeforeContactsLoad() {
        let viewModel = makeViewModel(profile: makeStubProfileData())

        viewModel.contactSettings.links[.github] = CardContactItem(
            value: "https://github.com/tester", isPublic: true
        )

        #expect(viewModel.canSubmit == false)
    }

    // MARK: - loadContactSettings

    @Test("연락처·링크 조회 성공 — 편집값과 저장값을 서버 값으로 채운다")
    func loadContactSettingsFillsValues() async {
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(profile: makeStubProfileData(), contacts: contacts)

        await viewModel.loadContactSettings()

        #expect(viewModel.contactSettings == makeStoredContacts())
        #expect(viewModel.savedContactSettings == .loaded(makeStoredContacts()))
    }

    @Test("연락처·링크 조회 실패 — failed로 두고, 재시도하면 다시 읽는다")
    func loadContactSettingsFailureAllowsRetry() async {
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        contacts.fetchError = MyPageTestError.boom
        let viewModel = makeViewModel(profile: makeStubProfileData(), contacts: contacts)

        await viewModel.loadContactSettings()
        #expect(viewModel.savedContactSettings.error != nil)

        contacts.fetchError = nil
        await viewModel.loadContactSettings()
        #expect(contacts.fetchCallCount == 2)
        #expect(viewModel.savedContactSettings == .loaded(makeStoredContacts()))
    }

    @Test("이미 불러왔으면 다시 읽지 않아 편집 중인 값을 덮지 않는다")
    func loadContactSettingsKeepsEdits() async {
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(profile: makeStubProfileData(), contacts: contacts)
        await viewModel.loadContactSettings()

        viewModel.contactSettings.isEmailPublic = false
        await viewModel.loadContactSettings()

        #expect(contacts.fetchCallCount == 1)
        #expect(viewModel.contactSettings.isEmailPublic == false)
    }

    // MARK: - 링크 우선순위 (#1679)

    @Test("저장된 링크 순서를 불러오고, 줄을 옮기면 canSubmit은 true")
    func loadsAndMovesLinkPriority() async {
        let linkPriority = StubLinkPriorityUseCase()
        linkPriority.stored = [.blog, .github, .linkedIn, .instagram, .personal]
        let viewModel = makeViewModel(profile: makeStubProfileData(), linkPriority: linkPriority)

        await viewModel.loadLinkPriority()
        #expect(viewModel.linkPriority == [.blog, .github, .linkedin, .instagram, .personal])
        #expect(viewModel.canSubmit == false)

        viewModel.moveLinks(fromOffsets: IndexSet(integer: 4), toOffset: 0)

        #expect(viewModel.linkPriority.first == .personal)
        #expect(viewModel.canSubmit == true)
    }

    @Test("순서를 바꾸는 중에 다시 불러와도 바꾼 순서를 덮지 않는다")
    func reloadKeepsEditedPriority() async {
        let viewModel = makeViewModel(profile: makeStubProfileData())
        await viewModel.loadLinkPriority()
        viewModel.moveLinks(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        await viewModel.loadLinkPriority()

        #expect(viewModel.linkPriority.first == .blog)
    }

    @Test("순서만 바꿔 submit하면 기기에만 저장하고 서버 요청은 보내지 않는다")
    func submitPriorityOnlySavesLocally() async throws {
        let mock = MockMyPageRepository()
        let linkPriority = StubLinkPriorityUseCase()
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(
            profile: makeStubProfileData(), repository: mock, contacts: contacts,
            linkPriority: linkPriority
        )
        await viewModel.loadContactSettings()
        await viewModel.loadLinkPriority()
        viewModel.moveLinks(fromOffsets: IndexSet(integer: 4), toOffset: 0)

        try await viewModel.submitProfileUpdate()

        #expect(linkPriority.saved == [.personal, .github, .linkedIn, .blog, .instagram])
        #expect(mock.updateProfileImageCallCount == 0)
        #expect(contacts.updateCallCount == 0)
        #expect(viewModel.canSubmit == false)
    }

    @Test("순서 저장이 실패하면 사진을 올리지 않고, 다시 저장할 수 있게 변경을 남긴다")
    func priorityFailureStopsBeforeUpload() async {
        let mock = MockMyPageRepository()
        let linkPriority = StubLinkPriorityUseCase()
        linkPriority.saveError = MyPageTestError.boom
        let viewModel = makeViewModel(
            profile: makeStubProfileData(), repository: mock, linkPriority: linkPriority
        )
        await viewModel.loadLinkPriority()
        viewModel.moveLinks(fromOffsets: IndexSet(integer: 4), toOffset: 0)
        await viewModel.didLoadImage(image: makeStubImage())

        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.submitProfileUpdate()
        }

        #expect(mock.updateProfileImageCallCount == 0)
        #expect(viewModel.canSubmit == true)
    }

    // MARK: - submitProfileUpdate

    @Test("변경 없이 submit하면 어떤 UseCase도 호출하지 않음 (no-op)")
    func submitWithoutChangesIsNoOp() async throws {
        let mock = MockMyPageRepository()
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(
            profile: makeStubProfileData(), repository: mock, contacts: contacts
        )
        await viewModel.loadContactSettings()

        try await viewModel.submitProfileUpdate()

        #expect(mock.updateProfileImageCallCount == 0)
        #expect(contacts.updateCallCount == 0)
    }

    @Test("이미지 변경 submit — updateProfileImage 호출 + jpeg 메타데이터 + socialConnections 보존")
    func submitImageUpdateCallsImageUseCase() async throws {
        let original = makeStubProfileData(
            challengeId: 1,
            socialConnections: [SocialConnection(memberOAuthId: "10", socialType: .kakao)]
        )
        // 서버 응답의 socialConnections가 비어 있어도 VM이 로컬 값을 복원해야 함
        let serverProfile = makeStubProfileData(challengeId: 42, socialConnections: [])
        let mock = MockMyPageRepository()
        mock.updateProfileImageResult = .success(serverProfile)
        let viewModel = makeViewModel(profile: original, repository: mock)

        await viewModel.didLoadImage(image: makeStubImage())
        try await viewModel.submitProfileUpdate()

        #expect(mock.updateProfileImageCallCount == 1)
        #expect(mock.updateProfileImageReceivedContentType == "image/jpeg")
        #expect(mock.updateProfileImageReceivedFileName?.hasPrefix("profile_") == true)
        #expect(mock.updateProfileImageReceivedFileName?.hasSuffix(".jpg") == true)
        #expect(viewModel.profileData.challengeId == 42)
        #expect(viewModel.profileData.socialConnections == original.socialConnections)
        // 제출 후 선택 상태 초기화
        #expect(viewModel.selectedPhotoItem == nil)
        #expect(viewModel.isUpdatingProfileImage == false)
        #expect(viewModel.canSubmit == false)
    }

    @Test("고해상도 이미지 submit — 긴 변 1024px로 줄인 5MB 이하 JPEG 업로드")
    func submitLargeImageUploadsResizedJPEG() async throws {
        let mock = MockMyPageRepository()
        mock.updateProfileImageResult = .success(makeStubProfileData())
        let viewModel = makeViewModel(profile: makeStubProfileData(), repository: mock)

        let largeImage = makeSolidImage(pixelSize: CGSize(width: 2048, height: 1536))
        await viewModel.didLoadImage(image: largeImage)
        try await viewModel.submitProfileUpdate()

        let uploadedData = try #require(mock.updateProfileImageReceivedImageData)
        let uploadedImage = try #require(UIImage(data: uploadedData))
        #expect(uploadedImage.size == CGSize(width: 1024, height: 768))
        #expect(uploadedData.count <= 5 * 1024 * 1024)
    }

    @Test("연락처·링크 변경 submit — 편집하지 않은 항목까지 전체를 저장하고 저장값을 기준으로 삼는다")
    func submitContactUpdateSendsWholeSettings() async throws {
        let mock = MockMyPageRepository()
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(
            profile: makeStubProfileData(), repository: mock, contacts: contacts
        )
        await viewModel.loadContactSettings()

        viewModel.contactSettings.links[.github]?.value = "https://github.com/new"
        viewModel.contactSettings.links[.instagram]?.isPublic = false
        try await viewModel.submitProfileUpdate()

        let sent = try #require(contacts.received)
        #expect(mock.updateProfileImageCallCount == 0)
        #expect(contacts.updateCallCount == 1)
        #expect(sent.link(.github).value == "https://github.com/new")
        #expect(sent.link(.instagram).isPublic == false)
        #expect(sent.isEmailPublic == makeStoredContacts().isEmailPublic)
        #expect(viewModel.savedContactSettings == .loaded(sent))
        #expect(viewModel.canSubmit == false)
    }

    @Test("이미지+연락처 동시 변경 시 두 UseCase 모두 호출")
    func submitImageAndContactCallsBothUseCases() async throws {
        let mock = MockMyPageRepository()
        mock.updateProfileImageResult = .success(makeStubProfileData(challengeId: 100))
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(
            profile: makeStubProfileData(), repository: mock, contacts: contacts
        )
        await viewModel.loadContactSettings()

        await viewModel.didLoadImage(image: makeStubImage())
        viewModel.contactSettings.links[.blog]?.value = "https://blog.example.com"
        try await viewModel.submitProfileUpdate()

        #expect(mock.updateProfileImageCallCount == 1)
        #expect(contacts.updateCallCount == 1)
    }

    @Test("바뀐 링크 형식이 틀리면 검증 오류를 던지고 사진도 올리지 않는다")
    func submitInvalidLinkThrowsBeforeAnyRequest() async {
        let mock = MockMyPageRepository()
        mock.updateProfileImageResult = .success(makeStubProfileData())
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(
            profile: makeStubProfileData(), repository: mock, contacts: contacts
        )
        await viewModel.loadContactSettings()

        await viewModel.didLoadImage(image: makeStubImage())
        viewModel.contactSettings.links[.github]?.value = "github.com/no-scheme"
        await #expect(throws: AppError.self) {
            try await viewModel.submitProfileUpdate()
        }

        #expect(mock.updateProfileImageCallCount == 0)
        #expect(contacts.updateCallCount == 0)
        #expect(viewModel.canSubmit == true)
    }

    @Test("이미지 업로드 실패 — 에러 전파 + 연락처 UseCase 미호출 + 진행 플래그 복구 + 재시도용 pending 유지")
    func submitImageFailurePropagatesAndKeepsPendingState() async {
        let mock = MockMyPageRepository()
        mock.updateProfileImageResult = .failure(MyPageTestError.boom)
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        let viewModel = makeViewModel(
            profile: makeStubProfileData(challengeId: 1), repository: mock, contacts: contacts
        )
        await viewModel.loadContactSettings()

        await viewModel.didLoadImage(image: makeStubImage())
        viewModel.contactSettings.links[.blog]?.value = "https://blog.example.com"
        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.submitProfileUpdate()
        }

        #expect(mock.updateProfileImageCallCount == 1)
        // 이미지 단계에서 throw되므로 연락처 단계는 실행되지 않음
        #expect(contacts.updateCallCount == 0)
        #expect(viewModel.profileData.challengeId == 1)
        // defer로 진행 플래그 복구 + 선택 이미지가 남아 있어 재시도 가능
        #expect(viewModel.isUpdatingProfileImage == false)
        #expect(viewModel.canSubmit == true)
    }

    @Test("연락처 저장 실패 — 에러 전파 + 진행 플래그 복구 + 변경 보존")
    func submitContactFailurePropagatesAndKeepsDiff() async {
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        contacts.updateError = MyPageTestError.boom
        let viewModel = makeViewModel(
            profile: makeStubProfileData(challengeId: 1), contacts: contacts
        )
        await viewModel.loadContactSettings()

        viewModel.contactSettings.links[.github]?.value = "https://github.com/tester"
        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.submitProfileUpdate()
        }

        #expect(contacts.updateCallCount == 1)
        #expect(viewModel.savedContactSettings == .loaded(makeStoredContacts()))
        #expect(viewModel.isUpdatingProfileImage == false)
        #expect(viewModel.canSubmit == true)
    }

    @Test("이미지 성공 후 연락처 실패 — 에러 전파 + 서버 응답 미반영 + 이미지/연락처 pending 모두 보존")
    func submitContactFailureAfterImageSuccessKeepsBothPendingStates() async {
        let mock = MockMyPageRepository()
        mock.updateProfileImageResult = .success(makeStubProfileData(challengeId: 100))
        let contacts = StubCardContactUseCase(stored: makeStoredContacts())
        contacts.updateError = MyPageTestError.boom
        let viewModel = makeViewModel(
            profile: makeStubProfileData(challengeId: 1), repository: mock, contacts: contacts
        )
        await viewModel.loadContactSettings()

        await viewModel.didLoadImage(image: makeStubImage())
        viewModel.contactSettings.links[.blog]?.value = "https://blog.example.com"
        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.submitProfileUpdate()
        }

        #expect(mock.updateProfileImageCallCount == 1)
        #expect(contacts.updateCallCount == 1)
        // 연락처 단계에서 throw되어 이미지 응답(challengeId 100)도 반영되지 않음
        #expect(viewModel.profileData.challengeId == 1)
        #expect(viewModel.isUpdatingProfileImage == false)
        #expect(viewModel.canSubmit == true)
    }

    // MARK: - addActivityLog

    @Test("addActivityLog 성공 — record 추가 후 프로필 재조회 + 성공 플래그 노출 + socialConnections 보존")
    func addActivityLogSuccess() async throws {
        let original = makeStubProfileData(
            challengeId: 1,
            socialConnections: [SocialConnection(memberOAuthId: "5", socialType: .apple)]
        )
        var refreshed = makeStubProfileData(challengeId: 55, socialConnections: [])
        refreshed.isUmcProduct = true
        let mock = MockMyPageRepository()
        mock.fetchMyProfileResult = .success(refreshed)
        let viewModel = makeViewModel(profile: original, repository: mock)

        try await viewModel.addActivityLog(code: "UMC-CODE")

        #expect(mock.addChallengerRecordCallCount == 1)
        #expect(mock.addChallengerRecordReceivedCode == "UMC-CODE")
        #expect(mock.fetchMyProfileCallCount == 1)
        // 기록 추가는 세션 캐시를 무효화하지 않으므로 캐시를 우회해야 방금 추가한 이력이 보인다.
        #expect(mock.fetchMyProfileReceivedForceRefresh == true)
        #expect(viewModel.profileData.challengeId == 55)
        #expect(viewModel.profileData.isUmcProduct)
        #expect(viewModel.profileData.socialConnections == original.socialConnections)
        #expect(viewModel.didRecentlyAddActivityLog == true)
        #expect(viewModel.isAddingActivityLog == false)
    }

    @Test("addActivityLog에서 record 추가 실패 시 에러 전파 + 프로필 미갱신 + 플래그 미노출")
    func addActivityLogFailurePropagates() async {
        let mock = MockMyPageRepository()
        mock.addChallengerRecordError = MyPageTestError.boom
        let viewModel = makeViewModel(profile: makeStubProfileData(challengeId: 1), repository: mock)

        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.addActivityLog(code: "X")
        }

        #expect(mock.addChallengerRecordCallCount == 1)
        #expect(mock.fetchMyProfileCallCount == 0)
        #expect(viewModel.profileData.challengeId == 1)
        #expect(viewModel.didRecentlyAddActivityLog == false)
        #expect(viewModel.isAddingActivityLog == false)
    }

    // MARK: - disconnectSocial

    @Test("카카오 연동 해제 — kakaoAccessToken 전달 + 재조회 결과로 목록 갱신 + 진행 플래그 복구")
    func disconnectKakaoPassesKakaoTokenAndRefreshesConnections() async throws {
        let kakao = SocialConnection(memberOAuthId: "10", socialType: .kakao)
        let deleteUseCase = SpyDeleteMemberOAuthUseCase()
        let viewModel = makeViewModel(
            profile: makeStubProfileData(
                socialConnections: [kakao, SocialConnection(memberOAuthId: "11", socialType: .apple)]
            ),
            fetchMyOAuthUseCase: StubFetchMyOAuthUseCase(result: .success([
                MemberOAuth(memberOAuthId: "11", memberId: "1", provider: .apple)
            ])),
            deleteMemberOAuthUseCase: deleteUseCase
        )

        try await viewModel.disconnectSocial(kakao)

        #expect(deleteUseCase.callCount == 1)
        #expect(deleteUseCase.receivedMemberOAuthId == "10")
        #expect(deleteUseCase.receivedKakaoAccessToken == "kakao-token")
        #expect(deleteUseCase.receivedGoogleAccessToken == nil)
        #expect(viewModel.profileData.socialConnections.map(\.socialType) == [.apple])
        #expect(viewModel.disconnectingSocialType == nil)
    }

    @Test("구글 연동 해제 — googleAccessToken만 전달")
    func disconnectGooglePassesGoogleToken() async throws {
        let google = SocialConnection(memberOAuthId: "20", socialType: .google)
        let deleteUseCase = SpyDeleteMemberOAuthUseCase()
        let viewModel = makeViewModel(
            profile: makeStubProfileData(socialConnections: [google]),
            deleteMemberOAuthUseCase: deleteUseCase
        )

        try await viewModel.disconnectSocial(google)

        #expect(deleteUseCase.receivedGoogleAccessToken == "google-token")
        #expect(deleteUseCase.receivedKakaoAccessToken == nil)
        #expect(viewModel.profileData.socialConnections.isEmpty)
    }

    @Test("애플 연동 해제 — 검증 토큰 없이 요청")
    func disconnectApplePassesNoVerificationToken() async throws {
        let apple = SocialConnection(memberOAuthId: "30", socialType: .apple)
        let deleteUseCase = SpyDeleteMemberOAuthUseCase()
        let viewModel = makeViewModel(
            profile: makeStubProfileData(socialConnections: [apple]),
            deleteMemberOAuthUseCase: deleteUseCase
        )

        try await viewModel.disconnectSocial(apple)

        #expect(deleteUseCase.receivedGoogleAccessToken == nil)
        #expect(deleteUseCase.receivedKakaoAccessToken == nil)
    }

    @Test("연동 해제 실패 — 에러 전파 + 기존 목록 유지 + 진행 플래그 복구")
    func disconnectFailureKeepsExistingConnections() async {
        let kakao = SocialConnection(memberOAuthId: "10", socialType: .kakao)
        let deleteUseCase = SpyDeleteMemberOAuthUseCase()
        deleteUseCase.error = MyPageTestError.boom
        let viewModel = makeViewModel(
            profile: makeStubProfileData(socialConnections: [kakao]),
            deleteMemberOAuthUseCase: deleteUseCase
        )

        await #expect(throws: MyPageTestError.boom) {
            try await viewModel.disconnectSocial(kakao)
        }

        #expect(viewModel.profileData.socialConnections == [kakao])
        #expect(viewModel.disconnectingSocialType == nil)
    }
}

// MARK: - Helpers

@MainActor
private func makeViewModel(
    profile: ProfileData,
    repository: MockMyPageRepository = MockMyPageRepository(),
    fetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol = StubFetchMyOAuthUseCase(result: .success([])),
    deleteMemberOAuthUseCase: SpyDeleteMemberOAuthUseCase = SpyDeleteMemberOAuthUseCase(),
    contacts: StubCardContactUseCase = StubCardContactUseCase(stored: makeStoredContacts()),
    linkPriority: StubLinkPriorityUseCase = StubLinkPriorityUseCase()
) -> MyPageProfileViewModel {
    // GoogleLoginManaging은 MainActor 격리라 파라미터 기본값으로 만들 수 없어 본문에서 생성한다.
    MyPageProfileViewModel(
        profileData: profile,
        useCaseProvider: makeUseCaseProvider(repository),
        fetchMyOAuthUseCase: fetchMyOAuthUseCase,
        deleteMemberOAuthUseCase: deleteMemberOAuthUseCase,
        fetchCardContactSettingsUseCase: contacts,
        updateCardContactSettingsUseCase: contacts,
        fetchCardLinkPriorityUseCase: linkPriority,
        saveCardLinkPriorityUseCase: linkPriority,
        kakaoLoginManager: StubKakaoLoginManager(),
        googleLoginManager: StubGoogleLoginManager()
    )
}

/// scale 1로 그려 `size`가 곧 픽셀 크기인 단색 이미지
private func makeSolidImage(pixelSize: CGSize) -> UIImage {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return UIGraphicsImageRenderer(size: pixelSize, format: format).image { context in
        UIColor.red.setFill()
        context.fill(CGRect(origin: .zero, size: pixelSize))
    }
}

// MARK: - Stubs (명함 링크 우선순위)

private final class StubLinkPriorityUseCase:
    FetchCardLinkPriorityUseCaseProtocol, SaveCardLinkPriorityUseCaseProtocol,
    @unchecked Sendable {
    var stored: [CardLinkType] = CardLinkType.allCases
    var saveError: Error?
    private(set) var saved: [CardLinkType]?

    func execute() async throws -> [CardLinkType] {
        stored
    }

    func execute(_ priority: [CardLinkType]) async throws {
        if let saveError { throw saveError }
        saved = priority
    }
}

// MARK: - Stubs (명함 연락처·링크)

/// 서버에 저장된 연락처·링크 — 이메일과 GitHub·Instagram이 채워져 있다.
private func makeStoredContacts() -> CardContactSettings {
    CardContactSettings(
        isEmailPublic: true,
        links: [
            .github: CardContactItem(value: "https://github.com/umc", isPublic: true),
            .linkedin: .empty,
            .blog: .empty,
            .instagram: CardContactItem(value: "https://instagram.com/umc", isPublic: true),
            .personal: .empty
        ]
    )
}

/// 조회·저장 UseCase를 한 객체로 흉내 낸다 — 저장하면 그 값을 새 저장값으로 돌려준다.
private final class StubCardContactUseCase:
    FetchCardContactSettingsUseCaseProtocol, UpdateCardContactSettingsUseCaseProtocol {
    private let stored: CardContactSettings
    var fetchError: Error?
    var updateError: Error?
    private(set) var fetchCallCount = 0
    private(set) var updateCallCount = 0
    private(set) var received: CardContactSettings?

    init(stored: CardContactSettings) {
        self.stored = stored
    }

    func execute() async throws -> CardContactSettings {
        fetchCallCount += 1
        if let fetchError { throw fetchError }
        return stored
    }

    func execute(_ settings: CardContactSettings) async throws -> CardContactSettings {
        updateCallCount += 1
        received = settings
        if let updateError { throw updateError }
        return settings.normalized
    }
}

// MARK: - Stubs (소셜 연동)

private struct StubFetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol {
    let result: Result<[MemberOAuth], Error>

    func execute() async throws -> [MemberOAuth] {
        try result.get()
    }
}

private final class SpyDeleteMemberOAuthUseCase: DeleteMemberOAuthUseCaseProtocol, @unchecked Sendable {
    var error: Error?
    private(set) var callCount = 0
    private(set) var receivedMemberOAuthId: String?
    private(set) var receivedGoogleAccessToken: String?
    private(set) var receivedKakaoAccessToken: String?

    func execute(
        memberOAuthId: String,
        googleAccessToken: String?,
        kakaoAccessToken: String?
    ) async throws {
        callCount += 1
        receivedMemberOAuthId = memberOAuthId
        receivedGoogleAccessToken = googleAccessToken
        receivedKakaoAccessToken = kakaoAccessToken
        if let error { throw error }
    }
}

private final class StubKakaoLoginManager: KakaoLoginManaging, @unchecked Sendable {
    var accessToken = "kakao-token"

    func login() async throws -> (accessToken: String, email: String) {
        (accessToken, "kakao@umc.dev")
    }

    func fetchAccessToken() async throws -> String {
        accessToken
    }
}

private final class StubGoogleLoginManager: GoogleLoginManaging, @unchecked Sendable {
    var accessToken = "google-token"

    func login() async throws -> (accessToken: String, email: String?) {
        (accessToken, nil)
    }

    func fetchAccessToken() async throws -> String {
        accessToken
    }
}
