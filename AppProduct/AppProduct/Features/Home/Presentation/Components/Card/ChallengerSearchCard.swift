//
//  ChallengerSearchCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/24/26.
//

import SwiftUI

/// 챌린저 검색 List Card
struct ChallengerSearchCard: View, Equatable {
    
    // MARK: - Properties
    
    /// 표시할 참여자 정보
    let participant: Participant
    
    /// 선택 상태를 나타내는 체크 박스(아이콘) 표시 여부
    let showCheck: Bool
    
    /// 현재 카드가 선택된 상태인지 여부
    let isSelected: Bool
    
    // MARK: - Equatable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.participant.id == rhs.participant.id &&
        lhs.showCheck == rhs.showCheck &&
        lhs.isSelected == rhs.isSelected
    }  
    
    // MARK: - Constants
    
    /// UI 상수
    private enum Constants {
        /// 프로필 이미지 크기
        static let imageSize: CGFloat = 30
        /// 선택됨 상태 아이콘 이미지 이름
        static let checkImage: String = "checkmark.circle"
        /// 선택되지 않음 상태 아이콘 이미지 이름
        static let uncheckImage: String = "circle"
    }
    
    // MARK: - Init
    
    /// ChallengerSearchCard를 초기화합니다.
    ///
    /// 주어진 참여자 정보와 체크박스 표시 여부를 기반으로 카드를 구성합니다.
    ///
    /// - Parameters:
    ///   - participant: 카드에 표시될 참여자(Participant) 정보
    ///   - showCheck: 선택 상태를 나타내는 체크 아이콘 표시 여부 (기본값: false)
    ///   - isSelected: 챌린저가 선택되었는지 여부 (기본값: false)
    init(participant: Participant, showCheck: Bool = false, isSelected: Bool = false) {
        self.participant = participant
        self.showCheck = showCheck
        self.isSelected = isSelected
    }
    
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing8, content: {
            profileImage
            challengeCard
            Spacer()
            
            if showCheck {
                Image(systemName: isSelected ? Constants.checkImage : Constants.uncheckImage)
                    .foregroundStyle(isSelected ? .green : .grey500)
                    .font(.title3)
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
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            Text("\(participant.name)/\(participant.nickname)(\(participant.gen)th)")
                .appFont(.calloutEmphasis, color: .black)
            
            Text("\(participant.schoolName)")
                .appFont(.subheadline, color: .grey600)
        }
    }
}

#Preview {
    ChallengerSearchCard(participant: .init(challengeId: 11, gen: 11, name: "정의찬", nickname: "제옹", schoolName: "중앙대학교", profileImage: nil, part: .front(type: .ios)))
}
