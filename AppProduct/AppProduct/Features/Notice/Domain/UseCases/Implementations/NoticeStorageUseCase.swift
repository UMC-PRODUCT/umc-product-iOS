//
//  StorageUseCase.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import UIKit

/// 공지사항 이미지 업로드 UseCase 구현체
///
/// Presigned URL 3단계 플로우(prepare → upload → confirm)를 캡슐화합니다.
final class NoticeStorageUseCase: NoticeStorageUseCaseProtocol {

    // MARK: - Property

    private let repository: NoticeStorageRepositoryProtocol

    // MARK: - Init

    init(repository: NoticeStorageRepositoryProtocol) {
        self.repository = repository
    }

    func uploadImage(_ image: UIImage, category: StorageFileCategory) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw DomainError.custom(message: "이미지 변환 실패")
        }

        let fileName = "image_\(UUID().uuidString).jpg"
        let contentType = "image/jpeg"
        let fileSize = imageData.count

        // 1. Presigned URL 준비
        let prepareResponse = try await repository.prepareUpload(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category
        )

        // 2. Presigned URL로 파일 업로드
        try await repository.uploadFile(
            to: prepareResponse.uploadUrl,
            data: imageData,
            method: prepareResponse.uploadMethod,
            headers: prepareResponse.headers,
            contentType: contentType
        )

        // 3. 업로드 완료 확인
        try await repository.confirmUpload(fileId: prepareResponse.fileId)  // ✅ 리턴값 제거

        // 4. fileId 반환
        return prepareResponse.fileId
    }

    func uploadImages(_ images: [UIImage], category: StorageFileCategory) async throws -> [String] {
        var fileIds: [String] = []

        for image in images {
            let fileId = try await uploadImage(image, category: category)
            fileIds.append(fileId)
        }

        return fileIds
    }
}
