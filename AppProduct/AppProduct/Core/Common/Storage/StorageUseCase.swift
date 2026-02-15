//
//  StorageUseCase.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import UIKit

final class StorageUseCase: StorageUseCaseProtocol {
    private let repository: StorageRepositoryProtocol

    init(repository: StorageRepositoryProtocol) {
        self.repository = repository
    }

    func uploadImage(_ image: UIImage, category: FileCategory) async throws -> String {
        // 1. 이미지 → JPEG Data 변환
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw DomainError.custom(message: "이미지 변환 실패")
        }

        let fileName = "image_\(UUID().uuidString).jpg"
        let contentType = "image/jpeg"
        let fileSize = imageData.count

        // 2. Presigned URL 준비
        let prepareResponse = try await repository.prepareUpload(
            fileName: fileName,
            contentType: contentType,
            fileSize: fileSize,
            category: category
        )

        // 3. Presigned URL로 파일 업로드
        try await repository.uploadFile(
            to: prepareResponse.uploadUrl,
            data: imageData,
            method: prepareResponse.uploadMethod,
            headers: prepareResponse.headers
        )

        // 4. 업로드 완료 확인
        _ = try await repository.confirmUpload(fileId: prepareResponse.fileId)

        // 5. fileId 반환
        return prepareResponse.fileId
    }

    func uploadImages(_ images: [UIImage], category: FileCategory) async throws -> [String] {
        var fileIds: [String] = []

        for image in images {
            let fileId = try await uploadImage(image, category: category)
            fileIds.append(fileId)
        }

        return fileIds
    }
}
