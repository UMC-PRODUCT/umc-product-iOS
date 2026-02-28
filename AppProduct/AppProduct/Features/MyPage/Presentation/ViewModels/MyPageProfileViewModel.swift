//
//  ModifyViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import Foundation
import SwiftUI
import PhotosUI

/// 마이페이지 읽기 및 수정 화면의 비즈니스 로직을 담당하는 ViewModel입니다.
///
/// 프로필 데이터를 관리하고, 이미지 선택 및 업로드 동작을 처리합니다.
@Observable
class MyPageProfileViewModel: SinglePhotoPickerManageable {
    // MARK: - Property

    /// 프로파일 정보
    var profileData: ProfileData
    private let useCaseProvider: MyPageUseCaseProviding

    // MARK: - 이미지 선택 관련

    /// PhotosPicker에서 선택된 아이템 (PHPickerResult)
    var selectedPhotoItem: PhotosPickerItem?
    
    /// 선택된 아이템에서 로드된 실제 이미지 객체
    var selectedImage: UIImage?

    /// 선택된 원본 이미지 바이너리 (업로드용)
    private var selectedImageData: Data?

    /// 프로필 이미지 수정 API 진행 상태
    var isUpdatingProfileImage: Bool = false

    /// 최초 조회/수정 화면 진입 시 링크 스냅샷
    private var initialProfileLinkState: [SocialLinkType: String]
    
    init(
        profileData: ProfileData,
        useCaseProvider: MyPageUseCaseProviding
    ) {
        self.profileData = profileData
        self.useCaseProvider = useCaseProvider
        self.initialProfileLinkState = Self.makeProfileLinkState(from: profileData.profileLink)
    }
    
    // MARK: - Function

    /// 갤러리에서 이미지를 선택했을 때 호출되는 콜백입니다.
    /// - Parameter image: 로드된 UIImage 객체
    func didLoadImage(image: UIImage) async {
        selectedImageData = image.jpegData(compressionQuality: 0.9)
    }

    /// 저장 버튼 활성화 여부
    var canSubmit: Bool {
        !isUpdatingProfileImage && (hasPendingImageUpdate || hasPendingLinkUpdate)
    }

    /// 갤러리에서 새 이미지를 선택하여 업로드 대기 중인지 여부
    private var hasPendingImageUpdate: Bool {
        selectedImageData != nil
    }

    /// 현재 링크 상태가 최초 스냅샷과 달라져 서버 반영이 필요한지 여부
    private var hasPendingLinkUpdate: Bool {
        Self.makeProfileLinkState(from: normalizedProfileLinksForSubmit) != initialProfileLinkState
    }

    /// 프로필 이미지를 서버에 업로드 후 회원 정보에 반영합니다.
    ///
    /// JPEG 0.9 품질로 압축된 이미지를 서버에 업로드하고,
    /// 성공 시 로컬 프로필 데이터를 갱신한 뒤 선택 상태를 초기화합니다.
    ///
    /// - Throws: 네트워크 오류 또는 서버 에러
    /// - Important: 호출 전 `canSubmit`이 true인지 확인해야 합니다.
    @MainActor
    func submitProfileUpdate() async throws {
        guard !isUpdatingProfileImage else {
            return
        }

        let hasImageUpdate = selectedImageData != nil
        let hasLinkUpdate = hasPendingLinkUpdate
        guard hasImageUpdate || hasLinkUpdate else {
            return
        }

        isUpdatingProfileImage = true
        defer { isUpdatingProfileImage = false }

        var updatedProfile = profileData

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

        if hasLinkUpdate {
            updatedProfile = try await useCaseProvider
                .updateMyPageProfileLinksUseCase
                .execute(profileLinks: normalizedProfileLinksForSubmit)
        }

        profileData = updatedProfile
        initialProfileLinkState = Self.makeProfileLinkState(from: updatedProfile.profileLink)
        selectedImageData = nil
        selectedPhotoItem = nil
    }

    // MARK: - Private Method

    /// 현재 프로필 링크를 정규화하여 서버 제출용 배열로 반환합니다.
    private var normalizedProfileLinksForSubmit: [ProfileLink] {
        let currentLinks = Self.makeProfileLinkState(from: profileData.profileLink)

        return SocialLinkType.allCases.map {
            ProfileLink(
                type: $0,
                url: currentLinks[$0] ?? ""
            )
        }
    }

    /// 프로필 링크 배열을 `[SocialLinkType: String]` 스냅샷으로 변환합니다.
    ///
    /// 변경 감지(diff) 비교에 사용되며, URL 공백을 제거하고
    /// 모든 `SocialLinkType` 케이스에 대해 키를 보장합니다.
    private static func makeProfileLinkState(
        from profileLinks: [ProfileLink]
    ) -> [SocialLinkType: String] {
        var mapped: [SocialLinkType: String] = [:]
        profileLinks.forEach {
            mapped[$0.type] = $0.url.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return Dictionary(
            uniqueKeysWithValues: SocialLinkType.allCases.map { type in
                (type, mapped[type] ?? "")
            }
        )
    }
}
