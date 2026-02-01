//
//  ProfileImagePicker.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI
import PhotosUI

/// 프로필 이미지 선택 컴포넌트
///
/// PhotosPicker를 사용하여 사진 라이브러리에서 이미지를 선택할 수 있습니다.
/// 선택된 이미지가 있으면 해당 이미지를, 없으면 서버에서 받은 프로필 이미지를 표시합니다.
struct ProfileImagePicker: View {

    // MARK: - Property

    /// 사용자가 선택한 사진 아이템 (PhotosPicker 바인딩)
    @Binding var selectedPhotoItem: PhotosPickerItem?

    /// 선택된 사진이 UIImage로 변환된 결과
    var selectedImage: UIImage?

    /// 기존 프로필 이미지 URL (서버에서 받은 값)
    var profileImage: String?

    // MARK: - Constant

    private enum Constants {
        /// 프로필 이미지 크기
        static let imageSize: CGFloat = 112

        /// 버튼 텍스트
        static let btnText: String = "사진 변경"
    }

    // MARK: - Body

    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            VStack(spacing: DefaultSpacing.spacing8, content: {
                // 새로 선택한 이미지가 있으면 우선 표시
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                        .clipShape(Circle())
                } else {
                    // 기존 프로필 이미지 표시 (URL에서 로드)
                    RemoteImage(
                        urlString: profileImage ?? "",
                        size: .init(width: Constants.imageSize, height: Constants.imageSize),
                        cornerRadius: 60
                    )
                }
                Text(Constants.btnText)
                    .appFont(.caption1, color: .blue)
            })
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .background(Color(.systemGroupedBackground))
    }
}
