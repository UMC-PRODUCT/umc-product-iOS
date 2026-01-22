//
//  SessionRepositoryProtocol.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/16/26.
//

import Foundation

protocol SessionRepositoryProtocol {
    func fetchSessionList() async throws -> [Session]
}
