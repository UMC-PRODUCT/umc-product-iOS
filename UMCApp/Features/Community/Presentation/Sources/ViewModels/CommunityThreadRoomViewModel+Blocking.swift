//
//  CommunityThreadRoomViewModel+Blocking.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 10/29/26.
//

import CommunityDomain

extension CommunityThreadRoomViewModel {
    func isSenderBlocked(_ message: ThreadMessage) -> Bool {
        guard !isMine(message), message.type != .system else { return false }
        return blockStore?.isBlocked(message.senderId, serverValue: message.isSenderBlocked)
            ?? message.isSenderBlocked
    }

    func isMessageHidden(_ message: ThreadMessage) -> Bool {
        isSenderBlocked(message) && !revealedBlockedMessageIds.contains(message.id)
    }

    func toggleBlockedMessage(_ message: ThreadMessage) {
        guard isSenderBlocked(message) else { return }
        if !revealedBlockedMessageIds.insert(message.id).inserted {
            revealedBlockedMessageIds.remove(message.id)
        }
    }

    /// 다른 사용자의 답장으로 차단한 메시지 본문이 다시 노출되는 것을 막는다.
    func displayedMessage(_ message: ThreadMessage) -> ThreadMessage {
        guard let reply = message.replyTo else { return message }
        let original = messages.first { $0.id == reply.messageId }
        let hideQuote = original.map(isSenderBlocked)
            ?? (blockStore?.blockedMemberIds.isEmpty == false)
        guard hideQuote else { return message }
        var copy = message
        copy.replyTo = nil
        return copy
    }
}
