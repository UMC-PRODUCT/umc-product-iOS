//
//  StaffNoticeTabTests.swift
//  NoticeDomainTests
//
//  Created by euijjang97 on 11/2/26.
//

import Testing
import UMCFoundation
@testable import NoticeDomain

struct StaffNoticeTabTests {
    @Test("교내 운영진의 읽기 탭은 역할별 허용 범위를 유지한다")
    func accessibleTabsRespectReadPermissions() {
        #expect(StaffNoticeTab.accessibleTabs(for: .schoolEtcAdmin) == [.schoolPartLeader])
        #expect(StaffNoticeTab.accessibleTabs(for: .schoolPartLeader) == [.schoolPartLeader])
        #expect(StaffNoticeTab.accessibleTabs(for: .schoolPresident)
                == [.schoolCore, .schoolPartLeader])
        #expect(StaffNoticeTab.accessibleTabs(for: .chapterPresident)
                == [.schoolCore, .schoolPartLeader])
        #expect(StaffNoticeTab.accessibleTabs(for: .challenger).isEmpty)
        #expect(StaffNoticeTab.accessibleTabs(for: nil).isEmpty)
    }
}
