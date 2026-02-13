//
//  ScheduleListCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import SwiftUI
import Playgrounds

/// 일정 정보를 리스트 형태로 보여주는 카드 뷰
///
/// 일정 제목, 소제목, 그리고 자동 분류된 카테고리 아이콘을 표시합니다.
/// `ScheduleClassifierRepository`를 통해 일정 제목을 분석하여 적절한 카테고리를 설정합니다.
struct ScheduleListCard: View, Equatable {
    
    // MARK: - Properties
    
    /// 표시할 일정 데이터
    let data: ScheduleData
    
    /// 일정 카테고리 (자동 분류됨, 기본값: .general)
    @State var category: ScheduleIconCategory = .general
    
    /// 분류 로딩 상태
    @State var isLoading: Bool = true
    
    private enum Constants {
        /// 아이콘 패딩
        static let iconPadding: CGFloat = 8
        /// 카드 전체 패딩
        static let padding: EdgeInsets = .init(top: 20, leading: 16, bottom: 20, trailing: 16)
        /// 카드 모서리 반경
        static let cornerRadius: CGFloat = 24
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.data == rhs.data
    }
    
    // MARK: - Init
    
    /// ScheduleListCard 생성자
    /// - Parameter data: 표시할 일정 데이터
    init(data: ScheduleData) {
        self.data = data
    }
    
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing24, content: {
            CardIconImage(image: category.symbol, color: category.color, isLoading: $isLoading)
            infoContent
            Spacer()
            chevron
        })
        .padding(Constants.padding)
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(.white)
                .glass()
        }
        .task(id: data.id) {
            isLoading = true
            
            let repository = ScheduleClassifierRepositoryImpl()
            let useCase = ClassifyScheduleUseCaseImpl(repository: repository)
            category = await useCase.execute(title: data.title)
            
            isLoading = false
        }
    }
    
    /// 일정 내용 정보 (제목, 부제목)
    private var infoContent: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            // 일정 제목
            Text(data.title)
                .appFont(.calloutEmphasis, color: .grey900)
            // 참여 상태 + D-Day
            Text("\(data.status) · D-\(data.dDay)")
                .appFont(.subheadline, color: .grey600)
        })
    }
    
    private var chevron: some View {
        Image(systemName: DefaultConstant.chevronForwardImage)
            .renderingMode(.template)
            .foregroundStyle(.grey900)
            .padding(Constants.iconPadding)
    }
}

#Preview {
    VStack {
        ScheduleListCard(data: .init(
            scheduleId: 1, title: "컨퍼런스",
            startsAt: .now, endsAt: .now, status: "참여 예정", dDay: 7
        ))
        ScheduleListCard(data: .init(
            scheduleId: 2, title: "데모데이",
            startsAt: .now, endsAt: .now, status: "참여 예정", dDay: 14
        ))
    }
    .safeAreaPadding(.horizontal, 16)
}
