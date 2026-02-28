//
//  LinkSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import SwiftUI

/// MyPage에서 사용자의 외부 소셜 링크(GitHub, LinkedIn, Blog)를 표시하고 여는 Section 컴포넌트
///
/// 등록된 링크가 있으면 해당 URL을 열고, 없으면 Alert를 표시하여 프로필에서 링크를 추가하도록 안내합니다.
struct LinkSection: View {
    // MARK: - Property

    /// 섹션의 타입 (헤더 타이틀로 사용됨)
    let sectionType: MyPageSectionType
    /// 사용자의 소셜 링크 목록
    let profileLink: [ProfileLink]
    /// Alert 표시를 위한 바인딩
    @Binding var alertPromprt: AlertPrompt?
    @Environment(\.openURL) var openURL

    // MARK: - Function

    /// LinkSection 생성자
    /// - Parameters:
    ///   - sectionType: 섹션 타입
    ///   - profileLink: 사용자가 등록한 외부 링크 목록
    ///   - alertPromprt: Alert 표시를 위한 바인딩
    init(
        sectionType: MyPageSectionType,
        profileLink: [ProfileLink],
        alertPromprt: Binding<AlertPrompt?>
    ) {
        self.sectionType = sectionType
        self.profileLink = profileLink
        self._alertPromprt = alertPromprt
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            linkSectionForEach
        }, header: {
            SectionHeaderView(title: sectionType.rawValue)
        })
    }
    
    /// 모든 소셜 링크 타입에 대한 Row를 생성하는 ForEach
    private var linkSectionForEach: some View {
        ForEach(SocialLinkType.allCases, id: \.rawValue) { link in
            // 등록된 링크가 있으면 사용, 없으면 빈 URL로 생성
            let linkRow = profileLink.first(where: { $0.type == link }) ?? ProfileLink(type: link, url: "")

            Button(action: {
                // 유효한 URL이 있으면 열고, 없으면 Alert 표시
                if let validURL = Self.normalizedURL(linkRow.url) {
                    openURL(validURL)
                } else {
                    alertInsert(linkRow.type.rawValue)
                }
            }, label: {
                row(linkRow)
            })
            .buttonStyle(.borderless)
        }
    }

    /// 링크가 없을 때 Alert를 생성하는 함수
    /// - Parameter text: Alert 타이틀에 포함될 링크 타입 이름
    private func alertInsert(_ text: String) {
        alertPromprt = .init(
            id: .init(),
            title: "\(text) 열 수 없어요",
            message: "아직 등록된 링크가 없습니다. 프로필에서 링크를 추가해 주세요."
        )
    }

    /// 개별 링크 Row를 생성하는 함수
    /// - Parameter profileLink: 표시할 프로필 링크 데이터
    /// - Returns: MyPageSectionRow 뷰
    private func row(_ profileLink: ProfileLink) -> some View {
            MyPageSectionRow(icon: profileLink.type.icon, title: profileLink.type.title, rightImage: "arrow.up.right")
    }

    /// URL 문자열을 정규화하여 유효한 URL을 반환합니다.
    ///
    /// 스킴이 없는 경우 `https://`를 자동 보완합니다.
    /// 빈 문자열이거나 유효하지 않으면 `nil`을 반환합니다.
    private static func normalizedURL(_ rawURL: String) -> URL? {
        let trimmed = rawURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let directURL = URL(string: trimmed), directURL.scheme != nil {
            return directURL
        }

        if let withHTTPS = URL(string: "https://\(trimmed)") {
            return withHTTPS
        }

        return nil
    }
}
