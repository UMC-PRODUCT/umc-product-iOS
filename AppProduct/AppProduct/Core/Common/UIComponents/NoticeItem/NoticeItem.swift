//
//  NoticeItem.swift
//  AppProduct
//
//  Created by 김미주 on 1/9/26.
//

import SwiftUI

// MARK: - NoticeItem

/// 공지 탭 - 리스트

struct NoticeItem: View {
    // MARK: - Properties

    private let model: NoticeItemModel

    // MARK: - Init

    init(model: NoticeItemModel) {
        self.model = model
    }

    // MARK: - Body

    var body: some View {
        NoticeItemPresenter(model: model)
    }
}

// MARK: - Presenter

private struct NoticeItemPresenter: View, Equatable {
    let model: NoticeItemModel

    static func == (lhs: NoticeItemPresenter, rhs: NoticeItemPresenter) -> Bool {
        lhs.model == rhs.model
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 태그 + 필독 + 알림 + 날짜
            HStack {
                HStack(spacing: 8) {
                    Text(model.tag.text)
                        .font(.system(size: 10))
                        .foregroundStyle(model.tag.textColor)
                        .padding(.vertical, 2)
                        .padding(.horizontal, 5)
                        .background(
                            Capsule()
                                .fill(model.tag.backColor)
                                .strokeBorder(model.tag.borderColor)
                        )

                    if model.mustRead {
                        HStack(spacing: 2.5) {
                            Image(systemName: "pin.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 12)
                            Text("필독")
                                .font(.system(size: 12).bold())
                        }
                        .foregroundStyle(.blue)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    if model.isAlert {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                    }

                    Text(formatDate(model.date))
                        .font(.system(size: 12))
                        .foregroundStyle(.gray)
                }
            }

            // 제목 + 내용
            VStack(alignment: .leading, spacing: 4) {
                Text(model.title)
                    .font(.system(size: 16).bold())
                    .foregroundStyle(model.mustRead ? Color.indigo100 : .black)
                    .lineLimit(1)

                Text(model.content)
                    .font(.system(size: 14))
                    .foregroundStyle(.gray)
                    .lineLimit(2)
            }

            // 작성자 + 링크/투표 여부 + 조회수
            HStack(spacing: 8) {
                Text(model.writer)
                    .font(.system(size: 12))

                Spacer()

                if model.hasLink {
                    Image(systemName: "link")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                }

                if model.hasVote {
                    Image(systemName: "chart.bar.xaxis")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 12, height: 12)
                }

                Text("조회 \(model.viewCount)")
                    .font(.system(size: 12))
            }
            .foregroundStyle(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(model.mustRead ? .blue.opacity(0.05) : .white)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        formatter.locale = Locale(identifier: "ko_KR")
        return formatter.string(from: date)
    }
}

#Preview {
    struct NoticeItemPreview: View {
        var body: some View {
            ZStack {
                Color.grey100

                VStack {
                    NoticeItem(
                        model: .init(
                            tag: .central,
                            mustRead: true,
                            isAlert: false,
                            date: Date(),
                            title: "[필독] 12시 활동 가이드라인 및 수료 기준 안내",
                            content: "안녕하세요, **12기 운영진**입니다. 이번 기수 활동 가이드라인과 수료 기준을 안내드립니다. 반드시 숙지하시어 불이익이 없도록 주의 부탁드립니다. ### 1. 출석 기준 - 지각 2회 = 결석 1회 - 결석 3회 이상 시 **수료 불가** ### 2. 스터디 기준 - 매주 파트장이 부여하는 스터디 수행 필수",
                            writer: "중앙 운영진",
                            hasLink: true,
                            hasVote: true,
                            viewCount: 1240
                        )
                    )

                    NoticeItem(
                        model: .init(
                            tag: .campus,
                            mustRead: false,
                            isAlert: true,
                            date: Date(),
                            title: "3월 정기 세션 뒤풀이 장소 안내",
                            content: "이번 주 토요일 세션 후 뒤풀이가 있습니다. 장소는 강남역 인근 **'맛있는 고기집'**입니다. 많은 참여 부탁드립니다!",
                            writer: "중앙대 운영진",
                            hasLink: false,
                            hasVote: false,
                            viewCount: 85
                        )
                    )
                }
                .padding()
            }
        }
    }
    return NoticeItemPreview()
}
