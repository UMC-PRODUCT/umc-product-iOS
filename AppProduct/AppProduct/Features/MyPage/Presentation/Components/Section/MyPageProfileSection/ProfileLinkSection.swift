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

    /// 최소 3개의 링크를 보장하는 computed property
    private var normalizedProfileLinks: [ProfileLink] {
        var links = profileLink

        // SocialLinkType의 모든 케이스를 순회하며 부족한 만큼 추가
        let allTypes = SocialLinkType.allCases

        // 현재 존재하는 타입들
        let existingTypes = Set(links.map { $0.type })

        // 없는 타입들을 빈 값으로 추가
        for type in allTypes {
            if !existingTypes.contains(type) && links.count < Constants.minimumLinks {
                links.append(ProfileLink(type: type, url: ""))
            }
        }

        return links
    }

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
    
    /// URL 입력 필드 생성
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
