// Created by euijjang97 on 11/1/26.
import Foundation
import CoreDomain
import UMCFoundation

extension MemberAdministrationAuthority {
    /// 서버의 조직 종류·기수 범위를 보존하여 중앙 운영 권한을 판정합니다.
    public func canSearchAllSchools(gisuId: String) -> Bool {
        isSuperAdmin || roles.contains {
            $0.gisuId == gisuId && $0.organizationType == .central
                && [.centralPresident, .centralVicePresident,
                    .centralOperatingTeamMember, .centralEducationTeamMember].contains($0.roleType)
        }
    }

    public func canManagePoints(gisuId: String, schoolId: String) -> Bool {
        canSearchAllSchools(gisuId: gisuId) || roles.contains {
            $0.gisuId == gisuId && $0.organizationType == .school
                && $0.organizationId == schoolId && !schoolId.isEmpty
                && [.schoolPresident, .schoolVicePresident].contains($0.roleType)
        }
    }

    public func canDeletePoints(gisuId: String) -> Bool {
        isSuperAdmin || roles.contains {
            $0.gisuId == gisuId && $0.organizationType == .central
                && $0.roleType == .centralPresident
        }
    }

    /// 학교 운영진은 자기 학교, 지부장은 자기 지부 안에서만 검색합니다.
    public func scopedFilter(_ filter: MemberSearchFilter) throws -> MemberSearchFilter {
        guard !filter.gisuId.isEmpty else { throw DomainError.custom(message: "기수를 선택해 주세요.") }
        if canSearchAllSchools(gisuId: filter.gisuId) { return filter }
        let matching = roles.filter { $0.gisuId == filter.gisuId }
        let chapterIds = matching.filter {
            $0.organizationType == .chapter && $0.roleType == .chapterPresident
        }.compactMap(\.organizationId).filter { !$0.isEmpty }
        let schoolIds = matching.filter {
            $0.organizationType == .school && $0.roleType.canAccessAdminMode
        }.compactMap(\.organizationId).filter { !$0.isEmpty }
        var scoped = filter
        if let chapter = chapterIds.first {
            scoped.chapterId = chapterIds.contains(filter.chapterId ?? "") ? filter.chapterId : chapter
        } else if let school = schoolIds.first {
            scoped.schoolId = schoolIds.contains(filter.schoolId ?? "") ? filter.schoolId : school
            scoped.chapterId = nil
        } else {
            throw DomainError.custom(message: "선택한 기수의 멤버를 조회할 권한이 없습니다.")
        }
        return scoped
    }
}

/// 부여·사유 편집에서 동일한 서버 입력 제한을 적용합니다.
public enum MemberPointValidation {
    public static func description(_ value: String) throws -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw DomainError.custom(message: "사유를 입력해 주세요.") }
        // 서버 @Size는 UTF-16 길이를 사용합니다(이모지도 같은 제한 적용).
        guard trimmed.utf16.count <= 200 else {
            throw DomainError.custom(message: "사유는 200자 이내로 입력해 주세요.")
        }
        return trimmed
    }

    public static func validate(type: ChallengerPointType, value: Int,
                                description: String) throws {
        _ = try self.description(description)
        guard type.isCustom ? value != 0 : value == (Int(exactly: type.defaultPointValue) ?? 0) else {
            throw DomainError.custom(message: "기타 배점은 0점일 수 없으며, 유형별 배점은 변경할 수 없습니다.")
        }
        guard Int32(exactly: value) != nil else {
            throw DomainError.custom(message: "배점은 -2147483648부터 2147483647 사이로 입력해 주세요.")
        }
    }

    public static func availableTypes(generation: String) -> [ChallengerPointType] {
        ChallengerPointType.allCases.filter {
            $0 != .warning && $0 != .out
                && ($0 != .bestWorkbook || (Int(generation) ?? 10) < 10)
        }
    }
}

/// Presentation이 Data 구현에 의존하지 않도록 운영 API를 제공하는 UseCase입니다.
public protocol MemberAdministrationUseCaseProtocol: MemberAdministrationRepositoryProtocol {}

public final class MemberAdministrationUseCase: MemberAdministrationUseCaseProtocol {
    private let repository: MemberAdministrationRepositoryProtocol
    public init(repository: MemberAdministrationRepositoryProtocol) { self.repository = repository }
    public func search(filter: MemberSearchFilter, page: Int) async throws -> AdminMemberPage {
        try await repository.search(filter: filter, page: page)
    }
    public func fetchGenerations() async throws -> [MemberFilterOption] {
        try await repository.fetchGenerations()
    }
    public func fetchOrganizations(gisuId: String) async throws -> MemberOrganizationOptions {
        try await repository.fetchOrganizations(gisuId: gisuId)
    }
    public func fetchAuthority() async throws -> MemberAdministrationAuthority {
        try await repository.fetchAuthority()
    }
    public func updatePointDescription(pointId: String, description: String) async throws {
        try await repository.updatePointDescription(
            pointId: pointId, description: MemberPointValidation.description(description)
        )
    }
}
