//
//  MemberReportDraft.swift
//  CoreDomain
//
//  Created by euijjang97 on 10/29/26.
//

import Foundation

/// 사용자 신고 사유. 서버 메시지 신고 enum과 다른 제품 개념이다.
public enum MemberReportReason: String, CaseIterable, Identifiable, Sendable {
    case harassment, impersonation, spam, other
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .harassment: "괴롭힘·지속적인 불쾌한 행위"
        case .impersonation: "사칭·허위 프로필"
        case .spam: "스팸·광고 활동"
        case .other: "기타"
        }
    }
}

public struct MemberReportDraft: Equatable, Sendable {
    public var reasons: Set<MemberReportReason>
    public var detail: String

    public init(reasons: Set<MemberReportReason> = [], detail: String = "") {
        self.reasons = reasons
        self.detail = detail
    }

    public var isValid: Bool {
        !reasons.isEmpty && !detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
