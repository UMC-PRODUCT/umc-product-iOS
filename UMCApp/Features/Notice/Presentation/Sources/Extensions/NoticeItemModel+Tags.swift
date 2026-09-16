//
//  NoticeItemModel+Tags.swift
//  NoticePresentation
//
//  Created by 이예지 on 5/8/26.
//

import SwiftUI
import UMCFoundation
import NoticeDomain
import CoreDesignSystem
import CoreUIComponents

extension NoticeItemModel {
    /// 공지 목록 셀에 표시할 태그 목록
    ///
    /// 순서: 기수 → 출처(scope) → 파트
    public var tags: [NoticeItemTag] {
        var items: [NoticeItemTag] = [generationTag].compactMap { $0 }
        
        if let scopeTag {
            items.append(scopeTag)
        }
        
        items.append(contentsOf: partTags)
        
        return items
    }
    
    /// 기수 태그 — 기수를 특정하지 못하면 태그 자체를 생략한다
    ///
    /// 기수 값을 알 수 없는 상태(역매핑 실패 등)에서 `"\(generation)기"` 를 그대로 쓰면
    /// 「기」만 남거나 gisuId 가 기수로 새어 나간다(#1356).
    var generationTag: NoticeItemTag? {
        if targetsAllGenerations {
            return NoticeItemTag(text: "모든 기수", backColor: .blue)
        }
        guard let generationNumber = Int(generation), generationNumber > 0 else {
            return nil
        }
        return NoticeItemTag(text: "\(generation)기", backColor: .blue)
    }
    
    /// 중앙 공지는 출처 태그 없음 — scope 태그는 지부/교내만 표시
    var scopeTag: NoticeItemTag? {
        switch scope {
        case .central:
            return nil
        case .branch:
            let displayName = scopeDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return NoticeItemTag(
                text: displayName.isEmpty ? "지부" : displayName,
                backColor: .orange500
            )
        case .campus:
            return NoticeItemTag(text: "교내", backColor: .green500)
        }
    }
    
    /// parts 배열 우선, 비어 있으면 category에서 파트 추출
    ///
    /// 파트별 공지(category: .part)는 parts 없이 category만 내려오는 경우가 있음
    var resolvedParts: [UMCPartType] {
        if !parts.isEmpty {
            return parts
        }
        
        if case .part(let part) = category {
            return [part]
        }
        
        return []
    }
    
    /// 파트가 4개 이상이면 "여러 파트" 단일 태그로 축약, 3개 이하는 개별 표시
    var partTags: [NoticeItemTag] {
        guard !resolvedParts.isEmpty else { return [] }
        
        if resolvedParts.count >= 4 {
            return [
                NoticeItemTag(
                    text: "여러 파트",
                    backColor: .grey500
                )
            ]
        }
        
        return resolvedParts.prefix(3).map { part in
            NoticeItemTag(
                text: NoticePart(umcPartType: part)?.displayName ?? "파트",
                backColor: part.color
            )
        }
    }
}
