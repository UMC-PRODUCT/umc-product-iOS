//
//  NoticeDebugScheme.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

#if DEBUG
enum NoticeDebugState: String {
    case loading
    case loadedCentral
    case loadedBranch
    case loadedSchool
    case loadedPart
    case failed

    static func fromLaunchArgument() -> NoticeDebugState? {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--notice-loading") {
            return .loading
        }
        if arguments.contains("--notice-loaded") {
            return .loadedCentral
        }
        if arguments.contains("--notice-failed") {
            return .failed
        }

        if let index = arguments.firstIndex(of: "-noticeDebugState"),
           arguments.indices.contains(index + 1) {
            return NoticeDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["NOTICE_DEBUG_STATE"] {
            return NoticeDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: NoticeViewModel) {
        switch self {
        case .loading:
            viewModel.seedForDebugState(
                noticeItems: .loading,
                mainFilter: .all
            )
        case .loadedCentral:
            viewModel.seedForDebugState(
                noticeItems: .loaded(Self.centralItems),
                mainFilter: .central
            )
        case .loadedBranch:
            viewModel.seedForDebugState(
                noticeItems: .loaded(Self.branchItems),
                mainFilter: .branch("Nova")
            )
        case .loadedSchool:
            viewModel.seedForDebugState(
                noticeItems: .loaded(Self.schoolItems),
                mainFilter: .school("가천대학교")
            )
        case .loadedPart:
                viewModel.seedForDebugState(
                    noticeItems: .loaded(Self.partItems),
                    mainFilter: .part(.ios)
                )
        case .failed:
            viewModel.seedForDebugState(
                noticeItems: .failed(.unknown(message: "공지 데이터를 불러오지 못했습니다.")),
                mainFilter: .all
            )
        }
    }

    private static var centralItems: [NoticeItemModel] {
        [
            NoticeItemModel(
                noticeId: "1001",
                generation: 9,
                scope: .central,
                category: .general,
                mustRead: true,
                isAlert: true,
                date: .now,
                title: "9기 전체 OT 안내",
                content: "9기 전체 OT를 진행합니다.",
                writer: "중앙 운영진",
                links: [],
                images: [],
                vote: nil,
                viewCount: 120
            )
        ]
    }

    private static var branchItems: [NoticeItemModel] {
        [
            NoticeItemModel(
                noticeId: "2001",
                generation: 9,
                scope: .branch,
                category: .general,
                mustRead: false,
                isAlert: true,
                date: .now,
                title: "Nova 지부 정기 세션 공지",
                content: "지부 세션 일정을 안내드립니다.",
                writer: "Nova 운영진",
                links: [],
                images: [],
                vote: nil,
                viewCount: 48
            )
        ]
    }

    private static var schoolItems: [NoticeItemModel] {
        [
            NoticeItemModel(
                noticeId: "3001",
                generation: 9,
                scope: .campus,
                category: .general,
                mustRead: false,
                isAlert: false,
                date: .now,
                title: "가천대학교 스터디 모집",
                content: "학교 단위 스터디 모집 안내입니다.",
                writer: "교내 운영진",
                links: [],
                images: [],
                vote: nil,
                viewCount: 32
            )
        ]
    }

    private static var partItems: [NoticeItemModel] {
        [
            NoticeItemModel(
                noticeId: "4001",
                generation: 9,
                scope: .central,
                category: .part(.front(type: .ios)),
                mustRead: false,
                isAlert: true,
                date: .now,
                title: "iOS 파트 과제 공지",
                content: "iOS 파트 대상 과제 제출 안내입니다.",
                writer: "iOS 파트장",
                links: [],
                images: [],
                vote: nil,
                viewCount: 27
            )
        ]
    }
}
#endif
