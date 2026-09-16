//
//  CalendarSyncAuthorization.swift
//  HomeDomain
//
//  Created by euijjang97 on 9/16/26.
//

import Foundation

/// 애플 캘린더 접근 권한 상태.
///
/// EventKit 의 `EKAuthorizationStatus` 를 도메인 어휘로 옮긴 값이다. 연동은 기존 이벤트의
/// 갱신·삭제까지 필요하므로 풀 액세스만 ``authorized`` 로 본다 — write-only 허용은
/// 이벤트 조회가 막혀 reconcile 이 불가능하니 ``denied`` 와 같게 취급한다.
public enum CalendarSyncAuthorization: Sendable, Equatable {

    /// 아직 묻지 않았다. 토글 ON 시 권한 요청을 띄울 수 있다.
    case notDetermined

    /// 사용자가 거부했거나 write-only 만 허용했다. 설정 앱에서만 바꿀 수 있다.
    case denied

    /// 기기 정책(스크린 타임 등)으로 막혀 있다. 사용자가 바꿀 수 없다.
    case restricted

    /// 풀 액세스 허용.
    case authorized
}
