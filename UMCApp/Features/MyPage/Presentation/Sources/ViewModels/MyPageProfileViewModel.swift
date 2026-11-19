//
//  MyPageProfileViewModel.swift
//  MyPage
//
//  Created by 김동민 on 7/5/26.
//

import UMCFoundation
import SwiftUI
import PhotosUI
import AuthDomain
import BusinessCardDomain
import CoreNetwork
import CorePhoto
import MyPageDomain

/// 마이페이지 읽기 및 수정 화면의 비즈니스 로직을 담당하는 ViewModel입니다.
///
/// 프로필 데이터를 관리하고, 이미지 선택 및 업로드 동작을 처리합니다.
@Observable
public final class MyPageProfileViewModel: SinglePhotoPickerManageable {
    // MARK: - Property
    
    /// 프로필 정보
    public var profileData: ProfileData
    private let useCaseProvider: MyPageUseCaseProviding
    private let fetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol
    private let deleteMemberOAuthUseCase: DeleteMemberOAuthUseCaseProtocol
    private let fetchCardContactSettingsUseCase: FetchCardContactSettingsUseCaseProtocol
    private let updateCardContactSettingsUseCase: UpdateCardContactSettingsUseCaseProtocol
    private let fetchCardLinkPriorityUseCase: FetchCardLinkPriorityUseCaseProtocol
    private let saveCardLinkPriorityUseCase: SaveCardLinkPriorityUseCaseProtocol
    private let kakaoLoginManager: KakaoLoginManaging
    private let googleLoginManager: GoogleLoginManaging

    /// PhotosPicker에서 선택된 아이템(PHPickerResult)
    public var selectedPhotoItem: PhotosPickerItem?
    
    /// 선택된 아이템에서 로드된 실제 이미지 객체
    public var selectedImage: UIImage?
    
    /// 업로드용으로 축소·압축한 이미지 바이너리
    private var selectedImageData: Data?
    
    /// 프로필 이미지 수정 API 진행 상태
    public var isUpdatingProfileImage: Bool = false
    
    /// 활동 이력 추가 API 진행 상태
    public var isAddingActivityLog: Bool = false
    /// 활동 이력 추가 성공 후 버튼 성공 문구 노출 상태
    public var didRecentlyAddActivityLog: Bool = false
    
    /// 소셜 연동 해제 API 진행 상태
    public var disconnectingSocialType: SocialType?
    
    /// 서버에 저장된 명함 링크와 공개 여부 (#1678).
    ///
    /// 프로필(`/member/me`)에는 공개 여부가 없어 화면 진입 뒤 명함 수정 API(MEMBER-105)로
    /// 따로 읽는다. 변경 감지의 기준이기도 하다.
    public private(set) var savedContactSettings: Loadable<CardContactSettings> = .idle
    /// 편집 중인 링크와 공개 여부. 조회가 끝나면 저장된 값으로 채운다.
    public var contactSettings = CardContactSettings()
    /// 편집 중인 링크 우선순위 (#1679). 맨 위에서부터 공개한 첫 링크가 명함 뒷면에 보인다.
    public private(set) var linkPriority: [SocialLinkType] = SocialLinkType.allCases
    /// 기기에 저장된 링크 우선순위. 변경 감지의 기준이다.
    private var savedLinkPriority: [SocialLinkType] = SocialLinkType.allCases
    /// 활동 이력 추가 성공 문구 자동 복귀 제어 태스크
    private var activityLogAddedResetTask: Task<Void, Never>?
    
    /// 저장 버튼 활성화 여부
    public var canSubmit: Bool {
        !isUpdatingProfileImage
            && (hasPendingImageUpdate || hasPendingContactUpdate || hasPendingLinkPriorityUpdate)
    }
    
    /// 갤러리에서 새 이미지를 선택하여 업로드 대기 중인지 여부
    private var hasPendingImageUpdate: Bool {
        selectedImageData != nil
    }
    
    /// 링크·공개 여부가 저장된 값과 달라져 서버 반영이 필요한지 여부. 조회 전에는 비교할
    /// 기준이 없으므로 `false` 다.
    private var hasPendingContactUpdate: Bool {
        guard let saved = savedContactSettings.value else { return false }
        return contactSettings.normalized != saved.normalized
    }

    /// 링크 순서를 바꿔 기기에 저장해야 하는지 여부
    private var hasPendingLinkPriorityUpdate: Bool {
        linkPriority != savedLinkPriority
    }
    
    
    // MARK: - Function
    
    public init(
        profileData: ProfileData,
        useCaseProvider: MyPageUseCaseProviding,
        fetchMyOAuthUseCase: FetchMyOAuthUseCaseProtocol,
        deleteMemberOAuthUseCase: DeleteMemberOAuthUseCaseProtocol,
        fetchCardContactSettingsUseCase: FetchCardContactSettingsUseCaseProtocol,
        updateCardContactSettingsUseCase: UpdateCardContactSettingsUseCaseProtocol,
        fetchCardLinkPriorityUseCase: FetchCardLinkPriorityUseCaseProtocol,
        saveCardLinkPriorityUseCase: SaveCardLinkPriorityUseCaseProtocol,
        kakaoLoginManager: KakaoLoginManaging = KakaoLoginManager(),
        googleLoginManager: GoogleLoginManaging = GoogleLoginManager()
    ) {
        self.profileData = profileData
        self.useCaseProvider = useCaseProvider
        self.fetchMyOAuthUseCase = fetchMyOAuthUseCase
        self.deleteMemberOAuthUseCase = deleteMemberOAuthUseCase
        self.fetchCardContactSettingsUseCase = fetchCardContactSettingsUseCase
        self.updateCardContactSettingsUseCase = updateCardContactSettingsUseCase
        self.fetchCardLinkPriorityUseCase = fetchCardLinkPriorityUseCase
        self.saveCardLinkPriorityUseCase = saveCardLinkPriorityUseCase
        self.kakaoLoginManager = kakaoLoginManager
        self.googleLoginManager = googleLoginManager
    }

    /// 명함 연락처·링크와 공개 여부를 조회합니다.
    ///
    /// 이미 읽었거나 읽는 중이면 다시 읽지 않는다 — 화면이 다시 나타날 때마다 덮어쓰면
    /// 편집 중인 값이 사라진다. 실패 뒤 재시도는 `.failed` 에서만 다시 탄다.
    @MainActor
    public func loadContactSettings() async {
        switch savedContactSettings {
        case .loading, .loaded: return
        case .idle, .failed: break
        }

        savedContactSettings = .loading
        do {
            let saved = try await fetchCardContactSettingsUseCase.execute()
            contactSettings = saved
            savedContactSettings = .loaded(saved)
        } catch is CancellationError {
            savedContactSettings = .idle
        } catch let error as AppError {
            savedContactSettings = .failed(error)
        } catch {
            savedContactSettings = .failed(.unknown(message: error.localizedDescription))
        }
    }
    
    /// 기기에 저장된 링크 우선순위를 읽습니다 (#1679). 못 읽으면 기본 순서로 둡니다.
    ///
    /// 이미 순서를 바꾸고 있으면 덮지 않는다 — 화면이 다시 나타날 때마다 읽는다.
    @MainActor
    public func loadLinkPriority() async {
        guard let priority = try? await fetchCardLinkPriorityUseCase.execute() else { return }
        let ordered = priority.compactMap(SocialLinkType.init(cardLinkType:))
        if !hasPendingLinkPriorityUpdate {
            linkPriority = ordered
        }
        savedLinkPriority = ordered
    }

    /// 링크 줄을 끌어서 옮긴 순서를 반영합니다.
    public func moveLinks(fromOffsets source: IndexSet, toOffset destination: Int) {
        linkPriority.move(fromOffsets: source, toOffset: destination)
    }

    /// 갤러리에서 이미지를 선택했을 때 호출되는 콜백입니다.
    /// - Parameter image: 로드된 UIImage 객체
    public func didLoadImage(image: UIImage) async {
        selectedImageData = image.jpegDataForUpload(
            maxPixelLength: Constants.profileImageMaxPixelLength,
            maxByteCount: Constants.profileImageMaxByteCount
        )
    }
    
    /// 프로필 이미지를 서버에 업로드 후 회원 정보에 반영합니다.
    ///
    /// 긴 변 1024px 이하·5MB 이하로 줄인 JPEG 이미지를 서버에 업로드하고,
    /// 성공 시 로컬 프로필 데이터를 갱신한 뒤 선택 상태를 초기화합니다.
    ///
    /// - Throws: 네트워크 오류 또는 서버 에러
    /// - Important: 호출 전 `canSubmit`이 true인지 확인해야 합니다.
    @MainActor
    public func submitProfileUpdate() async throws {
        guard !isUpdatingProfileImage else {
            return
        }
        
        let hasImageUpdate = selectedImageData != nil
        let hasContactUpdate = hasPendingContactUpdate
        let hasPriorityUpdate = hasPendingLinkPriorityUpdate
        guard hasImageUpdate || hasContactUpdate || hasPriorityUpdate else {
            return
        }

        // 사진을 먼저 올린 뒤 형식 오류로 멈추면 절반만 저장된다. 검사는 어떤 요청보다 먼저 한다.
        if hasContactUpdate {
            try validateContactSettings()
        }

        isUpdatingProfileImage = true
        defer { isUpdatingProfileImage = false }

        // 순서는 기기에만 저장하므로 서버 요청보다 먼저 한다. 사진을 올린 뒤에 여기서 멈추면
        // 사진만 저장된 채 실패로 안내하게 된다.
        if hasPriorityUpdate {
            try await saveCardLinkPriorityUseCase.execute(linkPriority.compactMap(\.cardLinkType))
            savedLinkPriority = linkPriority
        }
        
        var updatedProfile = profileData
        let currentSocialConnections = profileData.socialConnections
        
        if hasImageUpdate, let imageData = selectedImageData {
            let fileName = "profile_\(Int(Date().timeIntervalSince1970)).jpg"
            updatedProfile = try await useCaseProvider
                .updateMyPageProfileImageUseCase
                .execute(
                    imageData: imageData,
                    fileName: fileName,
                    contentType: "image/jpeg"
                )
        }
        
        var savedContacts: CardContactSettings?
        if hasContactUpdate {
            savedContacts = try await updateCardContactSettingsUseCase.execute(contactSettings)
        }

        updatedProfile.socialConnections = currentSocialConnections
        profileData = updatedProfile
        if let savedContacts {
            contactSettings = savedContacts
            savedContactSettings = .loaded(savedContacts)
        }
        selectedImageData = nil
        selectedPhotoItem = nil
    }
    
    /// 운영진 발급 코드로 활동 이력을 추가하고 프로필 정보를 갱신합니다.
    @MainActor
    public func addActivityLog(code: String) async throws {
        guard !isAddingActivityLog else {
            return
        }
        
        isAddingActivityLog = true
        defer { isAddingActivityLog = false }
        
        let currentSocialConnections = profileData.socialConnections
        try await useCaseProvider.addChallengerRecordUseCase.execute(code: code)
        // 기록 추가는 세션 프로필 캐시를 무효화하지 않으므로, 캐시 경로로 읽으면 방금 추가한
        // 이력이 빠진 스냅샷이 돌아온다.
        profileData = try await useCaseProvider.fetchMyPageProfileUseCase.execute(
            forceRefresh: true
        )
        profileData.socialConnections = currentSocialConnections
        showRecentActivityLogAddedState()
    }
    
    /// 특정 소셜 연동을 해제하고 최신 연동 목록으로 갱신합니다.
    @MainActor
    public func disconnectSocial(_ connection: SocialConnection) async throws {
        guard disconnectingSocialType == nil else {
            return
        }

        disconnectingSocialType = connection.socialType
        defer { disconnectingSocialType = nil }

        let verification = try await connection.socialType.fetchUnlinkAccessTokens(
            kakaoLoginManager: kakaoLoginManager,
            googleLoginManager: googleLoginManager
        )

        try await deleteMemberOAuthUseCase.execute(
            memberOAuthId: connection.memberOAuthId,
            googleAccessToken: verification.googleAccessToken,
            kakaoAccessToken: verification.kakaoAccessToken
        )

        let oauths = try await fetchMyOAuthUseCase.execute()
        let updatedConnections = oauths.compactMap(SocialConnection.init(memberOAuth:))
        profileData.socialConnections = updatedConnections
        SocialType.saveConnected(updatedConnections.map(\.socialType))
    }

    /// 바뀐 링크 중 형식이 틀린 값이 있으면 저장하지 않고 검증 오류를 던집니다.
    ///
    /// 링크는 서버가 명함에 싣는 기준(http(s)와 점이 든 호스트)을 따른다. 이 기준을 벗어난
    /// 링크는 저장은 돼도 명함에는 나오지 않는다.
    private func validateContactSettings() throws {
        guard let saved = savedContactSettings.value,
              let type = contactSettings.firstInvalidLink(comparedTo: saved) else { return }
        throw AppError.validation(
            .invalidFormat(field: type.title, expected: Constants.linkExample)
        )
    }
    
    /// 활동 이력 추가 성공 문구를 잠시 노출한 뒤 기본 상태로 복귀합니다.
    @MainActor
    private func showRecentActivityLogAddedState() {
        activityLogAddedResetTask?.cancel()
        didRecentlyAddActivityLog = true
        
        activityLogAddedResetTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            self?.didRecentlyAddActivityLog = false
        }
    }
}

fileprivate enum Constants {
    static let linkExample = "https://로 시작하는 주소"
    static let profileImageMaxPixelLength: CGFloat = 1024
    // 서버 FileCategory.PROFILE_IMAGE 상한
    static let profileImageMaxByteCount = 5 * 1024 * 1024
}
