//
//  MessageComposer.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 8/12/26.
//

import PhotosUI
import SwiftUI
import CommunityDomain
import CoreDesignSystem
import CoreUIComponents

// MARK: - Constants

fileprivate enum Constants {
    /// 마이크·전송 원판 지름. 두 버튼을 같은 크기의 원으로 나란히 세운다.
    static let actionButtonSize: CGFloat = 32
    static let placeholder = "메시지를 입력해주세요"
    static let lineLimit = 1...4
    static let editingTitle = "메시지 수정 중"
    /// 인용 칩 왼쪽의 세로 막대. 답장이라는 걸 아이콘 없이 알려 주는 표식이다.
    /// 말풍선 인용 블록과 같은 두께·캡슐 모양으로 맞춘다.
    static let quoteBarWidth: CGFloat = 3
    /// 자동완성 오버레이 최대 높이 — 약 3.5행. 반쯤 걸친 행이 보여야 더 있다는 게 드러난다.
    static let mentionListMaxHeight: CGFloat = 176
    static let mentionRowAvatarSize = CGSize(width: 28, height: 28)
    /// 한 번에 고를 수 있는 사진 수. 서버는 4장까지 받지만 우선 1장만 연다 (#1451).
    static let maxImageSelection = 1
}

/// 하단 입력창.
///
/// 마이크는 음성 체인이 후속 PR 이라 버튼만 두고 비활성화한다 — 나중에 붙을 때 입력창 높이가
/// 바뀌지 않게 자리를 미리 잡아 둔다. 사진 버튼은 버튼 줄 왼쪽 끝에 둔다 — 고르는 즉시
/// 전송하므로 입력 중인 글과 섞이지 않는다 (#1451).
///
/// 인용 칩과 `@` 자동완성은 입력줄 **위로 쌓는다**. 오버레이로 띄우면 마지막 말풍선을 가리는데,
/// 답장을 쓰는 순간에 가장 보고 싶은 게 바로 그 말풍선이다.
struct MessageComposer: View {

    // MARK: - Property

    @Binding var text: String

    let canSend: Bool
    /// 답장 인용 칩. `nil` 이면 칩 자리가 아예 없다 (시안 #22).
    let replyTarget: ThreadMessageReply?
    /// 수정 중인 원문. `nil` 이 아니면 인용 칩 자리에 수정 칩을 띄우고 전송 버튼이 수정 제출이 된다.
    let editingSnippet: String?
    /// `@` 자동완성 후보. 비어 있으면 목록을 그리지 않는다.
    let mentionCandidates: [ThreadMember]
    let onSend: () -> Void
    let onCancelReply: () -> Void
    let onCancelEdit: () -> Void
    let onSelectMention: (ThreadMember) -> Void
    var canAttachImage = false
    var onPickImages: ([PhotosPickerItem]) -> Void = { _ in }

    @State private var pickedImages: [PhotosPickerItem] = []

    /// 버튼 아이콘은 본문 크기를 따라 커지는데 원판이 고정이면 접근성 크기에서 글리프가 밖으로
    /// 삐져나온다. 원판도 같은 비율로 키운다.
    @ScaledMetric(relativeTo: .body) private var actionButtonSize = Constants.actionButtonSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if !mentionCandidates.isEmpty {
                mentionList
            }

            // 칩·카드·버튼의 glass 를 한 번에 그린다. 따로 그리면 glass 마다 오프스크린 패스가 돈다.
            GlassEffectContainer {
                VStack(spacing: 0) {
                    if let editingSnippet {
                        quoteChip(
                            title: Constants.editingTitle,
                            snippet: editingSnippet,
                            cancelLabel: "수정 취소",
                            onCancel: onCancelEdit
                        )
                        .transition(chipTransition)
                    } else if let replyTarget {
                        quoteChip(
                            title: "\(replyTarget.senderName)님에게 답장",
                            snippet: replyTarget.snippet,
                            cancelLabel: "답장 취소",
                            onCancel: onCancelReply
                        )
                        .transition(chipTransition)
                    }

                    inputRow
                }
            }
        }
        // 화면 VStack 이 아니라 여기에 건다. 전송하면 인용 해제와 메시지 추가가 한 번에 일어나서,
        // 위에 걸면 메시지 배열까지 애니메이션 대상이 된다.
        .animation(.snappy, value: replyTarget)
        .animation(.snappy, value: editingSnippet)
    }

    // MARK: - View Component

    /// 입력 카드. 글은 위, 버튼은 카드 안 아래 줄 오른쪽. 여러 줄이 되면 글만 위로 늘고
    /// 버튼 줄은 바닥에 남아서, 캡슐 밖에 버튼이 따로 떨어져 보이던 문제가 없다.
    private var inputRow: some View {
        VStack(spacing: 0) {
            TextField(Constants.placeholder, text: $text, axis: .vertical)
                .appFont(.subheadline)
                .lineLimit(Constants.lineLimit)
                .padding(.horizontal, DefaultSpacing.spacing12)
                .padding(.top, DefaultSpacing.spacing12)

            HStack(spacing: 0) {
                imageButton

                Spacer(minLength: 0)

                Button {
                    // 후속 PR: 음성 입력
                } label: {
                    Image(systemName: "mic")
                        .foregroundStyle(Color.grey500)
                        .frame(width: actionButtonSize, height: actionButtonSize)
                        // 아직 누를 수 없어 `.interactive()` 는 뺀다 — 눌림 반응이 오면 되는 줄 안다.
                        .glassEffect(.regular, in: .circle)
                        .frame(
                            minWidth: DefaultConstant.minimumTouchTarget,
                            minHeight: DefaultConstant.minimumTouchTarget
                        )
                        .contentShape(.rect)
                }
                .disabled(true)
                .accessibilityLabel("음성 입력")

                Button(action: onSend) {
                    Image(systemName: "arrow.up")
                        .foregroundStyle(canSend ? Color.white : Color.grey400)
                        .frame(width: actionButtonSize, height: actionButtonSize)
                        .glassEffect(sendButtonGlass, in: .circle)
                        // 원판이 44pt 보다 작아도 누르는 영역은 44pt 를 채운다.
                        .frame(
                            minWidth: DefaultConstant.minimumTouchTarget,
                            minHeight: DefaultConstant.minimumTouchTarget
                        )
                        .contentShape(.rect)
                }
                .disabled(!canSend)
                .accessibilityLabel(editingSnippet == nil ? "전송" : "수정 완료")
            }
            // 44pt 영역이 원판 둘레에 여백을 만들어 주므로 카드 안쪽 여백은 조금만 더한다.
            .padding(.horizontal, DefaultSpacing.spacing4)
            .padding(.bottom, DefaultSpacing.spacing4)
        }
        // concentric 은 화면 하단 모서리 곡률을 따라 40pt 이상으로 커져서 두세 줄 높이 카드가
        // 캡슐처럼 보였다. 고정 반경으로 줄여 각을 살린다 (#1391).
        .glassEffect(.regular, in: .rect(cornerRadius: DefaultConstant.cornerRadius))
        .padding(.horizontal, DefaultSpacing.spacing16)
        .padding(.vertical, DefaultSpacing.spacing8)
    }

    /// 고르는 즉시 올려 보낸다. 선택을 비워 둬야 같은 사진을 다시 골라도 `onChange` 가 돈다.
    private var imageButton: some View {
        PhotosPicker(
            selection: $pickedImages,
            maxSelectionCount: Constants.maxImageSelection,
            matching: .images
        ) {
            Image(systemName: "photo")
                .foregroundStyle(canAttachImage ? Color.grey700 : Color.grey400)
                .frame(width: actionButtonSize, height: actionButtonSize)
                .glassEffect(canAttachImage ? .regular.interactive() : .regular, in: .circle)
                .frame(
                    minWidth: DefaultConstant.minimumTouchTarget,
                    minHeight: DefaultConstant.minimumTouchTarget
                )
                .contentShape(.rect)
        }
        .disabled(!canAttachImage)
        .accessibilityLabel("사진 보내기")
        .onChange(of: pickedImages) { _, items in
            guard !items.isEmpty else { return }
            onPickImages(items)
            pickedImages = []
        }
    }

    /// 보낼 수 있을 때만 강조색을 채우고 눌림에 반응한다. 비활성은 마이크와 같은 무채색 glass 라
    /// 색이 빠진 것만으로 누를 수 없다는 게 드러난다. `.buttonStyle(.glassProminent)` 는 44pt
    /// 터치 영역 전체를 원으로 칠해서 32pt 원판을 만들 수 없어 glass 를 직접 입힌다.
    private var sendButtonGlass: Glass {
        canSend ? .regular.tint(Color.indigo500).interactive() : .regular
    }

    /// 아래로 미는 `move` 는 반투명 입력 카드 밑으로 칩이 비쳐 보여서 제자리 확대로 띄운다.
    /// 동작 줄이기에서는 페이드만 남긴다.
    private var chipTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .scale(scale: DefaultConstant.transitionScale, anchor: .bottom)
                .combined(with: .opacity)
    }

    /// 답장·수정 대상 요약 + 취소. 취소는 그 모드를 그만두는 유일한 경로라 44pt 를 채운다.
    private func quoteChip(
        title: String,
        snippet: String,
        cancelLabel: String,
        onCancel: @escaping () -> Void
    ) -> some View {
        HStack(spacing: DefaultSpacing.spacing8) {
            // 막대는 글 높이만큼만 선다. 44pt 행 높이를 채우면 둥근 배경 곡선에 끝이 닿는다.
            HStack(spacing: DefaultSpacing.spacing8) {
                Capsule()
                    .fill(Color.indigo500)
                    .frame(width: Constants.quoteBarWidth)

                VStack(alignment: .leading, spacing: DefaultSpacing.spacing4) {
                    Text(title)
                        .appFont(.caption1, weight: .semibold, color: .indigo600)

                    Text(snippet)
                        .appFont(.caption1, color: .grey600)
                        .lineLimit(1)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            // 큰 글자 크기에서는 글이 44pt 를 넘겨 행 높이를 정한다 — 그때도 막대가 위아래를 채우지 않게.
            .padding(.vertical, DefaultSpacing.spacing4)
            .accessibilityElement(children: .combine)

            Spacer(minLength: DefaultSpacing.spacing8)

            Button(action: onCancel) {
                // 본문보다 먼저 눈에 걸리지 않게 글리프만 작고 가늘게. 터치 영역은 44pt 그대로.
                Image(systemName: "xmark")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.grey500)
                    .frame(
                        width: DefaultConstant.minimumTouchTarget,
                        height: DefaultConstant.minimumTouchTarget
                    )
                    .contentShape(.rect)
            }
            .accessibilityLabel(cancelLabel)
        }
        // 배경 안쪽 여백. 인용 막대와 글이 둥근 모서리 곡선에 물리지 않게 띄운다. 반경이 고정이라
        // 글자가 커져 칩이 높아져도 곡선 깊이는 그대로다.
        .padding(.leading, DefaultSpacing.spacing16)
        .padding(.vertical, DefaultSpacing.spacing4)
        // 입력 카드와 같은 glass·반경. 둘이 세로로 쌓여 한 덩어리로 읽힌다.
        .glassEffect(.regular, in: .rect(cornerRadius: DefaultConstant.cornerRadius))
        // 배경 바깥 인셋. 이게 없으면 glass 가 화면 좌우 끝까지 흘러 잘려 나간 띠처럼 보인다.
        // 요약 배너·입력줄과 같은 값으로 맞춰 세로로 한 줄에 선다.
        .padding(.horizontal, DefaultSpacing.spacing16)
    }

    /// `@` 자동완성. 후보가 많아도 입력창을 화면 밖으로 밀지 않게 높이를 묶어 스크롤한다.
    private var mentionList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(mentionCandidates) { member in
                    Button {
                        onSelectMention(member)
                    } label: {
                        mentionRow(member)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxHeight: Constants.mentionListMaxHeight)
        .background(Color.grey000)
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private func mentionRow(_ member: ThreadMember) -> some View {
        HStack(spacing: DefaultSpacing.spacing12) {
            RemoteImage(
                urlString: member.profileImageURL ?? "",
                size: Constants.mentionRowAvatarSize
            )

            Text(member.name)
                .appFont(.subheadline, color: .grey900)
                .lineLimit(1)

            if let part = member.part, !part.isEmpty {
                Text(part)
                    .appFont(.caption2, color: .grey500)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, DefaultSpacing.spacing16)
        .frame(minHeight: DefaultConstant.minimumTouchTarget)
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .accessibilityHint("멘션으로 추가")
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    @Previewable @State var text = "@김"

    VStack {
        Spacer()

        MessageComposer(
            text: $text,
            canSend: true,
            replyTarget: ThreadMessageReply(
                messageId: "1",
                senderName: "김유엠",
                snippet: "오늘 스터디 7시에 시작합니다"
            ),
            editingSnippet: nil,
            mentionCandidates: [
                ThreadMember(
                    id: "1",
                    name: "김유엠",
                    part: "iOS",
                    profileImageURL: nil,
                    role: .owner
                ),
                ThreadMember(
                    id: "2",
                    name: "김메이커스",
                    part: "Web",
                    profileImageURL: nil,
                    role: .member
                )
            ],
            onSend: {},
            onCancelReply: {},
            onCancelEdit: {},
            onSelectMention: { _ in }
        )
    }
}
#endif
