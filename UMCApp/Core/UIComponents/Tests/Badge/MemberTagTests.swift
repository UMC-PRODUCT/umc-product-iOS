//
//  MemberTagTests.swift
//  CoreUIComponentsTests
//
//  Created by euijjang97 on 11/1/26.
//

import SwiftUI
import Testing
import UMCFoundation
@testable import CoreUIComponents

@Suite("MemberTag — Figma 태그 계약")
struct MemberTagTests {
    @Test("현행 파트는 Figma filled/outlined 팔레트를 사용한다")
    func partPalettes() {
        let expected: [(UMCPartType, String, String, String)] = [
            (.pm, "EEE3FC", "F6F0FF", "7F39C6"),
            (.design, "FFE0F1", "FFF0F7", "D92680"),
            (.webProductEngineer, "FFF0C2", "FFF7E0", "ED8002"),
            (.mobileProductEngineer, "E0E8FF", "F0F4FF", "385CDC"),
        ]
        for (part, fill, outlined, text) in expected {
            #expect(hex(part.tagPalette.fill) == fill)
            #expect(hex(part.tagPalette.outlinedFill) == outlined)
            #expect(hex(part.tagPalette.text) == text)
        }
    }

    @Test("태그 표기는 직책과 권한을 보존하면서 디자인의 그룹명으로 통일한다")
    func roleLabels() {
        #expect(ManagementTeam.superAdmin.tagName == "Admin")
        #expect(ManagementTeam.centralOperatingTeamMember.tagName == "중앙 운영진")
        #expect(ManagementTeam.centralEducationTeamMember.tagName == "중앙 운영진")
        #expect(ManagementTeam.schoolPartLeader.tagName == "교내 운영진")
        #expect(ManagementTeam.schoolEtcAdmin.tagName == "교내 운영진")
        #expect(ManagementTeam.schoolPartLeader.korean == "교내 파트장")
        #expect(ManagementTeam.schoolPartLeader.rawValue == "SCHOOL_PART_LEADER")
        #expect(ManagementTeam.schoolPartLeader.level > ManagementTeam.schoolEtcAdmin.level)
    }

    @Test("역할별 글자와 배경은 Figma 그룹 팔레트와 일치한다")
    func rolePalettes() {
        let expected: [(ManagementTeam, String, String)] = [
            (.superAdmin, "DDF4F1", "02746C"),
            (.challenger, "DDF4F1", "02746C"),
            (.centralPresident, "EAE5FB", "634AC9"),
            (.centralVicePresident, "EAE5FB", "634AC9"),
            (.centralOperatingTeamMember, "EAE5FB", "634AC9"),
            (.centralEducationTeamMember, "EAE5FB", "634AC9"),
            (.chapterPresident, "EEE6DD", "886544"),
            (.schoolPresident, "DBECFF", "0068E0"),
            (.schoolVicePresident, "DBECFF", "0068E0"),
            (.schoolPartLeader, "DBECFF", "0068E0"),
            (.schoolEtcAdmin, "DBECFF", "0068E0"),
        ]
        for (role, background, text) in expected {
            #expect(hex(role.backgroundColor) == background)
            #expect(hex(role.textColor) == text)
        }
    }

    @Test("모바일 태그 높이는 22pt이고 큰 글자에서는 잘리지 않고 늘어난다")
    @MainActor
    func dynamicTypeLayout() throws {
        let regular = ImageRenderer(content: MemberTag(part: .mobileProductEngineer))
        let accessible = ImageRenderer(content:
            MemberTag(part: .mobileProductEngineer).environment(\.dynamicTypeSize, .accessibility5)
        )
        let regularImage = try #require(regular.uiImage)
        let accessibleImage = try #require(accessible.uiImage)
        #expect(regularImage.size.height == 22)
        #expect(accessibleImage.size.height > regularImage.size.height)
    }

    private func hex(_ color: Color) -> String {
        let resolved = color.resolve(in: EnvironmentValues())
        return String(
            format: "%02X%02X%02X",
            Int((resolved.red * 255).rounded()),
            Int((resolved.green * 255).rounded()),
            Int((resolved.blue * 255).rounded())
        )
    }
}
