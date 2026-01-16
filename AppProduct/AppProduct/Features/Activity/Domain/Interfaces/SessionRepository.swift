//
//  SessionRepository.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import Foundation

protocol SessionRepository {
    func fetchSessionList() async throws -> [Session]
}
