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
        static let minimumLinks: Int = 3
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.header == rhs.header
    }

    /// 최소 3개의 링크 필드를 보장하는 정규화된 프로필 링크 배열
    ///
    /// 사용자가 입력한 링크가 3개 미만일 경우, 부족한 개수만큼
    /// 빈 값을 가진 링크 필드를 자동으로 추가하여 반환합니다.
    private var normalizedProfileLinks: [ProfileLink] {
        var links = profileLink

        // SocialLinkType의 모든 케이스를 순회하며 부족한 만큼 추가
        let allTypes = SocialLinkType.allCases

        // 현재 존재하는 타입들
        let existingTypes = Set(links.map { $0.type })

        // 없는 타입들을 빈 값으로 추가 (최소 3개 유지)
        for type in allTypes {
            if !existingTypes.contains(type) && links.count < Constants.minimumLinks {
                links.append(ProfileLink(type: type, url: ""))
            }
        }

        return links
    }

    // MARK: - Body

    var body: some View {
        Section(content: {
            Group {
                ForEach(normalizedProfileLinks.indices, id: \.self) { index in
                    let link = normalizedProfileLinks[index]
                    generateTextField(
                        binding: Binding(
                            get: { link.url },
                            set: { newValue in
                                // 원본 배열에서 해당 타입의 링크를 찾아서 업데이트
                                if let originalIndex = profileLink.firstIndex(where: { $0.type == link.type }) {
                                    profileLink[originalIndex].url = newValue
                                } else {
                                    // 원본에 없으면 새로 추가
                                    profileLink.append(ProfileLink(type: link.type, url: newValue))
                                }
                            }
                        ),
                        placeholder: link.type.placeholder,
                        image: link.type.icon
                    )
                }
            }
        }, header: {
            SectionHeaderView(title: header)
        })
    }

    // MARK: - Private Method

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
