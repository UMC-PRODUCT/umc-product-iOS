//
//  FetchCommunitySchoolsUseCaseProtocol.swift
//  AppProduct
//
//  Created by Codex on 2/24/26.
//

import Foundation

protocol FetchCommunitySchoolsUseCaseProtocol {
    func execute() async throws -> [String]
}
