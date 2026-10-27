//
//  ForegroundThreadStore.swift
//  CoreRouting
//
//  Created by euijjang97 on 10/26/26.
//

import SwiftUI

/// 현재 화면에 노출된 스레드만 보관한다. 늦게 사라진 이전 화면은 새 화면을 지우지 않는다.
@MainActor
@Observable
public final class ForegroundThreadStore {
    private var threadId: String?
    public var isObscured = false
    public var visibleThreadId: String? { isObscured ? nil : threadId }
    private var owner: UUID?

    public init() {}

    public func show(threadId: String, owner: UUID) {
        self.threadId = threadId
        self.owner = owner
    }

    public func hide(owner: UUID) {
        guard self.owner == owner else { return }
        threadId = nil
        self.owner = nil
    }
}

public extension EnvironmentValues {
    @Entry var foregroundThreadStore: ForegroundThreadStore? = nil
}
