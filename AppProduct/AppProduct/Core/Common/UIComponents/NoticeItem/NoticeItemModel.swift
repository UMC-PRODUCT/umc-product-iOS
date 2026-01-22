//
//  NoticeItemModel.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

struct NoticeItemModel: Equatable, Identifiable {
    let id = UUID()
    let tag: NoticeItemTag
    let mustRead: Bool
    let isAlert: Bool
    let date: Date
    let title: String
    let content: String
    let writer: String
    let hasLink: Bool
    let hasVote: Bool
    let viewCount: Int
}

extension NoticeItemModel {
    static let mockItems: [NoticeItemModel] = [
        NoticeItemModel(tag: .campus, mustRead: true, isAlert: true, date: Date(), title: "2026 UMC 신년회 안내", content: "안녕하세요! 가천대학교 UMC 챌린저 여러분! 회장 웰시입니다!", writer: "웰시/최지은", hasLink: false, hasVote: false, viewCount: 32),
        NoticeItemModel(tag: .central, mustRead: true, isAlert: true, date: Date(), title: "UMC 9기 ✨Demo Day✨ 안내", content: "안녕하세요, UMC 9기 챌린저 여러분! 총괄 챗챗입니다~", writer: "챗챗/전채운", hasLink: false, hasVote: false, viewCount: 123),
        NoticeItemModel(tag: .part(.ios), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        NoticeItemModel(tag: .part(.android), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        NoticeItemModel(tag: .part(.nodejs), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5),
        NoticeItemModel(tag: .part(.springboot), mustRead: false, isAlert: false, date: Date(), title: "iOS 9주차 워크북 배포 안내", content: "안녕하세요! 가천대학교 UMC iOS 챌린저 여러분! 파트장 소피입니다☺️", writer: "소피/이예지", hasLink: false, hasVote: false, viewCount: 5)
    ]
}
