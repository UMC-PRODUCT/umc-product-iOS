//
//  UserSessionManager.swift
//  AppProduct
//
//  Created by jaewon Lee on 1/23/26.
//

import Foundation

/// Activity 화면의 모드
enum ActivityMode: String, CaseIterable {
    case challenger
    case admin
}

/// 사용자 세션 및 권한을 관리하는 매니저
///
/// Activity 화면에서 Challenger/Admin 모드 전환을 위한 권한 정보를 제공합니다.
@Observable
final class UserSessionManager {

    // MARK: - Property

    /// 현재 사용자의 역할 (서버에서 받아온 실제 권한)
    // TODO: 바텀 엑세서리 확인 위해 기본 권환 바꿨으므로 추후 배포 시에는 challenger로 수정 필요 - [25.1.23] 이재원
    private(set) var currentRole: ManagementTeam = .centralOperator

    /// Admin 모드 활성화 여부
    private(set) var isAdminModeEnabled: Bool = false

    // MARK: - Computed Property

    /// Admin 모드 토글 가능 여부
    var canToggleAdminMode: Bool {
        currentRole.canAccessAdminMode
    }

    /// 현재 활성화된 Activity 모드
    var currentActivityMode: ActivityMode {
        isAdminModeEnabled ? .admin : .challenger
    }

    // MARK: - Function

    /// Admin 모드 토글
    func toggleAdminMode() {
        guard canToggleAdminMode else { return }
        isAdminModeEnabled.toggle()
    }

    /// 사용자 역할 업데이트 (로그인/세션 복원 시 호출)
    func updateRole(_ role: ManagementTeam) {
        currentRole = role
        // Admin 모드 접근 불가 역할로 변경되면 Admin 모드 비활성화
        if !role.canAccessAdminMode {
            isAdminModeEnabled = false
        }
    }

    /// 세션 초기화 (로그아웃 시 호출)
    func reset() {
        currentRole = .challenger
        isAdminModeEnabled = false
    }
}
