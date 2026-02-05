//
//  MockMemberRepository.swift
//  AppProduct
//
//  Created by 김미주 on 2/5/26.
//

import Foundation

final class MockMemberRepository: MemberRepositoryProtocol {
    // MARK: - Function
    func fetchMembers() async throws -> [MemberManagementItem] {
        return [
            .init(
                profile: nil,
                name: "이예지",
                generation: "9기",
                position: "Part Leader",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .schoolPartLeader
            ),
            .init(
                profile: nil,
                name: "이예지",
                generation: "9기",
                position: "Part Leader",
                part: .front(type: .ios),
                penalty: 0,
                badge: false,
                managementTeam: .schoolPartLeader
            ),
            .init(
                profile: nil,
                name: "김철수",
                generation: "9기",
                position: "Member",
                part: .front(type: .android),
                penalty: 1,
                badge: false,
                managementTeam: .challenger
            ),
            .init(
                profile: nil,
                name: "박영희",
                generation: "9기",
                position: "Member",
                part: .server(type: .spring),
                penalty: 0,
                badge: false,
                managementTeam: .challenger
            ),
            .init(
                profile: nil,
                name: "최민수",
                generation: "9기",
                position: "Member",
                part: .front(type: .web),
                penalty: 2,
                badge: false,
                managementTeam: .challenger
            ),
            .init(
                profile: nil,
                name: "정다은",
                generation: "9기",
                position: "Member",
                part: .design,
                penalty: 0,
                badge: false,
                managementTeam: .challenger
            ),
            .init(
                profile: nil,
                name: "강호진",
                generation: "9기",
                position: "Member",
                part: .pm,
                penalty: 1,
                badge: false,
                managementTeam: .challenger
            ),
        ]
    }
}
