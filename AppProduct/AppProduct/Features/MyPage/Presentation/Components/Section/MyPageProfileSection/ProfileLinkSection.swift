//
//  Profle.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import SwiftUI

/// 외부 프로필 링크 편집 섹션
/// TextField를 통해 URL을 직접 입력/수정할 수 있습니다.
struct ProfileLinkSection: View, Equatable {

    @Binding var profileLink: [ProfileLink]
    let header: String

    private enum Constants {
        static let iconSize: CGFloat = 24
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.header == rhs.header && lhs.profileLink == rhs.profileLink
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            Group {
                ForEach(SocialLinkType.allCases, id: \.self) { type in
                    generateTextField(
                        binding: binding(for: type),
                        placeholder: type.placeholder,
                        image: type.icon
                    )
                }
            }
        }, header: {
            SectionHeaderView(title: header)
        })
    }

    // MARK: - Private Method

    private func binding(for type: SocialLinkType) -> Binding<String> {
        Binding(
            get: {
                profileLink.first(where: { $0.type == type })?.url ?? ""
            },
            set: { newValue in
                if let originalIndex = profileLink.firstIndex(where: { $0.type == type }) {
                    profileLink[originalIndex].url = newValue
                } else {
                    profileLink.append(ProfileLink(type: type, url: newValue))
                }
            }
        )
    }

    /// URL 입력 필드를 생성합니다.
    ///
    /// 각 소셜 링크 타입에 맞는 아이콘과 플레이스홀더를 가진 TextField를 생성합니다.
    ///
    /// - Parameters:
    ///   - binding: URL 텍스트 바인딩
    ///   - placeholder: 입력 힌트 텍스트
    ///   - image: 링크 타입을 나타내는 아이콘
    /// - Returns: 아이콘과 TextField가 결합된 뷰
    private func generateTextField(binding: Binding<String>, placeholder: String, image: ImageResource) -> some View {
        HStack(spacing: DefaultSpacing.spacing8, content: {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: Constants.iconSize, height: Constants.iconSize)

            TextField("", text: binding, prompt: Text(placeholder))
        })
    }
}
