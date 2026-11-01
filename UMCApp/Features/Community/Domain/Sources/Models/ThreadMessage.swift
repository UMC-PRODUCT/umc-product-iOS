//
//  ThreadMessage.swift
//  CommunityDomain
//
//  Created by euijjang97 on 8/12/26.
//

import Foundation

public struct ThreadMessageFile: Identifiable, Hashable, Sendable {

    // MARK: - Property

    /// 서버 `fileId`. `fileURL` 은 조회할 때마다 재발급되는 단기 서명 URL 이므로
    /// **캐시 키로 쓰면 안 되고** 이 값을 키로 쓴다.
    public let id: String
    public let fileName: String
    public let fileSize: String
    public let fileURL: String

    // MARK: - Init

    public init(id: String, fileName: String, fileSize: String, fileURL: String) {
        self.id = id
        self.fileName = fileName
        self.fileSize = fileSize
        self.fileURL = fileURL
    }
}

public struct ThreadMessageMention: Hashable, Sendable {

    // MARK: - Property

    public let memberId: String
    public let name: String

    // MARK: - Init

    public init(memberId: String, name: String) {
        self.memberId = memberId
        self.name = name
    }
}

public struct ThreadMessageReply: Hashable, Sendable {

    // MARK: - Property

    public let messageId: String
    public let senderName: String
    public let snippet: String

    // MARK: - Init

    public init(messageId: String, senderName: String, snippet: String) {
        self.messageId = messageId
        self.senderName = senderName
        self.snippet = snippet
    }
}

public struct ThreadMessageReaction: Hashable, Sendable {

    // MARK: - Property

    public let emoji: String
    public let count: String
    public let reactedByMe: Bool

    // MARK: - Init

    public init(emoji: String, count: String, reactedByMe: Bool) {
        self.emoji = emoji
        self.count = count
        self.reactedByMe = reactedByMe
    }
}

/// 채팅 메시지.
///
/// 낙관적 전송 중인 메시지는 서버 `messageId` 가 아직 없어 `id` 에 `clientMessageId` 를 넣는다.
/// `message.created` 를 받으면 같은 `clientMessageId` 를 가진 항목을 서버 값으로 교체한다.
public struct ThreadMessage: Identifiable, Hashable, Sendable {

    // MARK: - Property

    public let id: String
    public let threadId: String
    public let senderId: String
    public let senderName: String
    public let type: ThreadMessageType
    public var files: [ThreadMessageFile]
    public var mentions: [ThreadMessageMention]
    public var replyTo: ThreadMessageReply?
    public let clientMessageId: String?
    public let createdAt: Date
    /// 아래 4개는 `message.updated`/`message.deleted`/`reaction.changed` 와 낙관적 전송이
    /// 제자리에서 갱신하므로 `var` 다.
    public var isSenderBlocked: Bool
    public var content: String
    public var reactions: [ThreadMessageReaction]
    public var editedAt: Date?
    public var deletedAt: Date?
    public var deliveryState: ThreadMessageDeliveryState

    // MARK: - Init

    public init(
        id: String,
        threadId: String,
        senderId: String,
        senderName: String,
        content: String,
        type: ThreadMessageType,
        files: [ThreadMessageFile] = [],
        mentions: [ThreadMessageMention] = [],
        replyTo: ThreadMessageReply? = nil,
        reactions: [ThreadMessageReaction] = [],
        clientMessageId: String? = nil,
        createdAt: Date,
        editedAt: Date? = nil,
        deletedAt: Date? = nil,
        deliveryState: ThreadMessageDeliveryState = .sent,
        isSenderBlocked: Bool = false
    ) {
        self.isSenderBlocked = isSenderBlocked
        self.id = id
        self.threadId = threadId
        self.senderId = senderId
        self.senderName = senderName
        self.content = content
        self.type = type
        self.files = files
        self.mentions = mentions
        self.replyTo = replyTo
        self.reactions = reactions
        self.clientMessageId = clientMessageId
        self.createdAt = createdAt
        self.editedAt = editedAt
        self.deletedAt = deletedAt
        self.deliveryState = deliveryState
    }

    // MARK: - Computed Property

    /// 톰스톤 판정. 서버 `status` 는 `SENT` 하나뿐이라 삭제 표현에 쓸 수 없다.
    public var isDeleted: Bool { deletedAt != nil }

    public var isEdited: Bool { editedAt != nil }

    // MARK: - Function

    /// 차단 메시지 원문·첨부·링크·반응이 화면 및 요약으로 흘러가지 않게 제거한다.
    public func redactedForBlocking(hideReply: Bool = false) -> ThreadMessage {
        var copy = self
        if isSenderBlocked {
            copy.content = "차단한 사용자의 메시지예요."
            copy.files = []
            copy.mentions = []
            copy.reactions = []
            copy.replyTo = nil
        } else if hideReply {
            // 서버 인용에는 작성자 ID가 없어 페이지 밖 원본의 차단 여부를 검증할 수 없다.
            copy.replyTo = nil
        }
        return copy
    }

    /// 낙관적 전송의 상태 전이용 복사본 (Task 16 `insertOrReplace`).
    public func with(deliveryState: ThreadMessageDeliveryState) -> ThreadMessage {
        var copy = self
        copy.deliveryState = deliveryState
        return copy
    }
}

/// `GET /messages` 한 페이지. 서버는 **최신순**으로 준다.
public struct ThreadMessagePage: Equatable, Sendable {

    // MARK: - Property

    public let messages: [ThreadMessage]
    public let hasMore: Bool
    /// 다음 페이지 요청에 쓸 **배타적** 커서.
    public let nextBefore: String?

    // MARK: - Init

    public init(messages: [ThreadMessage], hasMore: Bool, nextBefore: String?) {
        self.messages = messages
        self.hasMore = hasMore
        self.nextBefore = nextBefore
    }
}
