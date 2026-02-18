//
//  CommunityPostViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/28/26.
//

import Foundation

@Observable
class CommunityPostViewModel {
    // MARK: - Properties

    private let useCaseProvider: CommunityUseCaseProviding
    private let errorHandler: ErrorHandler

    var selectedCategory: CommunityItemCategory = .question
    var titleText: String = ""
    var contentText: String = ""

    var selectedDate: Date = Date()
    var maxParticipants: Int = 3
    var selectedPlace: PlaceSearchInfo = .init(name: "", address: "", coordinate: .init(latitude: 0.0, longitude: 0.0))
    var linkText: String = ""
    
    /// API 상태
    private(set) var submitState: Loadable<Bool> = .idle
    
    /// 수정 모드일 때 대상 일정 ID
    private(set) var editingPostId: Int?
    /// 수정 모드 초기값 스냅샷
    private var initialEditSnapshot: EditFormSnapshot?
    
    // MARK: - Computed Properties

    var isEditMode: Bool {
        editingPostId != nil
    }

    var isValid: Bool {
        let hasBasicInfo = !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if selectedCategory == .lighting {
            let hasPlace = !selectedPlace.name.isEmpty
            let hasLink = !linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

            return hasBasicInfo && hasPlace && hasLink
        }
        return hasBasicInfo
    }

    /// 수정 모드에서 초기값 대비 변경 사항이 있는지 확인합니다.
    var hasChangesInEditMode: Bool {
        guard initialEditSnapshot != nil else { return true }
        return initialEditSnapshot != currentEditSnapshot
    }

    /// 현재 폼 상태의 스냅샷을 생성합니다.
    private var currentEditSnapshot: EditFormSnapshot {
        EditFormSnapshot(
            title: titleText,
            content: contentText,
            category: selectedCategory,
            meetAt: selectedCategory == .lighting ? selectedDate : nil,
            maxParticipants: selectedCategory == .lighting ? maxParticipants : nil,
            location: selectedCategory == .lighting ? selectedPlace.address : nil,
            openChatUrl: selectedCategory == .lighting ? linkText : nil
        )
    }

    // MARK: - Init

    init(container: DIContainer, errorHandler: ErrorHandler) {
        self.useCaseProvider = container.resolve(CommunityUseCaseProviding.self)
        self.errorHandler = errorHandler
    }

    // MARK: - Prefill

    /// 게시글 상세 데이터를 기반으로 등록 폼을 프리필합니다.
    func applyPrefill(from post: CommunityItemModel) {
        editingPostId = post.postId
        selectedCategory = post.category
        titleText = post.title
        contentText = post.content

        initialEditSnapshot = currentEditSnapshot
    }

    // MARK: - Function

    @MainActor
    func createPost() async {
        submitState = .loading

        do {
            if selectedCategory == .lighting {
                // 번개 모임 생성
                let meetAtString = ISO8601DateFormatter().string(from: selectedDate)

                let request = CreateLightningPostRequestDTO(
                    title: titleText,
                    content: contentText,
                    meetAt: meetAtString,
                    location: selectedPlace.address,
                    maxParticipants: maxParticipants,
                    openChatUrl: linkText
                )

                try await useCaseProvider.createLightningUseCase.execute(request: request)
                submitState = .loaded(true)
            } else {
                // 일반 게시글 생성 (질문/자유)
                let request = PostRequestDTO(
                    title: titleText,
                    content: contentText,
                    category: selectedCategory.rawValue
                )

                try await useCaseProvider.createPostUseCase.execute(request: request)
                submitState = .loaded(true)
            }
        } catch let error as AppError {
            submitState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "createPost",
                retryAction: { [weak self] in
                    await self?.createPost()
                }
            ))
        } catch {
            submitState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "createPost",
                retryAction: { [weak self] in
                    await self?.createPost()
                }
            ))
        }
    }

    /// 게시글을 서버에 수정합니다.
    @MainActor
    func updatePost() async {
        guard let postId = editingPostId else {
            return
        }

        submitState = .loading

        do {
            if selectedCategory == .lighting {
                // 번개 모임 수정
                let meetAtString = ISO8601DateFormatter().string(from: selectedDate)

                let request = CreateLightningPostRequestDTO(
                    title: titleText,
                    content: contentText,
                    meetAt: meetAtString,
                    location: selectedPlace.address,
                    maxParticipants: maxParticipants,
                    openChatUrl: linkText
                )

                try await useCaseProvider.updateLightningUseCase.execute(
                    postId: postId,
                    request: request
                )
                submitState = .loaded(true)
            } else {
                // 일반 게시글 수정 (질문/자유)
                let request = PostRequestDTO(
                    title: titleText,
                    content: contentText,
                    category: selectedCategory.rawValue
                )

                try await useCaseProvider.updatePostUseCase.execute(
                    postId: postId,
                    request: request
                )
                submitState = .loaded(true)
            }
        } catch let error as AppError {
            submitState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "updatePost",
                retryAction: { [weak self] in
                    await self?.updatePost()
                }
            ))
        } catch {
            submitState = .idle
            errorHandler.handle(error, context: ErrorContext(
                feature: "Community",
                action: "updatePost",
                retryAction: { [weak self] in
                    await self?.updatePost()
                }
            ))
        }
    }

    @MainActor
    func submit() async {
        if editingPostId != nil {
            await updatePost()
        } else {
            await createPost()
        }
    }

    /// 수정 모드에서 변경 감지를 위한 폼 상태 스냅샷
    private struct EditFormSnapshot: Equatable {
        let title: String
        let content: String
        let category: CommunityItemCategory
        let meetAt: Date?
        let maxParticipants: Int?
        let location: String?
        let openChatUrl: String?
    }
}
