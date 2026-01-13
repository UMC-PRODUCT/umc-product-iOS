//
//  KakaoPlusManager.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import KakaoSDKTalk

class KakaoPlusManager {
    let channelId = "_xjqxcln"
    
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
