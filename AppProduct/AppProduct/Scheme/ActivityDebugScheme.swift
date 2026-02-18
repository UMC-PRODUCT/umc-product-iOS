//
//  ActivityDebugScheme.swift
//  AppProduct
//
//  Created by Codex on 2/18/26.
//

import Foundation

#if DEBUG
enum ActivityDebugState: String {
    case loading
    case loaded
    case failed

    static func fromLaunchArgument() -> ActivityDebugState? {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-activityDebugState"),
           arguments.indices.contains(index + 1) {
            return ActivityDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["ACTIVITY_DEBUG_STATE"] {
            return ActivityDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: ActivityViewModel) {
        viewModel.seedForDebugState(
            sessionsState: sessionsLoadable,
            userId: debugUserId
        )
    }

    private var sessionsLoadable: Loadable<[Session]> {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded(Self.debugSessions)
        case .failed:
            return .failed(.unknown(message: "활동 데이터를 불러오지 못했습니다."))
        }
    }

    private var debugUserId: UserID {
        UserID(value: "123")
    }

    private static var debugSessions: [Session] {
        let calendar = Calendar.current
        let now = Date()

        let firstStart = calendar.date(
            bySettingHour: 19, minute: 0, second: 0, of: now
        ) ?? now
        let secondStart = calendar.date(
            byAdding: .day, value: 1, to: firstStart
        ) ?? firstStart

        return [
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1001"),
                    icon: .Activity.profile,
                    title: "iOS 파트 정규 세션",
                    week: 6,
                    startTime: firstStart,
                    endTime: firstStart.addingTimeInterval(7_200),
                    location: Coordinate(
                        latitude: 37.582967,
                        longitude: 127.010527
                    )
                ),
                initialAttendance: nil
            ),
            Session(
                info: SessionInfo(
                    sessionId: SessionID(value: "1002"),
                    icon: .Activity.profile,
                    title: "공통 해커톤 OT",
                    week: 7,
                    startTime: secondStart,
                    endTime: secondStart.addingTimeInterval(5_400),
                    location: Coordinate(
                        latitude: 37.585000,
                        longitude: 127.020000
                    )
                ),
                initialAttendance: nil
            )
        ]
    }
}
#endif
