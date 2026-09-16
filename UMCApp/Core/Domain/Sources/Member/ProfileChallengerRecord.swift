//
//  ProfileChallengerRecord.swift
//  CoreDomain
//
//  Created by euijjang97 on 7/11/26.
//

import UMCFoundation

/// 멤버가 활동한 기수별 챌린저 기록 한 건 (MyPage `MyPageChallengerRecordDTO`의 도메인 대응).
public struct ProfileChallengerRecord: Equatable, Hashable, Sendable {

    // MARK: - Property

    public let challengerId: String
    public let memberId: String?
    public let gisu: String
    public let gisuId: String
    public let chapterId: String?
    public let chapterName: String?
    public let part: String
    /// 인프라 겸직 여부. 서버가 신규 두 파트에서만 `true` 로 내려준다 (#1351).
    public let infra: Bool
    public let schoolId: String
    public let schoolName: String
    public let name: String?
    public let nickname: String?
    public let email: String?
    public let profileImageLink: String?
    public let status: MemberStatus
    public let challengerPoints: [ProfileChallengerPoint]

    // MARK: - Init

    public init(
        challengerId: String,
        memberId: String?,
        gisu: String,
        gisuId: String,
        chapterId: String?,
        chapterName: String?,
        part: String,
        infra: Bool = false,
        schoolId: String,
        schoolName: String,
        name: String?,
        nickname: String?,
        email: String?,
        profileImageLink: String?,
        status: MemberStatus,
        challengerPoints: [ProfileChallengerPoint]
    ) {
        self.challengerId = challengerId
        self.memberId = memberId
        self.gisu = gisu
        self.gisuId = gisuId
        self.chapterId = chapterId
        self.chapterName = chapterName
        self.part = part
        self.infra = infra
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.name = name
        self.nickname = nickname
        self.email = email
        self.profileImageLink = profileImageLink
        self.status = status
        self.challengerPoints = challengerPoints
    }
}
