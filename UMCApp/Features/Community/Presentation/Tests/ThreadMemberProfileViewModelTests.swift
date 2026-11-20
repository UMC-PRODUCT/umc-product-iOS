//
//  ThreadMemberProfileViewModelTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 11/19/26.
//

import Foundation
import Testing
import CoreDomain
import CommunityDomain
import UMCFoundation
@testable import CommunityPresentation

@MainActor
@Suite("ThreadMemberProfileViewModel — 스레드 프로필 시트 내용 (#1681)")
struct ThreadMemberProfileViewModelTests {

    @Test("프로필을 읽으면 loaded로 두고, 실패하면 failed로 두었다가 다시 시도로 읽는다")
    func loadAndRetry() async {
        let useCase = StubProfileUseCase()
        useCase.result = .failure(AppError.unknown(message: "boom"))
        let viewModel = ThreadMemberProfileViewModel(memberId: "42", useCase: useCase)

        await viewModel.load()
        #expect(viewModel.state.error != nil)

        useCase.result = .success(ThreadMemberProfile(profile: Self.profile()))
        await viewModel.load()

        #expect(viewModel.state.value?.name == "김챌린")
        #expect(useCase.requestedMemberIds == ["42", "42"])
    }

    @Test("최근 활동 기록의 이름·학교·기수·파트를 쓰고, 운영진 기록은 고르지 않는다")
    func mapsLatestRecord() {
        let profile = ThreadMemberProfile(profile: Self.profile(records: [
            Self.record(gisu: "10", part: "WEB", name: "옛이름", school: "옛학교"),
            Self.record(gisu: "11", part: "IOS", name: "김챌린", school: "새학교"),
            Self.record(gisu: "12", part: "ADMIN", name: "운영진", school: "운영학교")
        ]))

        #expect(profile.name == "김챌린")
        #expect(profile.schoolName == "새학교")
        #expect(profile.generation == "11")
        #expect(profile.part == .front(type: .ios))
    }

    @Test("활동 기록이 없으면 운영진 역할의 기수·담당 파트를 쓴다")
    func fallsBackToRole() {
        let profile = ThreadMemberProfile(profile: Profile(
            memberId: "42", name: "김운영", nickname: "", generations: [],
            schoolName: "한양대학교",
            roles: [ProfileRole(
                id: "1", challengerId: "1", gisu: "12", gisuId: "10",
                roleType: .schoolPresident, organizationType: .school,
                organizationId: "3", responsiblePart: "SPRINGBOOT"
            )]
        ))

        #expect(profile.generation == "12")
        #expect(profile.part == .server(type: .spring))
        #expect(profile.name == "김운영")
    }

    // MARK: - Fixture

    nonisolated private static func profile(
        records: [ProfileChallengerRecord] = [record(gisu: "11", part: "IOS", name: "김챌린")]
    ) -> Profile {
        Profile(
            memberId: "42", name: "김챌린", nickname: "챌린", generations: [],
            schoolName: "한양대학교", challengerRecords: records
        )
    }

    nonisolated private static func record(
        gisu: String, part: String, name: String, school: String = "한양대학교"
    ) -> ProfileChallengerRecord {
        ProfileChallengerRecord(
            challengerId: "c\(gisu)", memberId: "42", gisu: gisu, gisuId: gisu,
            chapterId: nil, chapterName: nil, part: part,
            schoolId: "1", schoolName: school,
            name: name, nickname: "챌린", email: nil, profileImageLink: nil,
            status: .active, challengerPoints: []
        )
    }
}

@MainActor
private final class StubProfileUseCase: ThreadMemberProfileUseCaseProtocol, @unchecked Sendable {
    var result: Result<ThreadMemberProfile, Error> = .failure(AppError.unknown(message: "unset"))
    private(set) var requestedMemberIds: [String] = []

    nonisolated func loadProfile(memberId: String) async throws -> ThreadMemberProfile {
        try await MainActor.run {
            requestedMemberIds.append(memberId)
            return try result.get()
        }
    }
}
