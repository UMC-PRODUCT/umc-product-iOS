//
//  NoticePostRequestDTO.swift
//  AppProduct
//
//  Created by 이예지 on 2/11/26.
//

import Foundation

// MARK: - Post Notice
/// 공지 생성 요청 DTO
struct PostNoticeRequestDTO: Codable {
    /// 공지 제목
    let title: String
    /// 공지 본문
    let content: String
    /// 알림 발송 여부
    let shouldNotify: Bool
    /// 공지 대상 정보
    let targetInfo: TargetInfoDTO
}

// MARK: - Create Notice Response
/// 공지 생성 응답 DTO
struct NoticeCreateResponseDTO: Codable {
    /// 생성된 공지 ID
    let noticeId: Int
}

// MARK: - Add Images Response
/// 공지 이미지 추가 응답 DTO
struct NoticeAddImagesResponseDTO: Codable {
    /// 추가된 이미지 ID 목록
    let imageIds: [String]

    private enum CodingKeys: String, CodingKey {
        case imageIds
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let ids = try? container.decode([String].self, forKey: .imageIds) {
            self.imageIds = ids
            return
        }
        if let ids = try? container.decode([Int].self, forKey: .imageIds) {
            self.imageIds = ids.map(String.init)
            return
        }
        self.imageIds = []
    }
}
