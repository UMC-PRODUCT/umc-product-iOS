//
//  MyPageSectionRow.swift
//  AppProduct
//
//  Created by euijjang97 on 1/27/26.
//

import SwiftUI

/// MyPage에서 사용되는 재사용 가능한 Row 컴포넌트
///
/// 왼쪽 아이콘, 중앙 타이틀, 오른쪽 컨텐츠(이미지 또는 텍스트)로 구성된 표준 Row 레이아웃을 제공합니다.
///
/// - Example:
/// ```swift
/// // 이미지 리소스 + 오른쪽 이미지
/// MyPageSectionRow(icon: .github, title: "GitHub", rightImage: "arrow.up.right")
///
/// // SF Symbol + 오른쪽 텍스트
/// MyPageSectionRow(systemIcon: "info.circle", title: "버전", rightText: "1.0.0")
/// ```
struct MyPageSectionRow: View {
    // MARK: - Property

    /// 왼쪽에 표시할 아이콘 타입 (ImageResource 또는 SF Symbol)
    let icon: RowIconType
    /// 중앙에 표시할 타이틀 텍스트
    let title: String
    /// 오른쪽에 표시할 컨텐츠 타입 (이미지, 텍스트, 없음)
    let rightContent: RowRightContentType

    // MARK: - Function

    /// ImageResource 아이콘과 오른쪽 이미지를 사용하는 Row 생성자
    /// - Parameters:
    ///   - icon: 왼쪽에 표시할 이미지 리소스
    ///   - title: 중앙에 표시할 타이틀
    ///   - rightImage: 오른쪽에 표시할 SF Symbol 이름
    init(icon: ImageResource, title: String, rightImage: String) {
        self.icon = .resource(icon)
        self.title = title
        self.rightContent = .image(rightImage)
    }

    /// SF Symbol 아이콘과 오른쪽 이미지를 사용하는 Row 생성자
    /// - Parameters:
    ///   - systemIcon: 왼쪽에 표시할 SF Symbol 이름
    ///   - title: 중앙에 표시할 타이틀
    ///   - rightImage: 오른쪽에 표시할 SF Symbol 이름
    init(systemIcon: String, title: String, rightImage: String) {
        self.icon = .system(systemIcon)
        self.title = title
        self.rightContent = .image(rightImage)
    }

    /// ImageResource 아이콘과 오른쪽 텍스트를 사용하는 Row 생성자
    /// - Parameters:
    ///   - icon: 왼쪽에 표시할 이미지 리소스
    ///   - title: 중앙에 표시할 타이틀
    ///   - rightText: 오른쪽에 표시할 텍스트
    init(icon: ImageResource, title: String, rightText: String) {
        self.icon = .resource(icon)
        self.title = title
        self.rightContent = .text(rightText)
    }

    /// SF Symbol 아이콘과 오른쪽 텍스트를 사용하는 Row 생성자
    /// - Parameters:
    ///   - systemIcon: 왼쪽에 표시할 SF Symbol 이름
    ///   - title: 중앙에 표시할 타이틀
    ///   - rightText: 오른쪽에 표시할 텍스트
    init(systemIcon: String, title: String, rightText: String) {
        self.icon = .system(systemIcon)
        self.title = title
        self.rightContent = .text(rightText)
    }

    private enum Constants {
        static let linkIcon: CGFloat = 20
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8, content: {
            iconImage
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.linkIcon, height: Constants.linkIcon)

            Text(title)
                .appFont(.subheadline, weight: .medium, color: .black)

            Spacer()

            rightContentView
        })
    }

    /// 아이콘 타입에 따라 Image를 반환하는 computed property
    private var iconImage: Image {
        switch icon {
        case .resource(let imageResource):
            return Image(imageResource)
        case .system(let systemName):
            return Image(systemName: systemName)
        }
    }

    /// 오른쪽 컨텐츠 타입에 따라 적절한 뷰를 반환하는 computed property
    @ViewBuilder
    private var rightContentView: some View {
        switch rightContent {
        case .image(let imageName):
            SectionRightImage(rightImage: imageName)
        case .text(let text):
            Text(text)
                .appFont(.subheadline, weight: .regular, color: .grey500)
        case .none:
            EmptyView()
        }
    }
}

/// MyPageSectionRow에서 사용하는 아이콘 타입
enum RowIconType {
    /// 앱 내부 이미지 리소스
    case resource(ImageResource)
    /// SF Symbol 시스템 이미지
    case system(String)
}

/// MyPageSectionRow 오른쪽에 표시할 컨텐츠 타입
enum RowRightContentType {
    /// 이미지 (SF Symbol 또는 Asset)
    case image(String)
    /// 텍스트
    case text(String)
    /// 없음
    case none
}
