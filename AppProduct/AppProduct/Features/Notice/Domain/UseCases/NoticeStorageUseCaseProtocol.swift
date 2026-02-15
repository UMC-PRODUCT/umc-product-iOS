//
//  NoticeStorageUseCaseProtocol.swift
//  AppProduct
//
//  Created by 이예지 on 2/15/26.
//

import Foundation
import UIKit

/// 공지사항 이미지 업로드 UseCase 인터페이스
protocol NoticeStorageUseCaseProtocol {
    /// 이미지 업로드 (전체 플로우)
    /// - Parameter image: 업로드할 이미지
    /// - Returns: 업로드된 파일 ID
    func uploadImage(_ image: UIImage, category: StorageFileCategory) async throws -> String

    /// 여러 이미지 일괄 업로드
    /// - Parameter images: 업로드할 이미지 배열
    /// - Returns: 업로드된 파일 ID 배열
    func uploadImages(_ images: [UIImage], category: StorageFileCategory) async throws -> [String]
}
