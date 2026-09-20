//
//  ProjectRoutingView.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import CoreDI
import SwiftUI

/// ``ProjectDestination``을 실제 화면으로 바꾸는 라우팅 뷰.
///
/// App 셸이 탭 스택의 `.navigationDestination(for: ProjectDestination.self)`에서 쓴다.
/// 목적지와 짝을 이뤄 `public` 이다 (선례: `BusinessCardRoutingView`).
///
/// - Important: 자체 `NavigationStack`을 만들지 않는다. 탭별 스택은 상위 셸이 소유한다.
public struct ProjectRoutingView: View {

    // MARK: - Property

    private let destination: ProjectDestination
    private let container: DIContainer

    // MARK: - Init

    public init(destination: ProjectDestination, container: DIContainer) {
        self.destination = destination
        self.container = container
    }

    // MARK: - Body

    public var body: some View {
        switch destination {
        case .myProjects:
            MyProjectsView(container: container)

        case .detail(let projectId):
            ProjectDetailView(container: container, projectId: projectId)

        case .editInfo(let projectId):
            ProjectInfoEditorView(container: container, projectId: projectId)

        case .manageMembers(let projectId):
            ProjectMemberManagementView(container: container, projectId: projectId)

        case .transferOwnership(let projectId):
            ProjectOwnershipTransferView(container: container, projectId: projectId)

        case .applicationForm(let projectId):
            ProjectApplicationFormEditorView(container: container, projectId: projectId)
        }
    }
}
