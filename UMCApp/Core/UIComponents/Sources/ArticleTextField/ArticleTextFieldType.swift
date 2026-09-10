//
//  ArticleTextFieldType.swift
//  CoreUIComponents
//
//  Created by 이예지 on 7/3/26.
//

import Foundation
import SwiftUI
import CoreDesignSystem

public enum ArticleTextFieldType {
    case title
    case content
    case threadTitle
    case threadDescription

    public var placeholderLabel: String {
        switch self {
        case .title:
            return "제목을 입력하세요."
        case .content:
            return "내용을 입력하세요."
        case .threadTitle:
            return "스레드 제목을 입력하세요."
        case .threadDescription:
            return "스레드 특징을 입력하세요"
        }
    }

    public var placeholderFont: AppFont {
        switch self {
        case .title, .threadTitle:
            return .title3
        case .content:
            return .body
        case .threadDescription:
            return .subheadline
        }
    }

    /// `.title` 은 이 값이 `.semibold` 로 적혀 있었지만 실제 렌더에 반영된 적이 없다.
    /// 그대로 살리면 공지 에디터 제목이 갑자기 굵어지므로 보이던 대로 Regular 에 맞춘다.
    public var placeholderWeight: AppFontWeight {
        switch self {
        case .title, .content, .threadDescription:
            return .regular
        case .threadTitle:
            return .semibold
        }
    }

    public var axis: Axis {
        switch self {
        case .title, .threadTitle:
            return .horizontal
        case .content, .threadDescription:
            return .vertical
        }
    }

    public var scrollIndicator: ScrollIndicatorVisibility {
        switch self {
        case .title, .threadTitle, .threadDescription:
            return .hidden
        case .content:
            return .visible
        }
    }
}
