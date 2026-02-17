//
//  NoticeDebugScheme.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

#if DEBUG

/// 공지 디버그 스킴에서 사용할 역할 타입
///
/// Xcode 런치 인자(`-noticeDebugRole`) 또는 시드 플래그를 통해 역할을 지정합니다.
enum NoticeDebugRole: String {
    case central
    case branch
    case chapter
    case school
    case challenger

    /// 런치 인자에서 디버그 역할을 파싱합니다.
    ///
    /// `-noticeDebugRole` 키-값 인자를 우선 확인하고,
    /// 없으면 `--seed-appstorage-dummy-*` 플래그로 폴백합니다.
    static func fromLaunchArgument() -> NoticeDebugRole? {
        let arguments = ProcessInfo.processInfo.arguments

        if let index = arguments.firstIndex(of: "-noticeDebugRole"),
           arguments.indices.contains(index + 1) {
            return NoticeDebugRole(rawValue: arguments[index + 1])
        }

        // --seed-appstorage-dummy-* 플래그 기반 폴백 매핑
        if arguments.contains("--seed-appstorage-dummy-central") {
            return .central
        }
        if arguments.contains("--seed-appstorage-dummy-chapter") {
            return .branch
        }
        if arguments.contains("--seed-appstorage-dummy-school") {
            return .school
        }
        if arguments.contains("--seed-appstorage-dummy-challenger") {
            return .challenger
        }

        return nil
    }
}

/// 공지 화면의 디버그 상태를 정의합니다.
///
/// 런치 인자, 환경 변수를 통해 공지 목록의 초기 상태(loading/loaded/failed)를
/// 강제 지정하여 UI 미리보기 및 테스트에 활용합니다.
enum NoticeDebugState: String {

    // MARK: - Property

    case loading
    case loaded
    case loadedCentral
    case loadedBranch
    case loadedSchool
    case loadedPart
    case failed

    // MARK: - Function

    /// 런치 인자 및 환경 변수에서 디버그 상태를 파싱합니다.
    ///
    /// 우선순위: `--notice-*` 플래그 > `-noticeDebugState` 키-값 > `NOTICE_DEBUG_STATE` 환경 변수.
    /// `loaded` 상태일 경우 역할에 따라 세분화된 상태로 매핑합니다.
    static func fromLaunchArgument() -> NoticeDebugState? {
        let arguments = ProcessInfo.processInfo.arguments

        if arguments.contains("--notice-loading") {
            return .loading
        }
        if arguments.contains("--notice-loaded") {
            return loadedState(from: NoticeDebugRole.fromLaunchArgument())
        }
        if arguments.contains("--notice-failed") {
            return .failed
        }

        // -noticeDebugState 키-값 인자 확인
        if let index = arguments.firstIndex(of: "-noticeDebugState"),
           arguments.indices.contains(index + 1) {
            if arguments[index + 1] == NoticeDebugState.loaded.rawValue {
                return loadedState(from: NoticeDebugRole.fromLaunchArgument())
            }

            return NoticeDebugState(rawValue: arguments[index + 1])
        }

        // 환경 변수 폴백
        if let environmentValue = ProcessInfo.processInfo.environment["NOTICE_DEBUG_STATE"] {
            if environmentValue == NoticeDebugState.loaded.rawValue {
                return loadedState(from: NoticeDebugRole.fromLaunchArgument())
            }

            return NoticeDebugState(rawValue: environmentValue)
        }

        return nil
    }

    /// 디버그 상태를 ViewModel에 시드 데이터로 적용합니다.
    func apply(to viewModel: NoticeViewModel) {
        switch self {
        case .loading:
            viewModel.seedForDebugState(
                noticeItems: .loading,
                mainFilter: .all
            )
        case .loaded:
            viewModel.seedForDebugState(
                noticeItems: .loaded(Self.centralItems),
                mainFilter: .central
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

    // MARK: - Private Function

    /// 역할에 따라 적절한 loaded 세부 상태를 반환합니다.
    private static func loadedState(from role: NoticeDebugRole?) -> NoticeDebugState {
        switch role {
        case .branch, .chapter:
            return .loadedBranch
        case .school:
            return .loadedSchool
        case .challenger:
            return .loadedPart
        case .central, .none:
            return .loadedCentral
        }
    }

    private static var centralItems: [NoticeItemModel] {
        let now = Date()
        return (0..<20).map { index in
            let isMustRead = index % 4 == 0
            let category: NoticeCategory = (index % 5 == 0)
                ? .part(.front(type: .ios))
                : .general

            return NoticeItemModel(
                noticeId: String(1001 + index),
                generation: 9,
                scope: .central,
                category: category,
                mustRead: isMustRead,
                isAlert: true,
                date: Calendar.current.date(byAdding: .day, value: -index, to: now) ?? now,
                title: "중앙 공지 샘플 \(index + 1)",
                content: "중앙 운영 사무국 공지 샘플 본문 \(index + 1)입니다.",
                writer: "중앙 운영진",
                links: [],
                images: [],
                vote: nil,
                viewCount: 200 - index
            )
        }
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
