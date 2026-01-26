//
//  PhotoPickerManageable.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import UIKit
import SwiftUI
import PhotosUI

/// PhotosPicker 기능을 제공하고 이미지 로드 로직을 캡슐화하는 프로토콜입니다.
///
/// `PhotosPicker`를 사용하는 뷰모델에서 이 프로토콜을 채택하면,
/// `selectedPhotoItem` 변경 시 이미지를 자동으로 로드하는 기본 구현을 사용할 수 있습니다.
///
/// - Usage:
/// ```swift
/// class MyViewModel: ObservableObject, PhotoPickerManageable {
///     @Published var selectedPhotoItem: PhotosPickerItem?
///     @Published var selectedImage: UIImage?
///
///     // 뷰에서 onChange 등으로 loadSelectedImage() 호출 필요
///
///     // 선택적 구현: 이미지가 로드된 직후 수행할 추가 작업이 있다면 오버라이드
///     func didLoadImage(image: UIImage) async {
///         // 예: 서버로 이미지 업로드, 리사이징 등
///         print("Image loaded: \(image)")
///     }
/// }
/// ```
protocol PhotoPickerManageable: AnyObject {
    /// 선택된 PhotosPickerItem (SwiftUI View와 바인딩용)
    var selectedPhotoItem: PhotosPickerItem? { get set }

    /// 선택된 이미지 데이터 (UIImage)
    var selectedImage: UIImage? { get set }

    /// 선택한 `selectedPhotoItem`으로부터 실제 이미지를 로드하는 메서드
    /// - Note: 내부에서 `didLoadImage(image:)`를 호출합니다.
    @MainActor
    func loadSelectedImage() async
    
    /// 이미지가 성공적으로 로드된 후 호출되는 후크 메서드
    ///
    /// 기본 구현은 비어있으며, 필요 시 **오버라이드(Overloading/Overriding)** 하여 커스텀 로직을 추가할 수 있습니다.
    /// 예를 들어, 이미지가 로드되자마자 서버 업로드를 수행하거나 이미지 필터를 적용해야 할 때 유용합니다.
    @MainActor
    func didLoadImage(image: UIImage) async
}

// MARK: - Default Implementation

extension PhotoPickerManageable {
    @MainActor
    func loadSelectedImage() async {
        guard let item = selectedPhotoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let uiImage = UIImage(data: data) {
                selectedImage = uiImage
                await didLoadImage(uiImage)
            }
        } catch {
            print("이미지 불러오기 실패: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    func didLoadImage(_ image: UIImage) async {
        
    }
}
