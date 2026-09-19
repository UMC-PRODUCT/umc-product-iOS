//
//  CommunityThreadRoomViewModel+Edit.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import Foundation
import CommunityDomain
import UMCFoundation

/// 내 메시지 수정.
///
/// 먼저 말풍선을 고쳐 두고 보낸다. 성공은 `message.updated` 가 서버 값으로 덮어 확정하지만,
/// 실패는 `clientMessageId` 없는 에러 프레임으로만 온다. 그래서 `x-command-id` 를 여기서 만들어
/// 원문과 함께 쥐고 있다가, 같은 id 의 에러가 오면 되돌리고 ACK 가 오면 버린다.
extension CommunityThreadRoomViewModel {

    /// 되돌리기에 필요한 수정 전 값과, 되돌려도 되는지 판단할 낙관적 본문.
    struct PendingEdit {
        let messageId: String
        let originalContent: String
        let originalEditedAt: Date?
        let editedContent: String
    }

    // MARK: - Function

    /// 수정 메뉴를 띄울지. 서버는 작성자의, 삭제되지 않은 TEXT 메시지만 고치게 한다.
    public func canEdit(_ message: ThreadMessage) -> Bool {
        canWrite
            && message.deliveryState == .sent
            && isMine(message)
            && message.type == .text
            && !message.isDeleted
    }

    /// 컨텍스트 메뉴의 "수정" 진입점. 컴포저에 원문을 채우고 수정 모드로 바꾼다.
    ///
    /// 답장·멘션은 걷어 낸다 — 서버 수정 본문은 `content` 하나라 실을 자리가 없다.
    public func requestEdit(_ message: ThreadMessage) {
        guard canEdit(message) else { return }

        clearComposerAttachments()
        editTarget = message
        draft = message.content
    }

    /// 수정 칩의 취소 버튼. 채워 둔 원문도 함께 비운다.
    public func cancelEdit() {
        editTarget = nil
        draft = ""
    }

    // MARK: - Internal Function

    /// 수정 모드의 전송 버튼. `send()` 가 이리로 돌린다.
    func submitEdit() async {
        guard canSend, let target = editTarget else { return }

        let content = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        cancelEdit()
        await performEdit(messageId: target.id, content: content)
    }

    /// ACK 는 커밋 뒤에만 온다. 받은 명령은 더 되돌릴 일이 없다.
    func settleEdit(commandId: String) {
        pendingEdits.removeValue(forKey: commandId.lowercased())
    }

    /// 에러 프레임 반영. 이 화면이 보낸 수정이 아니면 아무 일도 하지 않는다.
    func applyEditFailure(_ error: RealtimeCommandError) {
        guard let commandId = error.commandId, rollbackEdit(commandId: commandId) else { return }
        // 되돌리기만 하면 고친 글이 말없이 사라진 것처럼 보인다 (#1375 반응과 같은 이유).
        errorHandler.handle(error, context: ErrorContext(
            feature: "Community",
            action: "editMessage"
        ))
    }

    // MARK: - Private Function

    /// 본문이 그대로면 보내지 않는다. 서버가 중복으로 보고 `message.updated` 를 내지 않아,
    /// 낙관적으로 찍은 "(수정됨)" 을 되돌릴 이벤트가 오지 않는다.
    private func performEdit(messageId: String, content: String) async {
        guard let index = messages.firstIndex(where: { $0.id == messageId }),
              canEdit(messages[index]),
              messages[index].content != content else { return }

        let commandId = UUID().uuidString.lowercased()
        // 에러 프레임이 SEND 직후 바로 올 수 있어 보내기 전에 등록한다.
        pendingEdits[commandId] = PendingEdit(
            messageId: messageId,
            originalContent: messages[index].content,
            originalEditedAt: messages[index].editedAt,
            editedContent: content
        )
        messages[index].content = content
        messages[index].editedAt = Date()

        do {
            try await useCase.editMessage(
                threadId: threadId,
                messageId: messageId,
                commandId: commandId,
                content: content
            )
        } catch {
            rollbackEdit(commandId: commandId)
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "editMessage",
                retryAction: { [weak self] in
                    await self?.performEdit(messageId: messageId, content: content)
                }
            ))
        }
    }

    /// 내가 찍은 본문 그대로일 때만 되돌린다 — 그 사이 `message.updated` 가 다른 값으로 덮었다면
    /// 서버 값이 더 정확하다. 반응처럼 수정과 무관한 필드는 건드리지 않는다.
    @discardableResult
    private func rollbackEdit(commandId: String) -> Bool {
        guard let pending = pendingEdits.removeValue(forKey: commandId.lowercased()) else {
            return false
        }
        if let index = messages.firstIndex(where: { $0.id == pending.messageId }),
           messages[index].content == pending.editedContent {
            messages[index].content = pending.originalContent
            messages[index].editedAt = pending.originalEditedAt
        }
        return true
    }
}
