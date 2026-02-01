//
//  KakaoPlusManager.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import KakaoSDKTalk

/// 카카오톡 채널(플러스친구)과의 상호작용을 처리하는 매니저입니다.
///
/// UMC 동아리의 카카오톡 채널 채팅방을 여는 기능을 제공합니다.
///
/// - Important: 카카오톡 앱이 설치되어 있어야 합니다.
///
/// - Usage:
/// ```swift
/// let kakaoPlusManager = KakaoPlusManager()
/// kakaoPlusManager.openKakaoChannel()  // 카카오톡 채널 채팅방 열기
/// ```
class KakaoPlusManager {
    // MARK: - Property

    /// UMC 동아리 카카오톡 채널 ID
    ///
    /// - Note: 채널 관리자 페이지에서 확인 가능한 고유 ID입니다.
    let channelId = "_xjqxcln"

    // MARK: - Function

    /// UMC 카카오톡 채널 채팅방을 엽니다.
    ///
    /// 카카오톡 앱이 실행되며 UMC 채널과의 1:1 채팅방이 열립니다.
    /// 사용자 문의, 공지사항 확인 등에 활용됩니다.
    ///
    /// - Note:
    ///   - 카카오톡 미설치 시 자동으로 App Store로 이동합니다.
    ///   - 채널 추가 여부와 관계없이 채팅방이 열립니다.
    func openKakaoChannel() {
        TalkApi.shared.chatChannel(channelPublicId: channelId, completion: { error in
            if let error = error {
                print("채널 열기 에러: \(error)")
            } else {
                print("카카오톡 채널 채팅 열기 성공")
            }
        })
    }
}
