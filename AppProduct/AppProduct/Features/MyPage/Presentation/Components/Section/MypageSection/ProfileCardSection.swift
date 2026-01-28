//
//  ProfileCardSection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/28/26.
//

import SwiftUI

/// MyPage 상단에 표시되는 사용자 프로필 카드 컴포넌트
///
/// 프로필 이미지, 이름/닉네임, 학교/기수/파트 정보를 보여주며, 탭하면 상세 프로필 페이지로 이동합니다.
struct ProfileCardSection: View {
    // MARK: - Property

    /// 표시할 사용자 프로필 데이터
    let profileData: ProfileData
    @Environment(\.di) var di

    private enum Constants {
        static let chevronSize: CGFloat = 9
        static let profileImageSize: CGSize = .init(width: 64, height: 64)
        static let chevron: String = "chevron.right"
    }

    /// DI Container에서 주입받은 NavigationRouter
    var router: NavigationRouter {
        di.resolve(NavigationRouter.self)
    }

    // MARK: - Function

    init(profileData: ProfileData) {
        self.profileData = profileData
    }

    // MARK: - Body

    var body: some View {
        Button(action: {
            router.push(to: .myPage(.myInfo(profileData: profileData)))
        }, label: {
            HStack(spacing: DefaultSpacing.spacing12, content: {
                profileImage
                profileInfo
                Spacer()
                SectionRightImage(rightImage: Constants.chevron)
            })
        })
    }
    
    /// 프로필 이미지 뷰 (무지개 테두리 효과 포함)
    private var profileImage: some View {
        RemoteImage(urlString: profileData.challangerInfo.profileImage ?? "", size: Constants.profileImageSize)
            .rainbowBorder(lineWidth: 3, shape: .circle)
            .glassEffect(.clear, in: .circle)
    }

    /// 프로필 정보(이름/닉네임, 학교/기수/파트) 전체를 담는 VStack
    private var profileInfo: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4, content: {
            challengerName
            challengerPartInfo
                .appFont(.caption1, weight: .medium, color: .grey500)
        })
    }

    /// 챌린저 이름 및 닉네임을 표시하는 뷰 (예: "정의찬 / 제옹")
    private var challengerName: some View {
        HStack(spacing: DefaultSpacing.spacing4, content: {
            Text(profileData.challangerInfo.name)
                .appFont(.bodyEmphasis, color: .black)

            Text("/")

            Text(profileData.challangerInfo.nickname)
        })
        .appFont(.bodyEmphasis, color: .black)
    }

    /// 챌린저의 학교, 기수, 파트 정보를 표시하는 뷰 (예: "중앙대 • 11기 • Design")
    private var challengerPartInfo: some View {
        HStack(spacing: DefaultSpacing.spacing4) {
            Text(profileData.challangerInfo.schoolName)
            Text("•")
            Text("\(profileData.challangerInfo.gen)기")
            Text("•")
            Text(profileData.challangerInfo.part.name)
        }
    }
}
