// Created by euijjang97 on 11/1/26.
import Foundation
import UMCFoundation

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminSearchResultDTO: Codable {
    let page: AdminSearchPageDTO

    private enum CodingKeys: String, CodingKey {
        case page
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decode(AdminSearchPageDTO.self, forKey: .page)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(page, forKey: .page)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminSearchPageDTO: Codable {
    let content: [AdminSearchItemDTO]
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case content, hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode([AdminSearchItemDTO].self, forKey: .content)
        hasNext = try container.decodeBoolFlexibleIfPresent(forKey: .hasNext) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(hasNext, forKey: .hasNext)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminSearchItemDTO: Codable {
    let challengerId: String
    let memberId: String
    let gisuId: String
    let generation: String
    let schoolId: String
    let name: String
    let nickname: String
    let schoolName: String
    let part: String
    let profileImageLink: String?
    let roleTypes: [String]

    private enum CodingKeys: String, CodingKey {
        case challengerId, memberId, gisuId, generation, schoolId, name, nickname, schoolName, part, profileImageLink, roleTypes
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeFlexibleStringIfPresent(forKey: .challengerId) ?? ""
        memberId = try container.decodeFlexibleStringIfPresent(forKey: .memberId) ?? ""
        gisuId = try container.decodeFlexibleStringIfPresent(forKey: .gisuId) ?? ""
        generation = try container.decodeFlexibleStringIfPresent(forKey: .generation) ?? ""
        schoolId = try container.decodeFlexibleStringIfPresent(forKey: .schoolId) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname) ?? ""
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        part = try container.decodeIfPresent(String.self, forKey: .part) ?? ""
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        roleTypes = try container.decodeIfPresent([String].self, forKey: .roleTypes) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(challengerId, forKey: .challengerId)
        try container.encode(memberId, forKey: .memberId)
        try container.encode(gisuId, forKey: .gisuId)
        try container.encode(generation, forKey: .generation)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(name, forKey: .name)
        try container.encode(nickname, forKey: .nickname)
        try container.encode(schoolName, forKey: .schoolName)
        try container.encode(part, forKey: .part)
        try container.encodeIfPresent(profileImageLink, forKey: .profileImageLink)
        try container.encode(roleTypes, forKey: .roleTypes)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminGenerationListDTO: Codable {
    let content: [AdminGenerationDTO]
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case content, hasNext
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        content = try container.decode([AdminGenerationDTO].self, forKey: .content)
        hasNext = try container.decode(Bool.self, forKey: .hasNext)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(content, forKey: .content)
        try container.encode(hasNext, forKey: .hasNext)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminGenerationDTO: Codable {
    let gisuId: String
    let generation: String
    let isActive: Bool

    private enum CodingKeys: String, CodingKey {
        case gisuId, generation, isActive
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try container.decodeFlexibleStringIfPresent(forKey: .gisuId) ?? ""
        generation = try container.decodeFlexibleStringIfPresent(forKey: .generation) ?? ""
        isActive = try container.decodeBoolFlexibleIfPresent(forKey: .isActive) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gisuId, forKey: .gisuId)
        try container.encode(generation, forKey: .generation)
        try container.encode(isActive, forKey: .isActive)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminOrganizationListDTO: Codable {
    let gisus: [AdminOrganizationDTO]

    private enum CodingKeys: String, CodingKey {
        case gisus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gisus = try container.decode([AdminOrganizationDTO].self, forKey: .gisus)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gisus, forKey: .gisus)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminOrganizationDTO: Codable {
    let gisuId: String
    let chapters: [AdminChapterDTO]
    let schools: [AdminSchoolDTO]

    private enum CodingKeys: String, CodingKey {
        case gisuId, chapters, schools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try container.decodeFlexibleStringIfPresent(forKey: .gisuId) ?? ""
        chapters = try container.decodeIfPresent([AdminChapterDTO].self, forKey: .chapters) ?? []
        schools = try container.decodeIfPresent([AdminSchoolDTO].self, forKey: .schools) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gisuId, forKey: .gisuId)
        try container.encode(chapters, forKey: .chapters)
        try container.encode(schools, forKey: .schools)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminChapterDTO: Codable {
    let chapterId: String
    let chapterName: String
    let schools: [AdminSchoolDTO]

    private enum CodingKeys: String, CodingKey {
        case chapterId, chapterName, schools
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try container.decodeFlexibleStringIfPresent(forKey: .chapterId) ?? ""
        chapterName = try container.decodeIfPresent(String.self, forKey: .chapterName) ?? ""
        schools = try container.decodeIfPresent([AdminSchoolDTO].self, forKey: .schools) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(chapterId, forKey: .chapterId)
        try container.encode(chapterName, forKey: .chapterName)
        try container.encode(schools, forKey: .schools)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminSchoolDTO: Codable {
    let schoolId: String
    let schoolName: String
    let chapterId: String

    private enum CodingKeys: String, CodingKey {
        case schoolId, schoolName, chapterId
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try container.decodeFlexibleStringIfPresent(forKey: .schoolId) ?? ""
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName) ?? ""
        chapterId = try container.decodeFlexibleStringIfPresent(forKey: .chapterId) ?? ""
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(schoolName, forKey: .schoolName)
        try container.encode(chapterId, forKey: .chapterId)
    }
}

/// 운영진 API에서 사용하는 부분 응답입니다. 식별자는 문자열로 보존합니다.
struct AdminSystemAuthorityDTO: Codable {
    let isSuperAdmin: Bool

    private enum CodingKeys: String, CodingKey {
        case isSuperAdmin
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isSuperAdmin = try container.decodeBoolFlexibleIfPresent(forKey: .isSuperAdmin) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isSuperAdmin, forKey: .isSuperAdmin)
    }
}
