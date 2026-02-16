//
//  NoticeRepository.swift
//  AppProduct
//
//  Created by 이예지 on 2/14/26.
//

import Foundation
import Moya

/// 공지사항 Repository 구현체
///
/// 공지 CRUD, 열람 처리, 리마인더, 검색 등 공지 관련 전체 API를 처리합니다.
struct NoticeRepository: NoticeRepositoryProtocol {
    
    // MARK: - Property
    private let adapter: MoyaNetworkAdapter
    
    // MARK: - Initializer
    init(adapter: MoyaNetworkAdapter) {
        self.adapter = adapter
    }
    
    // MARK: - NoticeRepositoryProtocol
    
    // MARK: 공지 생성
    /// 공지사항 완전 생성 (links, images 포함) → 상세 조회 반환
    func createNotice(
        body: PostNoticeRequestDTO,
        links: [String] = [],
        imageIds: [String] = []
    ) async throws -> NoticeDetail {
        let response = try await adapter.request(NoticeRouter.postNotice(body: body))
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeCreateResponseDTO>.self,
            from: response.data
        )
        let noticeId = try apiResponse.unwrap().noticeId
        
        if !links.isEmpty {
            _ = try await adapter.request(
                NoticeRouter.addLink(noticeId: noticeId, links: links)
            )
        }
        
        if !imageIds.isEmpty {
            let imageResponse = try await adapter.request(
                NoticeRouter.addImage(noticeId: noticeId, imageIds: imageIds)
            )
            let imageApiResponse = try JSONDecoder().decode(
                APIResponse<NoticeAddImagesResponseDTO>.self,
                from: imageResponse.data
            )
            _ = try imageApiResponse.unwrap()
        }
        
        return try await getDetailNotice(noticeId: noticeId)
    }
    
    /// 공지사항 기본 생성 → NoticeItemModel 반환
    func postNotice(body: PostNoticeRequestDTO) async throws -> NoticeItemModel {
        let response = try await adapter.request(NoticeRouter.postNotice(body: body))
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeCreateResponseDTO>.self,
            from: response.data
        )
        let noticeId = try apiResponse.unwrap().noticeId
        let detail = try await getDetailNotice(noticeId: noticeId)
        return detail.toItemModel()
    }
    
    /// 공지사항 투표 추가
    func addVote(
        noticeId: Int,
        body: AddVoteRequestDTO
    ) async throws -> AddVoteResponseDTO {
        let response = try await adapter.request(
            NoticeRouter.addVote(noticeId: noticeId, body: body)
        )

        let apiResponse = try JSONDecoder().decode(
            APIResponse<AddVoteResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
    
    /// 공지사항 링크 추가 → NoticeItemModel 반환
    func addLink(noticeId: Int, links: [String]) async throws -> NoticeItemModel {
        let response = try await adapter.request(
            NoticeRouter.addLink(noticeId: noticeId, links: links)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeDTO>.self,
            from: response.data
        )
        let noticeDTO = try apiResponse.unwrap()
        
        return noticeDTO.toItemModel()
    }
    
    /// 공지사항 이미지 추가 → NoticeItemModel 반환
    func addImage(noticeId: Int, imageIds: [String]) async throws -> NoticeItemModel {
        let response = try await adapter.request(
            NoticeRouter.addImage(noticeId: noticeId, imageIds: imageIds)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeAddImagesResponseDTO>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
        let detail = try await getDetailNotice(noticeId: noticeId)
        return detail.toItemModel()
    }
    
    /// 공지사항 리마인더 발송
    func sendReminder(noticeId: Int, targetIds: [Int]) async throws {
        let response = try await adapter.request(
            NoticeRouter.sendReminder(noticeId: noticeId, targetIds: targetIds)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    /// 공지사항 읽음 처리
    func readNotice(noticeId: Int) async throws {
        let response = try await adapter.request(
            NoticeRouter.readNotice(noticeId: noticeId)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
    
    // MARK: 공지 수정
    
    /// 공지사항 수정 (제목, 본문) → NoticeDetail 반환
    func updateNotice(noticeId: Int, body: UpdateNoticeRequestDTO) async throws -> NoticeDetail {
        let response = try await adapter.request(
            NoticeRouter.updateNotice(noticeId: noticeId, body: body)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
        
        // 수정 후 상세 조회하여 최신 데이터 반환
        return try await getDetailNotice(noticeId: noticeId)
    }
    
    /// 공지사항 링크 수정 → NoticeDetail 반환
    func updateLinks(noticeId: Int, links: [String]) async throws -> NoticeDetail {
        let response = try await adapter.request(
            NoticeRouter.updateLink(noticeId: noticeId, links: links)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
        
        // 수정 후 상세 조회하여 최신 데이터 반환
        return try await getDetailNotice(noticeId: noticeId)
    }
    
    /// 공지사항 이미지 수정 → NoticeDetail 반환
    func updateImages(noticeId: Int, imageIds: [String]) async throws -> NoticeDetail {
        let response = try await adapter.request(
            NoticeRouter.updateImage(noticeId: noticeId, imageIds: imageIds)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
        
        // 수정 후 상세 조회하여 최신 데이터 반환
        return try await getDetailNotice(noticeId: noticeId)
    }
    
    // MARK: - 공지 조회
    
    /// 공지사항 전체 조회
    func getAllNotices(
        request: NoticeListRequestDTO
    ) async throws -> NoticePageDTO<NoticeDTO> {
        let response = try await adapter.request(
            NoticeRouter.getAllNotices(request: request)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticePageDTO<NoticeDTO>>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
    
    /// 공지사항 상세 조회
    func getDetailNotice(noticeId: Int) async throws -> NoticeDetail {
        let response = try await adapter.request(
            NoticeRouter.getDetailNotice(noticeId: noticeId)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeDetailDTO>.self,
            from: response.data
        )
        let detailDTO = try apiResponse.unwrap()
        
        return detailDTO.toDomain()
    }
    
    /// 공지 열람 통계 조회
    func getReadStatics(noticeId: Int) async throws -> NoticeReadStaticsDTO {
        let response = try await adapter.request(
            NoticeRouter.getNoticeReadStatusCount(noticeId: noticeId)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeReadStaticsDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
    
    /// 공지 열람 현황 상세 조회
    func getReadStatusList(
        noticeId: Int,
        cursorId: Int = 0,
        filterType: String,
        organizationIds: [Int],
        status: String
    ) async throws -> NoticeReadStatusResponseDTO {
        let response = try await adapter.request(
            NoticeRouter.getNoticeReadStatusList(
                noticeId: noticeId,
                cursorId: cursorId,
                filterType: filterType,
                organizationIds: organizationIds,
                status: status
            )
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticeReadStatusResponseDTO>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
    
    /// 공지사항 검색
    func searchNotice(
        keyword: String,
        request: NoticeListRequestDTO
    ) async throws -> NoticePageDTO<NoticeDTO> {
        let response = try await adapter.request(
            NoticeRouter.searchNotice(keyword: keyword, request: request)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<NoticePageDTO<NoticeDTO>>.self,
            from: response.data
        )
        return try apiResponse.unwrap()
    }
    
    // MARK: - 공지 삭제
    
    /// 공지사항 삭제
    func deleteNotice(noticeId: Int) async throws {
        let response = try await adapter.request(
            NoticeRouter.deleteNotice(noticeId: noticeId)
        )
        
        let apiResponse = try JSONDecoder().decode(
            APIResponse<EmptyResult>.self,
            from: response.data
        )
        _ = try apiResponse.unwrap()
    }
}

private extension NoticeDetail {
    func toItemModel() -> NoticeItemModel {
        NoticeItemModel(
            noticeId: id,
            generation: generation,
            scope: scope,
            category: category,
            mustRead: isMustRead,
            isAlert: false,
            date: createdAt,
            title: title,
            content: content,
            writer: authorName,
            links: links,
            images: images,
            vote: vote,
            viewCount: 0
        )
    }
}
