//
//  PenaltyCard.swift
//  AppProduct
//
//  Created by euijjang97 on 1/14/26.
//

import SwiftUI

/// 홈 화면 패널티 카드
///
/// 사용자의 기수별 패널티 정보와 상세 기록을 카드 형태로 표시합니다.
struct PenaltyCard: View, Equatable {
    
    // MARK: - Properties
    
    /// 기수별 패널티 데이터 리스트
    let generations: [GenerationData]
    
    /// 현재 표시 중인 탭(기수) 인덱스
    @State private var currentIndex: Int = 0
    
    // MARK: - Constants
    
    enum Constants {
        /// 카드 전체 패딩
        static let padding: CGFloat = 20
        /// 카드 높이 (데이터 없을 때, 있을 때)
        static let height: (CGFloat, CGFloat) = (100, 240)
    }
    
    // MARK: - Equtable
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.generations == rhs.generations
    }
    
    // MARK: - Init
    
    /// PenaltyCard 생성자
    /// - Parameter generations: 표시할 기수별 패널티 데이터
    init(generations: [GenerationData]) {
        self.generations = generations
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing24, content: {
            GenTabBar(
                generations: generations.map { $0.gen },
                currentIndex: $currentIndex
            )
            
            TabView(selection: $currentIndex) {
                ForEach(generations.indices, id: \.self) { index in
                    HStack(alignment: .top, spacing: DefaultSpacing.spacing16) {
                        
                        CardInfo(infoType: .penalties(generations[index].penaltyPoint))
                        
                        CardInfo(infoType: .infoText(generations[index].penaltyLogs))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tag(index)
                    .padding(.horizontal, DefaultSpacing.spacing4)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        })
        .frame(minHeight: generations.isEmpty ? Constants.height.0 : Constants.height.1)
        .padding(Constants.padding)
        .clipShape(.rect(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true))
        .glassEffect(.regular, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
    }
}

/// 기수 선택 탭 바
fileprivate struct GenTabBar: View {
    // MARK: - Properties
    
    /// 표시할 기수 목록
    let generations: [Int]
    /// 현재 선택된 인덱스 바인딩
    @Binding var currentIndex: Int
    
    private enum Constants {
        /// 탭 텍스트 패딩
        static let textPadding: EdgeInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        /// 인디케이터 간격
        static let indicatorSpacing: CGFloat = 4
        /// 인디케이터 지름
        static let indicatorDiameter: CGFloat = 8
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing16) {
            Text("\(generations[currentIndex])th 활동 상태")
                .appFont(.footnoteEmphasis, color: .indigo600)
                .padding(Constants.textPadding)
                .background(.indigo100, in: .capsule)
            
            Spacer()
            
            HStack(spacing: Constants.indicatorSpacing) {
                ForEach(generations.indices, id: \.self) { index in
                    Circle()
                        .fill(currentIndex == index ? Color.indigo500 : Color.indigo200)
                        .frame(width: Constants.indicatorDiameter, height: Constants.indicatorDiameter)
                        .onTapGesture {
                            withAnimation {
                                currentIndex = index
                            }
                        }
                }
            }
        }
    }
}

// MARK: - CardInfo
/// 카드 경고 포인트 및 설명
fileprivate struct CardInfo: View {
    
    // MARK:  - Properties
    /// 표시할 정보 타입 (점수 또는 상세 기록)
    var infoType: InfoType
    
    // MARK: - Constants
    
    private enum Constants {
        static let desCardPadding: CGFloat = 4
        /// 프로그레스 바 높이
        static let progressHeight: CGFloat = 20
    }
    
    // MARK: - Init
    init(infoType: InfoType) {
        self.infoType = infoType
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16, content: {
            title
            content
        })
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    // MARK: - Top
    /// 카드 타이틀
    private var title: some View {
        Text(infoType.text)
            .font(.subheadline)
            .foregroundStyle(.grey600)
            .fontWeight(.semibold)
    }
    
    /// 카드 컨텐츠
    @ViewBuilder
    private var content: some View {
        if let point = infoType.point {
            pointContent(point: point)
        } else if let items = infoType.infoItems {
            descripContent(items: items)
        }
    }
    
    // MARK: - Point
    /// 포인트 컨텐츠
    /// - Parameter point: 포인트 점수
    /// - Returns: 포인트 뷰 반환
    private func pointContent(point: Int) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            pointTitle(point: point)
            progressBar(point: point)
        })
    }
    
    private func pointTitle(point: Int) -> some View {
        HStack(alignment: .lastTextBaseline, spacing: DefaultSpacing.spacing12, content: {
            Text("\(point)")
                .appFont(.title1Emphasis, color: .grey900)
            
            Group {
                Text("/")
                Text("3")
            }
            .appFont(.title2Emphasis, color: .grey400)
        })
    }
    
    // MARK: - Descrip
    /// 패널티 사유 카드 리스트
    /// - Parameter items: 패널티 사유
    /// - Returns: 패널티 사유 뷰
    @ViewBuilder
    private func descripContent(items: [PenaltyInfoItem]) -> some View {
        if items.isEmpty {
            ContentUnavailableView(
                "등록된 패널티가 없습니다.",
                systemImage: "exclamationmark.circle",
                description: Text("현재 부과된 패널티 사유가 없습니다.")
            )
        } else {
            VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
                ForEach(items.indices, id: \.self) { index in
                    descripCard(item: items[index])
                }
            }
        }
    }
    
    /// 패널티 사유 뷰 카드
    /// - Parameter item: 패널티 사유 데이터
    /// - Returns: 패널티 사유 뷰
    private func descripCard(item: PenaltyInfoItem) -> some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4, content: {
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(item.reason)
                    .appFont(.calloutEmphasis, color: .grey900)
                Spacer()
                Text("\(item.penaltyPoint)점")
                    .appFont(.calloutEmphasis, color: .red)
            }
            
            Text(item.date)
                .appFont(.footnote, color: .grey500)
        })
    }
    
    // MARK: - Method
    private func progressBar(point: Int) -> some View {
        Gauge(value: Double(point), in: 0...3) {
            EmptyView()
        }
        .gaugeStyle(.linearCapacity)
        .tint(progressGradient(point))
        .frame(height: Constants.progressHeight)
    }
    
    /// 프로그레스 바 그라데이션 색상 결정
    private func progressGradient(_ point: Int) -> LinearGradient {
        switch point {
        case 0...1:
            return LinearGradient(
                colors: [.green300, .green500, .green700],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 2:
            return LinearGradient(
                colors: [.orange400, .orange500, .orange600],
                startPoint: .leading,
                endPoint: .trailing
            )
        case 3:
            return LinearGradient(
                colors: [.red300, .red500, .red700],
                startPoint: .leading,
                endPoint: .trailing
            )
        default:
            return LinearGradient(
                colors: [.grey400, .grey500, .grey600],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
    
    /// 프로그레스 바 배경 색상 결정
    private func progressBackgroundColor(_ point: Int) -> Color {
        switch point {
        case 0...1:
            return .green100
        case 2:
            return .orange100
        case 3:
            return .red100
        default:
            return .grey100
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    PenaltyCard(generations: [
        GenerationData(
            gen: 11,
            penaltyPoint: 3,
            penaltyLogs: [
                .init(reason: "지각", date: "03.26", penaltyPoint: 1),
                .init(reason: "과제 미제출", date: "03.27", penaltyPoint: 1),
                .init(reason: "과제 미제출", date: "03.27", penaltyPoint: 2)
            ]
        ),
        GenerationData(
            gen: 12,
            penaltyPoint: 1,
            penaltyLogs: [
                .init(reason: "지각", date: "03.14", penaltyPoint: 1),
            ]
        ),
        GenerationData(
            gen: 13,
            penaltyPoint: 0,
            penaltyLogs: []
        )
    ])
}
