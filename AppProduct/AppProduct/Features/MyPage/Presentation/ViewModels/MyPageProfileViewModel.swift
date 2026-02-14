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
    
    init(
        profileData: ProfileData,
        useCaseProvider: MyPageUseCaseProviding
    ) {
        self.profileData = profileData
        self.useCaseProvider = useCaseProvider
    }
    
    // MARK: - Function

    /// 갤러리에서 이미지를 선택했을 때 호출되는 콜백입니다.
    /// - Parameter image: 로드된 UIImage 객체
    func didLoadImage(image: UIImage) async {
        selectedImageData = image.jpegData(compressionQuality: 0.9)
    }

    /// 저장 버튼 활성화 여부
    var canSubmit: Bool {
        selectedImageData != nil && !isUpdatingProfileImage
    }

    /// 프로필 이미지를 서버에 업로드 후 회원 정보에 반영합니다.
    ///
    /// JPEG 0.9 품질로 압축된 이미지를 서버에 업로드하고,
    /// 성공 시 로컬 프로필 데이터를 갱신한 뒤 선택 상태를 초기화합니다.
    ///
    /// - Throws: 네트워크 오류 또는 서버 에러
    /// - Important: 호출 전 `canSubmit`이 true인지 확인해야 합니다.
    @MainActor
    func submitProfileImageUpdate() async throws {
        guard let imageData = selectedImageData else {
            return
        }

        isUpdatingProfileImage = true
        defer { isUpdatingProfileImage = false }

        // 타임스탬프 기반 고유 파일명 생성
        let fileName = "profile_\(Int(Date().timeIntervalSince1970)).jpg"
        let updatedProfile = try await useCaseProvider
            .updateMyPageProfileImageUseCase
            .execute(
                imageData: imageData,
                fileName: fileName,
                contentType: "image/jpeg"
            )

        profileData = updatedProfile
        selectedImageData = nil
        selectedPhotoItem = nil
    }
}
