//
//  ModifyViewModel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import Foundation
import SwiftUI
import PhotosUI

/// 마이페이지 수정 화면의 비즈니스 로직을 담당하는 ViewModel입니다.
///
/// 프로필 데이터를 관리하고, 이미지 선택 및 업로드 동작을 처리합니다.
@Observable
class ModifyMyPageViewModel: PhotoPickerManageable {
    
    /// 프로필 데이터 로딩 상태 (loading, loaded, failed 등)
    var profileDataState: Loadable<ProfileData> = .loading
    
    /// 수정 중인 프로필 데이터 (임시 저장소)
    var editableProfileData: ProfileData?

    // MARK: - 이미지 선택 관련

    /// PhotosPicker에서 선택된 아이템 (PHPickerResult)
    var selectedPhotoItem: PhotosPickerItem?
    
    /// 선택된 아이템에서 로드된 실제 이미지 객체
    var selectedImage: UIImage?

    /// 초기 프로필 데이터를 로드하고 상태를 업데이트합니다.
    /// - Parameter data: 불러온 프로필 데이터
    func loadProfileData(_ data: ProfileData) {
        self.editableProfileData = data
        self.profileDataState = .loaded(data)
    }
    
    /// 갤러리에서 이미지를 선택했을 때 호출되는 콜백입니다.
    /// - Parameter image: 로드된 UIImage 객체
    func didLoadImage(image: UIImage) async {
        // TODO: 서버로 이미지 업로드 로직 구현 필요
        print("서버로 사진 전달 함수")
    }
}
