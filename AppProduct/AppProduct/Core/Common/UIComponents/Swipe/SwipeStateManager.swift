//
//  SwipeStateManager.swift
//  AppProduct
//
//  Created by jaewon Lee on 2/8/26.
//

import Foundation

// MARK: - SwipeStateManager

@Observable
final class SwipeStateManager {
    // MARK: - Property

    private(set) var openCellID: UUID? = nil

    // MARK: - Function

    func open(_ id: UUID) {
        openCellID = id
    }

    func close() {
        openCellID = nil
    }

    func isOpen(_ id: UUID) -> Bool {
        openCellID == id
    }
}
