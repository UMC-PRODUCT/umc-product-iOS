//
//  NoticeEditorViewModel+VoteAttachment.swift
//  AppProduct
//
//  Created by euijjang97 on 2/17/26.
//

import Foundation
import UIKit

extension NoticeEditorViewModel {

    // MARK: - Vote Action

    /// 투표 폼 시트를 표시합니다. 이미 확정된 투표가 있으면 안내 Alert을 보여줍니다.
    func showVotingFormSheet() {
        if isVoteConfirmed {
            alertPrompt = AlertPrompt(
                id: .init(),
                title: "투표가 이미 생성되었습니다",
                message: "투표 카드를 눌러 수정하거나 삭제할 수 있습니다.",
                positiveBtnTitle: "확인"
            )
        } else {
            voteFormData = VoteFormData()
            originalVoteFormData = nil
            showVoting = true
        }
    }

    /// 투표 편집을 취소하고 원본 상태로 복원합니다.
    func cancelVotingEdit() {
        if isVoteConfirmed, let original = originalVoteFormData {
            voteFormData = original
        } else if !isVoteConfirmed {
            voteFormData = VoteFormData()
        }

        originalVoteFormData = nil
        showVoting = false
    }

    /// 투표 폼 입력을 확정합니다.
    func confirmVote() {
        isVoteConfirmed = true
        originalVoteFormData = nil
        showVoting = false
    }

    /// 확정된 투표를 수정 모드로 전환합니다. 원본 데이터를 스냅샷에 저장합니다.
    func editVote() {
        originalVoteFormData = VoteFormData(
            title: voteFormData.title,
            options: voteFormData.options.map { VoteOptionItem(text: $0.text) },
            isAnonymous: voteFormData.isAnonymous,
            allowMultipleSelection: voteFormData.allowMultipleSelection,
            startDate: voteFormData.startDate,
            endDate: voteFormData.endDate
        )
        showVoting = true
    }

    /// 투표를 삭제하고 폼을 초기화합니다.
    func deleteVote() {
        voteFormData = VoteFormData()
        isVoteConfirmed = false
        originalVoteFormData = nil
    }

    /// 투표 옵션을 추가합니다. 최대 개수 제한을 초과하면 무시됩니다.
    func addVoteOption() {
        guard voteFormData.canAddOption else { return }
        voteFormData.options.append(VoteOptionItem())
    }

    /// 투표 옵션을 삭제합니다. 최소 개수 미만이면 무시됩니다.
    func removeVoteOption(_ option: VoteOptionItem) {
        guard voteFormData.canRemoveOption else { return }
        voteFormData.options.removeAll { $0.id == option.id }
    }

    // MARK: - Image Action

    /// 선택한 이미지를 로컬 카드 목록으로 반영합니다.
    ///
    /// 실제 서버 업로드는 저장 시점(`saveNotice`)에서만 수행됩니다.
    @MainActor
    func didLoadImages(images: [UIImage]) async {
        for image in images {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { continue }
            noticeImages.append(
                NoticeImageItem(
                    imageData: imageData,
                    isLoading: false,
                    fileId: nil
                )
            )
        }

        selectedPhotoItems.removeAll()
    }

    /// 첨부 이미지 목록에서 지정 항목을 제거합니다.
    func removeImage(_ item: NoticeImageItem) {
        noticeImages.removeAll { $0.id == item.id }
    }

    // MARK: - Link Action

    /// 첨부 링크 목록에서 지정 항목을 제거합니다.
    func removeLink(_ link: NoticeLinkItem) {
        noticeLinks.removeAll { $0.id == link.id }
    }
}
