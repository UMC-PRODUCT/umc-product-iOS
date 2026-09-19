//
//  ProjectDestination.swift
//  ProjectPresentation
//
//  Created by euijjang97 on 9/19/26.
//

/// 프로젝트 화면 목적지.
///
/// 마이페이지 탭 스택 위에 쌓이지만 MyPage 모듈이 소유하지 않는다 — Feature 간 의존을 만들지
/// 않고 App 셸이 중개하는 규약(선례: `BusinessCardDestination`)이라 `public` 이다.
/// App 셸이 탭 스택마다 `.navigationDestination(for:)` 로 등록하므로 모듈 안 화면은
/// `NavigationLink(value:)` 로 다음 목적지를 push 한다.
public enum ProjectDestination: Hashable {

    /// 내 프로젝트 — 관리 프로젝트·초안·내 지원 내역 (#1476).
    case myProjects

    /// 프로젝트 상세 + 팀원 구성.
    case detail(projectId: String)
}
