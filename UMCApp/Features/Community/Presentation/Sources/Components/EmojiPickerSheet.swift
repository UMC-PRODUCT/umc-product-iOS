//
//  EmojiPickerSheet.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/17/26.
//

import SwiftUI
import CoreDesignSystem

// MARK: - Constants

fileprivate enum Constants {
    static let navigationTitle = "이모지 선택"
    static let dismissTitle = "닫기"
    static let cellSize: CGFloat = 44
    static let emojiSize: CGFloat = 28
    /// 얼굴부터 보이게 블록 순서를 잡는다. 코드 포인트 순이면 날씨·기호가 먼저 나온다.
    static let scalarRanges: [ClosedRange<UInt32>] = [
        0x1F600...0x1F64F,
        0x1F900...0x1FAFF,
        0x1F300...0x1F5FF,
        0x1F650...0x1F8FF,
        0x1F000...0x1F2FF,
        0x2100...0x2BFF
    ]
    static let regionalIndicators: ClosedRange<UInt32> = 0x1F1E6...0x1F1FF
}

// MARK: - Emoji Picker Sheet

/// 반응 바 `+` 로 여는 전체 이모지 목록.
///
/// 키보드 입력을 열지 않고 표준 유니코드 단일 글리프만 나열한다 — 자유 입력을 받으면
/// Genmoji·여러 글자가 섞여 서버 검증(그래파임 하나)에 걸린다. 국기·피부톤·ZWJ 조합은 빠진다.
struct EmojiPickerSheet: View {

    // MARK: - Property

    /// 나열할 이모지. 전부 서버 검증을 통과해야 하므로 테스트가 직접 읽는다.
    static let emojis: [String] = Constants.scalarRanges.flatMap { range in
        range.compactMap { value -> String? in
            guard !Constants.regionalIndicators.contains(value),
                  let scalar = Unicode.Scalar(value),
                  scalar.properties.isEmoji,
                  !scalar.properties.isEmojiModifier else { return nil }
            // 기본 표시가 텍스트인 글리프(❤ 등)는 VS16 을 붙여야 이모지로 그려진다.
            return scalar.properties.isEmojiPresentation
                ? String(scalar)
                : String(scalar) + "\u{FE0F}"
        }
    }

    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: Constants.cellSize))]) {
                    ForEach(Self.emojis, id: \.self) { emoji in
                        Button {
                            onSelect(emoji)
                        } label: {
                            Text(emoji)
                                .font(.system(size: Constants.emojiSize))
                                .frame(width: Constants.cellSize, height: Constants.cellSize)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
                .padding(.vertical, DefaultSpacing.spacing16)
            }
            .umcDefaultBackground()
            .navigationTitle(Constants.navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(Constants.dismissTitle) { dismiss() }
                        .appFont(.body, color: .grey700)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    EmojiPickerSheet(onSelect: { _ in })
}
#endif
