//
//  ModifyMyPageView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import SwiftUI
import PhotosUI

/// 마이페이지 정보 Write & Read 화면입니다.
///
/// 사용자의 프로필 이미지, 닉네임, 학교, 기수/파트, 활동 로그, 소셜 링크 등을 확인하고 수정할 수 있습니다.
struct MyPageProfileView: View {
    /// 뷰모델 상태 객체
    @State var viewModel: MyPageProfileViewModel
    
    init(profileData: ProfileData) {
        self._viewModel = .init(initialValue: .init(profileData: profileData))
    }
    
    var body: some View {
        Form {
            sectionContentImpl($viewModel.profileData)
        }
        .navigation(naviTitle: .myProfile, displayMode: .inline)
        .toolbar(content: {
            // 완료 버튼
            ToolBarCollection.ConfirmBtn(action: {
                print("hello")
                // TODO: 수정 완료 액션 구현
            })
        })
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadSelectedImage()
            }
        }
    }
    
    /// 섹션 구현부
    /// - Parameter profile: 프로필 데이터 바인딩
    @ViewBuilder
    private func sectionContentImpl(_ profile: Binding<ProfileData>) -> some View {
        // 프로필 이미지 수정
        ProfileImagePicker(selectedPhotoItem: $viewModel.selectedPhotoItem, selectedImage: viewModel.selectedImage, profileImage: viewModel.profileData.challangerInfo.profileImage)
        // 연동된 소셜 계정 정보
        ConnectionSocial(socialConnected: profile.socialConnected.wrappedValue, header: "연동된 계정")
        // 이름 및 닉네임 (읽기 전용)
        NameAndNickname(name: profile.challangerInfo.wrappedValue.name, nickaname: profile.challangerInfo.wrappedValue.nickname, header: "이름/닉네임")
        // 학교 (읽기 전용)
        SchoolSection(univ: profile.challangerInfo.wrappedValue.schoolName, header: "학교")
        // 기수 및 파트 (읽기 전용)
        GenAndPartSection(gen: profile.challangerInfo.wrappedValue.gen, part: profile.challangerInfo.wrappedValue.part, header: "기수/파트")
        // 활동 이력 목록
        ActiveLogs(rows: profile.activityLogs.wrappedValue, header: "활동 이력")
        // 외부 프로필 링크 수정
        ProfileLinkSection(profileLink: profile.profileLink, header: "외부 프로링크")
    }
}

// MARK: - Read-Only Text Field

/// 읽기 전용 텍스트 필드 (disabled TextField)
/// 사용자 정보 중 수정 불가능한 항목을 표시할 때 사용합니다.
fileprivate struct ReadOnlyTextField: View, Equatable {
    let placeholder: String
    let header: String
    
    var body: some View {
        Section {
            TextField("", text: .constant(""), prompt: Text(placeholder))
                .disabled(true)
        } header: {
            SectionHeaderView(title: header)
        }
    }
}

/// 프로필 이미지 선택 컴포넌트
/// 기존 이미지가 없으면 기본 이미지를, 선택된 이미지가 있으면 해당 이미지를 보여줍니다.
fileprivate struct ProfileImagePicker: View {
    
    @Binding var selectedPhotoItem: PhotosPickerItem?
    var selectedImage: UIImage?
    var profileImage: String? // URL string
    
    private enum Constants {
        static let imageSize: CGFloat = 112
        static let btnText: String = "사진 변경"
    }
    
    
    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            VStack(spacing: DefaultSpacing.spacing8, content: {
                if let selectedImage = selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                        .clipShape(Circle())
                } else {
                    RemoteImage(
                        urlString: profileImage ?? "",
                        size: .init(width: Constants.imageSize, height: Constants.imageSize),
                        cornerRadius: 60
                    )
                }
                Text(Constants.btnText)
                    .appFont(.caption1, color: .blue)
            })
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets())
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Connection Social

/// 연동된 소셜 계정 목록을 보여주는 섹션
fileprivate struct ConnectionSocial: View, Equatable {
    let socialConnected: [SocialType]
    let header: String
    
    var body: some View {
        Section {
            socialTagView
        } header: {
            SectionHeaderView(title: header)
        }
    }
    
    /// 소셜 아이콘 태그 컨테이너
    private var socialTagView: some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            ForEach(socialConnected, id: \.rawValue) { social in
                socialType(social)
            }
        }
    }
    
    /// 개별 소셜 타입 태그 뷰
    private func socialType(_ social: SocialType) -> some View {
        Text(social.rawValue)
            .appFont(.caption1Emphasis, color: social.fontColor)
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .glassEffect(.clear.tint(social.color), in: .containerRelative)
    }
}

// MARK: - Name And Nickname (Deprecated)

/// @deprecated ReadOnlyTextField 사용 권장
/// 이름과 닉네임을 표시하는 읽기 전용 뷰
fileprivate struct NameAndNickname: View, Equatable {
    let name: String
    let nickaname: String
    let header: String
    
    var body: some View {
        ReadOnlyTextField(
            placeholder: "\(name)/\(nickaname)",
            header: header
        )
    }
}

/// 학교 정보를 표시하는 읽기 전용 섹션
fileprivate struct SchoolSection: View, Equatable {
    let univ: String
    let header: String
    
    var body: some View {
        ReadOnlyTextField(placeholder: univ, header: header)
    }
}

/// 기수와 파트 정보를 표시하는 읽기 전용 섹션
fileprivate struct GenAndPartSection: View, Equatable {
    let gen: Int
    let part: UMCPartType
    let header: String
    
    var body: some View {
        ReadOnlyTextField(placeholder: "\(gen)기/\(part.name)", header: header)
    }
}

/// 활동 이력 목록을 보여주는 섹션
/// 각 이력은 ActiveLogRow를 통해 표시됩니다.
fileprivate struct ActiveLogs: View, Equatable {
    let rows: [ActivityLog]
    let header: String
    
    init(rows: [ActivityLog], header: String) {
        self.rows = rows
        self.header = header
    }
    
    var body: some View {
        Section(content: {
            VStack(spacing: DefaultSpacing.spacing16, content: {
                ForEach(rows, id: \.id) { row in
                    ActiveLogRow(row: row)
                        .equatable() // 성능 최적화를 위한 Equatable 적용
                }
            })
        }, header: {
            SectionHeaderView(title: header)
        })
    }
}

/// 외부 프로필 링크 편집 섹션
/// TextField를 통해 URL을 직접 입력/수정할 수 있습니다.
fileprivate struct ProfileLinkSection: View, Equatable {

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


