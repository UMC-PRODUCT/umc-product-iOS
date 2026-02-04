//
//  NoticeVoteCard.swift
//  AppProduct
//
//  Created by 이예지 on 2/3/26.
//

import SwiftUI

struct NoticeVoteCard: View {

    // MARK: - Property
    let vote: NoticeVote
    @State private var selectedOptionIds: Set<String> = []
    let onVote: ([String]) -> Void

    // MARK: - Constants
    fileprivate enum Constants {
        static let innerPadding: CGFloat = 25
        static let dividerHeight: CGFloat = 10
        static let progressHeight: CGFloat = 8
        static let capsulePadding: CGFloat = 8
        static let capsuleOpacity: Double = 0.3
        static let voteBtnVPadding: CGFloat = 8
    }

    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing16) {
            // 헤더
            headerSection

            // 투표 옵션
            optionsSection

            // 하단 정보
            footerSection
        }
        .padding(Constants.innerPadding)
        .background {
            ConcentricRectangle(corners: .concentric(minimum: DefaultConstant.concentricRadius), isUniform: true)
                .fill(Color(.systemGroupedBackground))
        }
    }

    // MARK: - HeaderSection
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
            HStack {
                Label("투표", systemImage: "chart.bar.fill")
                    .appFont(.calloutEmphasis)
                    .foregroundStyle(Color.black)

                Spacer()

                statusBadge
            }
            .padding(.bottom, DefaultSpacing.spacing4)

            Text(vote.question)
                .appFont(.bodyEmphasis)
                .foregroundStyle(Color.black)

            // 투표 성격 표시
            HStack(spacing: DefaultSpacing.spacing8) {
                Text(vote.allowMultipleChoices ? "복수선택" : "단일선택")
                    .appFont(.footnote, color: .grey600)
                
                Divider()
                    .frame(height: Constants.dividerHeight)
                
                Text(vote.isAnonymous ? "익명" : "실명")
                    .appFont(.footnote, color: .grey600)
                
                Spacer()
                
                Label(vote.formattedPeriod, systemImage: "calendar")
                    .appFont(.footnote, color: .grey600)
            }
        }
    }

    // MARK: - StatusBadge
    private var statusBadge: some View {
        Group {
            switch vote.status {
            case .active:
                Text("진행중")
                    .appFont(.footnoteEmphasis, color: .green)
                    .padding(Constants.capsulePadding)
                    .background(Color.green.opacity(Constants.capsuleOpacity))
                    .clipShape(Capsule())
                    .glassEffect(.clear)
            case .ended:
                Text("마감")
                    .appFont(.footnoteEmphasis, color: .red)
                    .padding(Constants.capsulePadding)
                    .background(Color.red.opacity(Constants.capsuleOpacity))
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - OptionsSection
    private var optionsSection: some View {
        VStack(spacing: DefaultSpacing.spacing12) {
            ForEach(vote.options) { option in
                if vote.hasUserVoted || vote.isEnded {
                    // 투표 결과 표시
                    VoteResultRow(
                        option: option,
                        totalVotes: vote.totalVotes,
                        isUserSelected: vote.userVotedOptionIds.contains(option.id)
                    )
                } else {
                    // 투표 선택 표시
                    Button(action: {
                        withAnimation(.default) {
                            toggleOption(option.id)
                        }
                    }) {
                        VoteOptionRow(
                            option: option,
                            isSelected: selectedOptionIds.contains(option.id),
                            allowMultiple: vote.allowMultipleChoices
                        )
                    }
                }
            }
        }
    }

    // MARK: - FooterSection
    private var footerSection: some View {
        VStack(spacing: DefaultSpacing.spacing8) {
            // 투표하기 버튼 (진행 중 + 미투표)
            if vote.status == .active && !vote.hasUserVoted {
                Button(action: {
                    onVote(Array(selectedOptionIds))
                }) {
                    Text("투표하기")
                        .appFont(.subheadlineEmphasis, color: .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Constants.voteBtnVPadding)
                }
                .buttonStyle(.glassProminent)
                .tint(.indigo500)
                .disabled(selectedOptionIds.isEmpty)
                .glassEffect()
            }
            
            Text("총 \(vote.totalVotes)명 참여")
                .appFont(.footnote, color: .grey600)
        }
    }

    // MARK: - Function
    private func toggleOption(_ optionId: String) {
        if vote.allowMultipleChoices {
            if selectedOptionIds.contains(optionId) {
                selectedOptionIds.remove(optionId)
            } else {
                selectedOptionIds.insert(optionId)
            }
        } else {
            selectedOptionIds = [optionId]
        }
    }
}


// MARK: - VoteOptionRow
/// 투표 선택 행 (투표 전)
struct VoteOptionRow: View {

    // MARK: - Property
    let option: VoteOption
    let isSelected: Bool
    let allowMultiple: Bool
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let mainPadding: CGFloat = 12
        static let bgOpacity: Double = 0.5
    }

    // MARK: - Body
    var body: some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            // 선택 아이콘
            Image(systemName: isSelected ? "circle.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.indigo500 : Color.grey400)
                .appFont(.title3)
                .glassEffect(.clear)

            Text(option.title)
                .appFont(.callout, color: .black)

            Spacer()
        }
        .padding(Constants.mainPadding)
        .background(isSelected ? Color.indigo200.opacity(Constants.bgOpacity) : Color(.systemBackground).opacity(Constants.bgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
    }
}


// MARK: - VoteResultRow
  /// 투표 결과 행 (투표 후)
struct VoteResultRow: View {
    
    // MARK: - Property
    let option: VoteOption
    let totalVotes: Int
    let isUserSelected: Bool
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let progressHeight: CGFloat = 8
        static let innerPadding: CGFloat = 18
        static let bgOpacity: Double = 0.5
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            topSection
            gaugeSection
            Text("\(option.voteCount)명")
                .appFont(.footnote, color: .grey600)
        }
        .padding(Constants.innerPadding)
        .background(isUserSelected ? Color.indigo200.opacity(Constants.bgOpacity) : Color(.systemBackground).opacity(Constants.bgOpacity))
        .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
    }
    
    // 투표 항목 + 결과
    private var topSection: some View {
        HStack {
            Text(option.title)
                .appFont(isUserSelected ? .bodyEmphasis : .body, color: .black)
            
            Spacer()
            
            if isUserSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.indigo500)
                    .appFont(.callout)
            }
            
            Text(String(format: "%.1f%%", option.percentage(totalVotes: totalVotes)))
                .appFont(.calloutEmphasis, color: isUserSelected ? .indigo700 : .grey700)
        }
    }
    
    // 게이지 바
    private var gaugeSection: some View {
        Gauge(value: option.percentage(totalVotes: totalVotes), in: 0...100) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .gaugeStyle(.linearCapacity)
        .tint(isUserSelected ? Color.indigo500 : Color.grey400)
        .frame(height: Constants.progressHeight)
    }
}


// MARK: - Preview
#Preview("투표 가능 - 단일선택/익명", traits: .sizeThatFitsLayout) {
    NoticeVoteCard(
        vote: NoticeVote(
            id: "poll1",
            question: "다음 해커톤 주제로 어떤 것이 좋을까요?",
            options: [
                VoteOption(id: "1", title: "AI/머신러닝", voteCount: 45),
                VoteOption(id: "2", title: "블록체인", voteCount: 23),
                VoteOption(id: "3", title: "IoT", voteCount: 18),
                VoteOption(id: "4", title: "게임 개발", voteCount: 34)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 7),
            allowMultipleChoices: false,
            isAnonymous: true,
            userVotedOptionIds: []
        ),
        onVote: { _ in }
    )
    .padding()
}

#Preview("투표 완료 - 단일선택/실명", traits: .sizeThatFitsLayout) {
    NoticeVoteCard(
        vote: NoticeVote(
            id: "poll2",
            question: "다음 해커톤 주제로 어떤 것이 좋을까요?",
            options: [
                VoteOption(id: "1", title: "AI/머신러닝", voteCount: 45),
                VoteOption(id: "2", title: "블록체인", voteCount: 23),
                VoteOption(id: "3", title: "IoT", voteCount: 18),
                VoteOption(id: "4", title: "게임 개발", voteCount: 34)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 7),
            allowMultipleChoices: false,
            isAnonymous: false,
            userVotedOptionIds: ["1"]
        ),
        onVote: { _ in }
    )
    .padding()
}

#Preview("투표 종료", traits: .sizeThatFitsLayout) {
    NoticeVoteCard(
        vote: NoticeVote(
            id: "poll3",
            question: "다음 해커톤 주제로 어떤 것이 좋을까요?",
            options: [
                VoteOption(id: "1", title: "AI/머신러닝", voteCount: 45),
                VoteOption(id: "2", title: "블록체인", voteCount: 23),
                VoteOption(id: "3", title: "IoT", voteCount: 18),
                VoteOption(id: "4", title: "게임 개발", voteCount: 34)
            ],
            startDate: Date(timeIntervalSinceNow: -86400 * 10),
            endDate: Date(timeIntervalSinceNow: -86400),
            allowMultipleChoices: false,
            isAnonymous: true,
            userVotedOptionIds: ["1"]
        ),
        onVote: { _ in }
    )
    .padding()
}

#Preview("복수선택/익명", traits: .sizeThatFitsLayout) {
    NoticeVoteCard(
        vote: NoticeVote(
            id: "poll4",
            question: "참여하고 싶은 스터디를 모두 선택해주세요",
            options: [
                VoteOption(id: "1", title: "알고리즘", voteCount: 12),
                VoteOption(id: "2", title: "CS 스터디", voteCount: 25),
                VoteOption(id: "3", title: "디자인 패턴", voteCount: 8),
                VoteOption(id: "4", title: "영어 회화", voteCount: 15)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 7),
            allowMultipleChoices: true,
            isAnonymous: true,
            userVotedOptionIds: []
        ),
        onVote: { _ in }
    )
    .padding()
}

#Preview("복수선택/실명 - 투표완료", traits: .sizeThatFitsLayout) {
    NoticeVoteCard(
        vote: NoticeVote(
            id: "poll5",
            question: "참여하고 싶은 스터디를 모두 선택해주세요",
            options: [
                VoteOption(id: "1", title: "알고리즘", voteCount: 12),
                VoteOption(id: "2", title: "CS 스터디", voteCount: 25),
                VoteOption(id: "3", title: "디자인 패턴", voteCount: 8),
                VoteOption(id: "4", title: "영어 회화", voteCount: 15)
            ],
            startDate: Date(timeIntervalSinceNow: -86400),
            endDate: Date(timeIntervalSinceNow: 86400 * 7),
            allowMultipleChoices: true,
            isAnonymous: false,
            userVotedOptionIds: ["1", "2"]
        ),
        onVote: { _ in }
    )
    .padding()
}
