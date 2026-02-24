//
//  FetchCommunitySchoolsUseCaseProtocol.swift
//  AppProduct
//
//  Created by euijjang97 on 2/24/26.
//

import Foundation

protocol FetchCommunitySchoolsUseCaseProtocol {
    func execute() async throws -> [String]
}
