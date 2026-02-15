//
//  MyPageDebugScheme.swift
//  AppProduct
//
//  Created by euijjang97 on 2/16/26.
//

import Foundation

#if DEBUG
enum MyPageDebugState: String {
    case loading
    case loaded
    case failed

    static func fromLaunchArgument() -> MyPageDebugState? {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "-myPageDebugState"),
           arguments.indices.contains(index + 1) {
            return MyPageDebugState(rawValue: arguments[index + 1])
        }

        if let environmentValue = ProcessInfo.processInfo.environment["MYPAGE_DEBUG_STATE"] {
            return MyPageDebugState(rawValue: environmentValue)
        }

        return nil
    }

    func apply(to viewModel: MyPageViewModel) {
        viewModel.seedForDebugState(profileData: profileLoadable)
    }

    private var profileLoadable: Loadable<ProfileData> {
        switch self {
        case .loading:
            return .loading
        case .loaded:
            return .loaded(MyPageMockData.profile)
        case .failed:
            return .failed(.unknown(message: "마이페이지 데이터를 불러오지 못했습니다."))
        }
    }
}
#endif
