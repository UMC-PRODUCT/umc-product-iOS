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
    case superAdmin
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

        if let index = arguments.firstIndex(of: "-seed-member-role"),
           arguments.indices.contains(index + 1),
           let managementRole = ManagementTeam(rawValue: arguments[index + 1]) {
            switch managementRole {
            case .superAdmin:
                return .superAdmin
            case .centralPresident, .centralVicePresident, .centralOperatingTeamMember, .centralEducationTeamMember:
                return .central
            case .chapterPresident:
                return .chapter
            case .schoolPresident, .schoolVicePresident, .schoolPartLeader, .schoolEtcAdmin:
                return .school
            case .challenger:
                return .challenger
            }
        }

        if arguments.contains("--seed-appstorage-role-super-admin") {
            return .superAdmin
        }
        if arguments.contains("--seed-appstorage-role-central-president")
            || arguments.contains("--seed-appstorage-role-central-vice-president")
            || arguments.contains("--seed-appstorage-role-central-operating-team-member")
            || arguments.contains("--seed-appstorage-role-central-education-team-member") {
            return .central
        }
        if arguments.contains("--seed-appstorage-role-chapter-president") {
            return .chapter
        }
        if arguments.contains("--seed-appstorage-role-school-president")
            || arguments.contains("--seed-appstorage-role-school-vice-president")
            || arguments.contains("--seed-appstorage-role-school-part-leader")
            || arguments.contains("--seed-appstorage-role-school-etc-admin") {
            return .school
        }
        if arguments.contains("--seed-appstorage-role-challenger") {
            return .challenger
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
    case detailFailed
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
        if arguments.contains("--notice-detail-failed") {
            return .detailFailed
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
                noticeItems: .loaded(Self.loadedItemsForScheme),
                mainFilter: .central
            )
        case .loadedCentral:
            viewModel.seedForDebugState(
                noticeItems: .loaded(Self.loadedItemsForScheme),
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
        case .detailFailed:
            viewModel.seedForDebugState(
                noticeItems: .loaded(Self.loadedItemsForScheme),
                mainFilter: .central
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
        case .superAdmin, .central, .none:
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
                title: centralRealisticTitle(at: index),
                content: centralRealisticContent(at: index),
                writer: centralRealisticWriter(at: index),
                links: defaultLinks,
                images: defaultImages,
                vote: defaultVote,
                viewCount: 200 - index
            )
        }
    }

    /// `-noticeDebugState loaded` 전용 데이터
    ///
    /// 실제 앱 공지 피드와 유사한 구성으로 시드 데이터를 제공합니다.
    private static var loadedItemsForScheme: [NoticeItemModel] {
        let now = Date()
        let pinnedItems: [NoticeItemModel] = [
            NoticeItemModel(
                noticeId: "9001",
                generation: 9,
                scope: .central,
                category: .general,
                mustRead: true,
                isAlert: true,
                date: now,
                title: "9th UMC Hackathon 모집 신청 안내",
                content: "안녕하세요 9기 UMC 중앙운영사무국입니다! 챌린저 여러분께서 기다리시던 9th UMC Hackathon 신청을 시작합니다.",
                writer: "사과/김아오-9th UMC 총괄",
                links: defaultLinks,
                images: defaultImages,
                vote: activeVote,
                viewCount: 445
            ),
            NoticeItemModel(
                noticeId: "9002",
                generation: 9,
                scope: .central,
                category: .general,
                mustRead: true,
                isAlert: true,
                date: Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now,
                title: "📣 9th UMC 동아리 연합 컨퍼런스 신청 모집 안내",
                content: "안녕하세요, 9기 UMC 중앙운영사무국입니다! 2026년 9th UMCON이 다가오고 있습니다. 신청 링크를 확인해주세요.",
                writer: "사과/김아오-9th UMC 총괄",
                links: defaultLinks,
                images: [],
                vote: endedVote,
                viewCount: 421
            ),
            NoticeItemModel(
                noticeId: "9003",
                generation: 9,
                scope: .campus,
                category: .general,
                mustRead: false,
                isAlert: false,
                date: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now,
                title: "[투표] 9기 기말고사 뒤풀이 메뉴 선정 안내",
                content: "이번 해커톤 종료 후 진행될 회식 메뉴를 결정하고자 합니다. 가장 많은 표를 받은 메뉴로 진행됩니다!",
                writer: "애플/박사과-9th UMC대 회장",
                links: [],
                images: [],
                vote: noSelectionActiveVote,
                viewCount: 32
            )
        ]

        let additionalItems = (pinnedItems.count..<20).map { index in
            let isMustRead = index % 4 == 0
            let category: NoticeCategory = (index % 5 == 0)
                ? .part(.front(type: .ios))
                : .general

            return NoticeItemModel(
                noticeId: String(11001 + index),
                generation: 9,
                scope: index % 6 == 0 ? .campus : .central,
                category: category,
                mustRead: isMustRead,
                isAlert: true,
                date: Calendar.current.date(byAdding: .day, value: -index, to: now) ?? now,
                title: centralRealisticTitle(at: index),
                content: centralRealisticContent(at: index),
                writer: centralRealisticWriter(at: index),
                links: defaultLinks,
                images: defaultImages,
                vote: defaultVote,
                viewCount: 300 - index
            )
        }
        return pinnedItems + additionalItems
    }

    /// 공지 카드의 태그를 한 번에 확인할 수 있도록 전체 태그 케이스를 구성합니다.
    ///
    /// 포함 태그:
    /// - 일반 태그: 중앙, 지부, 학교
    /// - 파트 태그: PM, Design, SpringBoot, Node.js, Web, Android, iOS
    private static func allTagShowcaseItems(baseDate: Date) -> [NoticeItemModel] {
        let tagCases: [(scope: NoticeScope, category: NoticeCategory, label: String)] = [
            (.central, .general, "중앙"),
            (.branch, .general, "지부"),
            (.campus, .general, "학교"),
            (.central, .part(.pm), "PM"),
            (.central, .part(.design), "Design"),
            (.central, .part(.server(type: .spring)), "SpringBoot"),
            (.central, .part(.server(type: .node)), "Node.js"),
            (.central, .part(.front(type: .web)), "Web"),
            (.central, .part(.front(type: .android)), "Android"),
            (.central, .part(.front(type: .ios)), "iOS")
        ]

        return tagCases.enumerated().map { index, tagCase in
            NoticeItemModel(
                noticeId: String(9001 + index),
                generation: 9,
                scope: tagCase.scope,
                category: tagCase.category,
                mustRead: index % 2 == 0,
                isAlert: true,
                date: Calendar.current.date(byAdding: .hour, value: -index, to: baseDate) ?? baseDate,
                title: "\(tagCase.label) 운영 공지",
                content: "\(tagCase.label) 대상 공지 노출 검증용 내용입니다.",
                writer: "중앙 운영진",
                links: defaultLinks,
                images: defaultImages,
                vote: defaultVote,
                viewCount: 300 - index
            )
        }
    }

    /// 중앙 공지 리스트 디버그용 현실형 제목
    private static func centralRealisticTitle(at index: Int) -> String {
        let titles = [
            "9기 OT 자료 및 운영 안내",
            "파트별 첫 스터디 일정 공지",
            "출석 체크 정책 변경 안내",
            "프로젝트 팀빌딩 일정 확정",
            "중간 점검 제출 양식 공유",
            "데모데이 발표 순서 안내",
            "공식 채널 운영 가이드",
            "워크북 제출 마감 리마인드",
            "운영진 Q&A 세션 안내",
            "공지사항 작성 정책 업데이트",
            "스터디룸 사용 수칙 안내",
            "출결 이의 신청 기간 공지",
            "온보딩 미션 제출 안내",
            "팀 프로젝트 피드백 일정",
            "파트별 코드리뷰 주간 운영",
            "커뮤니티 가이드라인 재공지",
            "중앙 운영 공지 템플릿 배포",
            "발표 자료 업로드 경로 안내",
            "최종 회고 일정 및 방식 안내",
            "다음 기수 인수인계 공지"
        ]
        return titles[index % titles.count]
    }

    /// 중앙 공지 리스트 디버그용 현실형 본문
    private static func centralRealisticContent(at index: Int) -> String {
        let contents = [
            "이번 주 운영 공지 요약본을 반드시 확인해주세요.",
            "세부 일정, 장소, 제출 기준은 본문 링크를 참고해주세요.",
            "대상별 안내가 다를 수 있으니 수신 범위를 확인해주세요.",
            "기한 내 미제출 시 자동 누락 처리될 수 있습니다.",
            "운영 변경 사항은 즉시 반영되며 공지로만 안내됩니다."
        ]
        return contents[index % contents.count]
    }

    /// 중앙 공지 리스트 디버그용 작성자
    private static func centralRealisticWriter(at index: Int) -> String {
        let writers = ["중앙 운영진", "중앙 운영 사무국", "운영 PM", "교육 운영팀"]
        return writers[index % writers.count]
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
                links: defaultLinks,
                images: defaultImages,
                vote: defaultVote,
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
                links: defaultLinks,
                images: defaultImages,
                vote: defaultVote,
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
                links: defaultLinks,
                images: defaultImages,
                vote: defaultVote,
                viewCount: 27
            )
        ]
    }

    private static var defaultLinks: [String] {
        [
            "https://www.notion.so/umc-notice-debug",
            "https://github.com/UMC-community"
        ]
    }

    private static var defaultImages: [String] {
        [
            "https://picsum.photos/640/640",
            "https://picsum.photos/640/641",
            "https://picsum.photos/640/642"
        ]
    }

    private static var defaultVote: NoticeVote {
        NoticeVote(
            id: "notice-debug-vote",
            question: "디버그 샘플에서 가장 먼저 확인할 항목은?",
            options: [
                VoteOption(id: "1", title: "이미지", voteCount: 17),
                VoteOption(id: "2", title: "링크", voteCount: 11),
                VoteOption(id: "3", title: "열람 현황", voteCount: 13),
                VoteOption(id: "4", title: "권한 분기", voteCount: 9)
            ],
            startDate: Date(timeIntervalSinceNow: -86_400),
            endDate: Date(timeIntervalSinceNow: 86_400 * 5),
            allowMultipleChoices: true,
            isAnonymous: false,
            userVotedOptionIds: []
        )
    }

    /// 진행중 + 내가 참여한 상태를 확인하기 위한 투표
    private static var activeVote: NoticeVote {
        NoticeVote(
            id: "notice-debug-active-vote",
            question: "해커톤 OT에서 가장 기대되는 세션은?",
            options: [
                VoteOption(id: "1", title: "팀 빌딩", voteCount: 21),
                VoteOption(id: "2", title: "아이디어 피칭", voteCount: 14),
                VoteOption(id: "3", title: "멘토링", voteCount: 18),
                VoteOption(id: "4", title: "데모 피드백", voteCount: 9)
            ],
            startDate: Date(timeIntervalSinceNow: -86_400),
            endDate: Date(timeIntervalSinceNow: 86_400 * 4),
            allowMultipleChoices: true,
            isAnonymous: false,
            userVotedOptionIds: ["1", "3"]
        )
    }

    /// 종료 + 결과 확인 상태를 위한 투표
    private static var endedVote: NoticeVote {
        NoticeVote(
            id: "notice-debug-ended-vote",
            question: "컨퍼런스 선호 세션 투표 결과",
            options: [
                VoteOption(id: "1", title: "테크 토크", voteCount: 32),
                VoteOption(id: "2", title: "패널 토의", voteCount: 17),
                VoteOption(id: "3", title: "네트워킹", voteCount: 26)
            ],
            startDate: Date(timeIntervalSinceNow: -86_400 * 7),
            endDate: Date(timeIntervalSinceNow: -86_400),
            allowMultipleChoices: false,
            isAnonymous: true,
            userVotedOptionIds: ["1"]
        )
    }

    /// 진행중 + 아직 미참여 상태를 위한 투표
    private static var noSelectionActiveVote: NoticeVote {
        NoticeVote(
            id: "notice-debug-no-selection-vote",
            question: "뒤풀이 메뉴를 골라주세요",
            options: [
                VoteOption(id: "1", title: "치킨", voteCount: 12),
                VoteOption(id: "2", title: "피자", voteCount: 19),
                VoteOption(id: "3", title: "국밥", voteCount: 7),
                VoteOption(id: "4", title: "분식", voteCount: 11)
            ],
            startDate: Date(timeIntervalSinceNow: -3_600),
            endDate: Date(timeIntervalSinceNow: 86_400 * 2),
            allowMultipleChoices: false,
            isAnonymous: false,
            userVotedOptionIds: []
        )
    }
}
#endif
