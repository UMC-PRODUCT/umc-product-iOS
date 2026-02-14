//
//  MyPageUseCaseProvider.swift
//  AppProduct
//
//  Created by euijjang97 on 2/15/26.
//

import Foundation

protocol MyPageUseCaseProviding {
    var fetchMyPageProfileUseCase: FetchMyPageProfileUseCaseProtocol { get }
    var updateMyPageProfileImageUseCase: UpdateMyPageProfileImageUseCaseProtocol { get }
}

final class MyPageUseCaseProvider: MyPageUseCaseProviding {
    let fetchMyPageProfileUseCase: FetchMyPageProfileUseCaseProtocol
    let updateMyPageProfileImageUseCase: UpdateMyPageProfileImageUseCaseProtocol

    init(repository: MyPageRepositoryProtocol) {
        self.fetchMyPageProfileUseCase = FetchMyPageProfileUseCase(
            repository: repository
        )
        self.updateMyPageProfileImageUseCase = UpdateMyPageProfileImageUseCase(
            repository: repository
        )
    }
}
