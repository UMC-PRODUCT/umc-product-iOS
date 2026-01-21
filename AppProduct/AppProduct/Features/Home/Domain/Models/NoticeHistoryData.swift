//
//  NoticeHistoryData.swift
//  AppProduct
//
//  Created by euijjang97 on 1/20/26.
//

import Foundation
import SwiftData

@Model
class NoticeHistoryData {
    @Attribute(.unique) var id: UUID
    var title: String
    var content: String
    var icon: NoticeAlarmType
    var createdAt: Date

    // MARK: - Init
    init(
        id: UUID = .init(),
        title: String,
        content: String,
        icon: NoticeAlarmType,
        createdAt: Date
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.icon = icon
        self.createdAt = createdAt
    }

    // MARK: - CoreML Init
    convenience init(
        id: UUID = .init(),
        title: String,
        content: String,
        createdAt: Date
    ) {
        let repository = NoticeClassifierRepositoryImpl()
        let usecase = NoticeClassifierUseCaseImpl(repository: repository)
        let classifiedIcon = usecase.execute(title: title, content: content)

        self.init(
            id: id,
            title: title,
            content: content,
            icon: classifiedIcon,
            createdAt: createdAt
        )
    }
}
