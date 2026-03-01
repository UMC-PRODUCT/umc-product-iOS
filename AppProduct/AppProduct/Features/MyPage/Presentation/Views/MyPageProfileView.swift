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
    @Environment(ErrorHandler.self) private var errorHandler
    @Environment(\.dismiss) private var dismiss

    init(container: DIContainer, profileData: ProfileData) {
        let provider = container.resolve(MyPageUseCaseProviding.self)
        self._viewModel = .init(
            initialValue: .init(
                profileData: profileData,
                useCaseProvider: provider
            )
        )
    }
    
    var body: some View {
        Form {
            sectionContentImpl($viewModel.profileData)
        }
        .navigation(naviTitle: .myProfile, displayMode: .inline)
        .toolbar(content: {
            // 완료 버튼
            ToolBarCollection.ConfirmBtn(
                action: { submitProfileUpdate() },
                disable: !viewModel.canSubmit,
                isLoading: viewModel.isUpdatingProfileImage,
                dismissOnTap: false
            )
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

    /// 프로필 이미지 업데이트를 서버에 제출하고 완료 시 화면을 dismiss합니다.
    ///
    /// 실패 시 ErrorHandler를 통해 Alert를 표시합니다.
    private func submitProfileUpdate() {
        Task {
            do {
                try await viewModel.submitProfileUpdate()
                dismiss()
            } catch {
                errorHandler.handle(
                    error,
                    context: .init(
                        feature: "MyPage",
                        action: "submitProfileUpdate"
                    )
                )
            }
        }
    }
}

#if DEBUG
// MARK: - Preview

private var myPageProfilePreviewContainer: DIContainer {
    let container = DIContainer()
    container.register(PathStore.self) { PathStore() }
    container.register(MyPageUseCaseProviding.self) {
        MyPageUseCaseProvider(repository: MockMyPageRepository())
    }
    return container
}

#Preview("MyPage Profile") {
    let container = myPageProfilePreviewContainer
    return NavigationStack {
        MyPageProfileView(
            container: container,
            profileData: MyPageMockData.profile
        )
    }
    .environment(\.di, container)
    .environment(ErrorHandler())
}
#endif
