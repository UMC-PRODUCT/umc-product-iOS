//
//  NoticeUseCaseProtocol.swift
//  AppProduct
//
//  Created by 이예지 on 2/14/26.
//

import Foundation

/// Notice 관련 모든 UseCase를 정의하는 Protocol
protocol NoticeUseCaseProtocol {
    
    // MARK: - 공지 생성 (POST)
    
    /// 공지사항 완전 생성 (links, images 포함)
    /// - Parameters:
    ///   - title: 공지 제목
    ///   - content: 공지 내용
    ///   - shouldNotify: 알림 발송 여부
    ///   - targetInfo: 수신 대상 정보
    ///   - links: 링크 목록
    ///   - imageIds: 이미지 ID 목록
    /// - Returns: 생성된 공지 상세 정보
    func createNotice(
        title: String,
        content: String,
        shouldNotify: Bool,
        targetInfo: [TargetInfoDTO],
        links: [String],
        imageIds: [String]
    ) async throws -> NoticeDetail
    
    /// 공지사항 투표 추가 (POST)
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - title: 투표 제목
    ///   - isAnonymous: 익명 투표 여부
    ///   - allowMultipleChoice: 복수 선택 허용 여부
    ///   - startsAt: 투표 시작 시간
    ///   - endsAtExclusive: 투표 종료 시간
    ///   - options: 투표 옵션 목록
    /// - Returns: 생성된 투표 ID 정보
    func addVote(
        noticeId: Int,
        title: String,
        isAnonymous: Bool,
        allowMultipleChoice: Bool,
        startsAt: Date,
        endsAtExclusive: Date,
        options: [String]
    ) async throws -> AddVoteResponseDTO
    
    /// 공지사항 링크 추가 (POST)
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - links: 추가할 링크 목록
    /// - Returns: 업데이트된 공지 정보
    func addLink(noticeId: Int, links: [String]) async throws -> NoticeItemModel
    
    /// 공지사항 이미지 추가 (POST)
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - imageIds: 추가할 이미지 ID 목록
    /// - Returns: 업데이트된 공지 정보
    func addImage(noticeId: Int, imageIds: [String]) async throws -> NoticeItemModel
    
    // MARK: - 공지 읽음 처리 (POST)
    
    /// 공지사항 읽음 처리
    /// - Parameter noticeId: 공지 ID
    func readNotice(noticeId: Int) async throws
    
    // MARK: - 리마인더 (POST)
    
    /// 리마인더 발송
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - targetIds: 대상 사용자 ID 목록
    func sendReminder(noticeId: Int, targetIds: [Int]) async throws
    
    // MARK: - 공지 수정 (PATCH)
    
    /// 공지사항 수정 (제목, 본문)
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - title: 수정할 제목
    ///   - content: 수정할 본문
    /// - Returns: 수정된 공지 상세 정보
    func updateNotice(
        noticeId: Int,
        title: String,
        content: String
    ) async throws -> NoticeDetail
    
    /// 공지사항 링크 수정
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - links: 수정할 링크 목록 (전체 교체)
    /// - Returns: 수정된 공지 상세 정보
    func updateLinks(
        noticeId: Int,
        links: [String]
    ) async throws -> NoticeDetail
    
    /// 공지사항 이미지 수정
    /// - Parameters:
    ///   - noticeId: 공지 ID
    ///   - imageIds: 수정할 이미지 ID 목록 (전체 교체)
    /// - Returns: 수정된 공지 상세 정보
    func updateImages(
        noticeId: Int,
        imageIds: [String]
    ) async throws -> NoticeDetail
    
    // MARK: - 공지 조회 (GET)
    
    /// 공지사항 전체 조회
    func getAllNotices(request: NoticeListRequestDTO) async throws -> PageDTO<NoticeDTO>
    
    /// 공지사항 상세 조회
    func getDetailNotice(noticeId: Int) async throws -> NoticeDetail
    
    /// 공지 열람 통계 조회
    func getReadStatics(noticeId: Int) async throws -> NoticeReadStaticsDTO
    
    /// 공지 열람 현황 상세 조회
    func getReadStatusList(
        noticeId: Int,
        cursorId: Int,
        filterType: String,
        organizationIds: [Int],
        status: String
    ) async throws -> NoticeReadStatusResponseDTO
    
    /// 공지사항 검색
    /// - Parameters:
    ///   - keyword: 검색 키워드
    ///   - request: 필터 및 페이징 정보
    /// - Returns: 검색 결과 페이지
    func searchNotice(
        keyword: String,
        request: NoticeListRequestDTO
    ) async throws -> PageDTO<NoticeDTO>
    
    // MARK: - 공지 삭제 (DELETE)
    
    /// 공지사항 삭제
    /// - Parameter noticeId: 삭제할 공지 ID
    func deleteNotice(noticeId: Int) async throws
}

