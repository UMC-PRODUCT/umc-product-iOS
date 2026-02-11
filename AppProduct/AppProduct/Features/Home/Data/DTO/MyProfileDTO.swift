//
//  MyProfileDTO.swift
//  AppProduct
//
//  Created by euijjang97 on 2/11/26.
//

import Foundation

struct MyProfileDTO: Codable {
    let id: Int
    let name: String
    let nickname: String
    let email: String
    let schoolId: Int
    let schoolName: String
    let profileImageLink: String
    let status: MemberStatus
    let roles: [RoleDTO]
}

// MARK: - RoleDTO

struct RoleDTO: Codable {
    let id: Int
    let challengerId: Int
    let roleType: ManagementTeam
    let organizationType: OrganizationType
    let organizationId: Int
    let responsiblePart: String?
    let gisuId: Int
}

// MARK: - MemberStatus

enum MemberStatus: String, Codable {
    case active = "ACTIVE"
    case inactive = "INACTIVE"
    case withdrawn = "WITHDRAWN"
}

// MARK: - OrganizationType

enum OrganizationType: String, Codable {
    case central = "CENTRAL"
    case chapter = "CHAPTER"
    case school = "SCHOOL"
}
