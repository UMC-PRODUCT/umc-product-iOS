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
class MyPageProfileViewModel: PhotoPickerManageable {
    
    /// 프로파일 정보
    var profileData: ProfileData

    // MARK: - 이미지 선택 관련

    /// PhotosPicker에서 선택된 아이템 (PHPickerResult)
    var selectedPhotoItem: PhotosPickerItem?
    
    /// 선택된 아이템에서 로드된 실제 이미지 객체
    var selectedImage: UIImage?
    
    init(profileData: ProfileData) {
        self.profileData = profileData
    }
    
    /// 갤러리에서 이미지를 선택했을 때 호출되는 콜백입니다.
    /// - Parameter image: 로드된 UIImage 객체
    func didLoadImage(image: UIImage) async {
        // TODO: 서버로 이미지 업로드 로직 구현 필요
        print("서버로 사진 전달 함수")
    }
}
