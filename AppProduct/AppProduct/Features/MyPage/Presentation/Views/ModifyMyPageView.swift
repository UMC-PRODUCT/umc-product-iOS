//
//  ModifyMyPageView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/26/26.
//

import SwiftUI
import PhotosUI

/// 마이페이지 정보 수정 화면입니다.
///
/// 사용자의 프로필 이미지, 닉네임, 학교, 기수/파트, 활동 로그, 소셜 링크 등을 확인하고 수정할 수 있습니다.
struct ModifyMyPageView: View {
    /// 뷰모델 상태 객체
    @State var viewModel: ModifyMyPageViewModel
    
    var body: some View {
        Form {
            contentView
        }
        .navigation(naviTitle: .myPage, displayMode: .inline) // 네비게이션 타이틀 설정
        .toolbar(content: {
            // 완료 버튼
            ToolBarCollection.ConfirmBtn(action: {
                print("hello")
                // TODO: 수정 완료 액션 구현
            })
        })
        // 이미지 선택 시 비동기 로드 트리거
        .onChange(of: viewModel.selectedPhotoItem) { _, _ in
            Task {
                await viewModel.loadSelectedImage()
            }
        }
    }
    
    /// 데이터 로딩 상태에 따른 컨텐츠 뷰 분기 처리
    @ViewBuilder
    private var contentView: some View {
        switch viewModel.profileDataState {
        case .idle:
            Color.clear.task {
                print("hello") // 초기 로딩 트리거 등
            }
        case .loading:
            Progress(message: "내 정보를 가져오는 중입니다.", size: .regular)
        case .loaded:
            // 데이터가 로드되었고, 편집 가능한 데이터가 있는 경우 폼 표시
            if viewModel.editableProfileData != nil {
                sectionContent()
            }
        case .failed(let appError):
            Text("에러: \(appError.localizedDescription)")
        }
    }
    
    /// 실제 수정 폼 섹션들을 구성하는 뷰
    @ViewBuilder
    private func sectionContent() -> some View {
        // 프로필 데이터 바인딩 랩핑
        let profile = Binding(
            get: { viewModel.editableProfileData! },
            set: { viewModel.editableProfileData = $0 }
        )
        
        sectionContentImpl(profile)
    }
    
    /// 섹션 구현부
    /// - Parameter profile: 프로필 데이터 바인딩
    @ViewBuilder
    private func sectionContentImpl(_ profile: Binding<ProfileData>) -> some View {
        // 프로필 이미지 수정
        ProfileImagePicker(selectedPhotoItem: $viewModel.selectedPhotoItem, selectedImage: viewModel.selectedImage, profileImage: viewModel.profileDataState.value?.challangerInfo.profileImage)
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
                .disabled(true) // 입력 방지
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
        static let imageSize: CGFloat = 120
        static let btnText: String = "사진 변경"
    }
    
    
    var body: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            VStack(spacing: DefaultSpacing.spacing8, content: {
                if let selectedImage = selectedImage {
                    // 갤러리에서 새로 선택한 이미지 표시
                    Image(uiImage: selectedImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: Constants.imageSize, height: Constants.imageSize)
                        .clipShape(Circle())
                } else {
                    // 기존 프로필 이미지 (URL) 로드
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
        .listRowInsets(EdgeInsets()) // 리스트 셀 패딩 제거
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
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.header == rhs.header
    }
    
    var body: some View {
        Section(content: {
            Group {
                ForEach(profileLink.indices, id: \.self) { index in
                    generateTextField($profileLink[index].url, placeholder: profileLink[index].type.title)
                }
            }
        }, header: {
            SectionHeaderView(title: header)
        })
    }
    
    /// URL 입력 필드 생성
    private func generateTextField(_ text: Binding<String>, placeholder: String) -> some View {
        TextField("", text: text, prompt: Text(placeholder))
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var showNavi: Bool = false
    
    NavigationStack {
        Button(action: {
            showNavi.toggle()
        }, label: {
            Text("!1")
        })
        .navigationDestination(isPresented: $showNavi, destination: {
            ModifyMyPageView(
                viewModel: ModifyMyPageViewModel.preview
            )
        })
    }
}

extension ModifyMyPageViewModel {
    static var preview: ModifyMyPageViewModel {
        let viewModel = ModifyMyPageViewModel()
        
        let mockProfile = ProfileData(challengeId: 1,
                                      challangerInfo: .init(challengeId: 1, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대", profileImage: nil, part: .front(type: .ios)), socialConnected: [
                                        .apple, .kakao
                                      ], activityLogs: [
                                        .init(part: .design, generation: 11, role: .campusPartLeader),
                                        .init(part: .front(type: .ios), generation: 11, role: .centralOperator),
                                      ], profileLink: [
                                        ProfileLink(type: .github, url: "https://github.com/username"),
                                        ProfileLink(type: .linkedin, url: "https://linkedin.com/in/username"),
                                        ProfileLink(type: .blog, url: "https://portfolio.com")
                                      ])
        
        viewModel.loadProfileData(mockProfile)
        
        return viewModel
    }
}
