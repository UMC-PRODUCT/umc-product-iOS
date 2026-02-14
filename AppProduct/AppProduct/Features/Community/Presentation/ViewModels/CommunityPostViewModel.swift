//
//  CommunityPostViewModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/28/26.
//

import Foundation

@Observable
class CommunityPostViewModel {
    // MARK: - Dependencies
    
    private let createPostUseCase: CreatePostUseCaseProtocol
    
    // MARK: - Properties
    var selectedCategory: CommunityItemCategory = .question
    
    var titleText: String = ""
    var contentText: String = ""
    
    var selectedDate: Date = Date()
    var maxParticipants: Int = 3
    var selectedPlace: PlaceSearchInfo = .init(name: "", address: "", coordinate: .init(latitude: 0.0, longitude: 0.0))
    var linkText: String = ""
    
    private(set) var createPostState: Loadable<CommunityItemModel> = .idle
    
    // MARK: - Computed Properties
    var isValid: Bool {
        let hasBasicInfo = !titleText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !contentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if selectedCategory == .lighting {
            let hasPlace = !selectedPlace.name.isEmpty
            let hasLink = !linkText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            return hasBasicInfo && hasPlace && hasLink
        }
        return hasBasicInfo
    }
    
    // MARK: - Init
    
    init(createPostUseCase: CreatePostUseCaseProtocol) {
        self.createPostUseCase = createPostUseCase
    }
    
    // MARK: - Function
    
//    @MainActor
//    func createPost() async {
//        createPostState = .loading
//        
//        let request = CreateLightningPostRequestDTO(
//            title: titleText,
//            content: contentText,
//            meetAt: selectedDate,
//            location: selectedPlace,
//            maxParticipants: maxParticipants,
//            link: linkText
//        )
//        
//        do {
//            let createPost = try await createPostUseCase.execute(request: request)
//            createPostState = .loaded(createPost)
//        } catch let error as DomainError {
//            createPostState = .failed(.domain(error))
//        } catch {
//            createPostState = .failed(.unknown(message: error.localizedDescription))
//        }
//    }
}
