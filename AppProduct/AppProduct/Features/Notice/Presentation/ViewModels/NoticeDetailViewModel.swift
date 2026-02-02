//
//  NoticeDetailViewModel.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import SwiftUI

@Observable
final class NoticeDetailViewModel {
    
    /// 공지 상세 상태
    var noticeState: Loadable<NoticeDetail> = .loaded(NoticeDetailMockData.sampleNoticeWithPermission)
    
    /// 액션 메뉴 표시 여부
    var showingActionMenu: Bool = false
    
    /// Alert 프롬프트
    var alertPrompt: AlertPrompt?
    
    /// 공지 ID
    private let noticeID: String
    
    // MARK: - Initialization
    
    init(noticeID: String = "1") {
        self.noticeID = noticeID
    }
    
    // MARK: - Actions
    
    /// 액션 메뉴 표시
    func showActionMenu() {
        showingActionMenu = true
    }
    
    /// 공지 수정
    func editNotice() {
        // TODO: NoticeEditorView로 이동
        print("[NoticeDetail] 공지 수정: \(noticeID)")
    }
    
    /// 삭제 확인 다이얼로그 표시
    func showDeleteConfirmation() {
        alertPrompt = AlertPrompt(
            id: .init(),
            title: "공지 삭제",
            message: "정말 삭제하시겠습니까?",
            positiveBtnTitle: "삭제",
            positiveBtnAction: { [weak self] in
                Task {
                    await self?.deleteNotice()
                }
            },
            negativeBtnTitle: "취소"
        )
    }
    
    /// 공지 삭제
    @MainActor
    private func deleteNotice() async {
        // TODO: UseCase로 삭제 처리
        print("[NoticeDetail] 공지 삭제 시작: \(noticeID)")
        
        do {
            // 삭제 API 호출 시뮬레이션
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // 삭제 성공
            print("[NoticeDetail] 공지 삭제 완료")
            
            // TODO: 이전 화면으로 돌아가기
        } catch {
            // 삭제 실패 시 에러 처리
            print("[NoticeDetail] 공지 삭제 실패: \(error)")
        }
    }
}
