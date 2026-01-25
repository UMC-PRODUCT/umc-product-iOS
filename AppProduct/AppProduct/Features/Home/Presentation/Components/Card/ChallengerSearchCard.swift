//
//  ChallengerSearchCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/24/26.
//

import SwiftUI

/// 챌린저 검색 List Card
struct ChallengerSearchCard: View, Equatable {
    
    // MARK: - Property
    /// 표시할 참여자 정보
    let participant: Participant
    let showCheck: Bool
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.participant == rhs.participant
    }
    
    // MARK: - Constant
    /// UI 상수
    private enum Constants {
        /// 프로필 이미지 크기
        static let imageSize: CGFloat = 30
        static let checkImage: String = "checkmark.circle"
    }
    
    // MARK: - Init
    /// 초기화 메서드
    /// - Parameter participant: 뷰에 표시할 참여자 객체
    /// - Parameter showCheck: check 표시
    init(participant: Participant, showCheck: Bool = false) {
        self.participant = participant
        self.showCheck = showCheck
    }
    
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8, content: {
            profileImage
            challengeCard
            Spacer()
            
            if showCheck {
                Image(systemName: Constants.checkImage)
            }
        })
    }
    
    // MARK: - UI Components
    /// 프로필 이미지
    private var profileImage: some View {
        RemoteImage(urlString: participant.profileImage ?? "person.fill", size: .init(width: Constants.imageSize, height: Constants.imageSize))
    }
    
    /// 챌린저 정보
    private var challengeCard: some View {
        Text("\(participant.gen)th_\(participant.name)/\(participant.nickname)_\(participant.schoolName)")
            .appFont(.calloutEmphasis, color: .black)
    }
}

#Preview {
    ChallengerSearchCard(participant: .init(challengeId: 11, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)))
}
