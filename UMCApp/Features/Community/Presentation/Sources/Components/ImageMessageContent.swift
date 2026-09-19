//
//  ImageMessageContent.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/19/26.
//

import SwiftUI
import Kingfisher
import CommunityDomain
import CoreDesignSystem

// MARK: - Constants

fileprivate enum Constants {
    /// 사진 묶음 전체 폭. 말풍선 최대 폭(280)에서 안쪽 여백을 빼고도 남게 잡는다.
    static let contentWidth: CGFloat = 200
    static let spacing: CGFloat = DefaultSpacing.spacing4
    static let columnCount = 2
    static let cornerRadius: CGFloat = 8
    /// 전체 화면 뷰어의 긴 변 상한(px). 다른 클라이언트가 올린 원본(최대 10MB)을 그대로
    /// 풀면 메모리가 튄다.
    static let viewerMaxPixelSize: CGFloat = 2_048
}

/// 사진 메시지의 썸네일 묶음. 탭하면 전체 화면 뷰어가 열린다.
///
/// 캐시 키는 `fileId` 다 — `fileURL` 은 조회할 때마다 재발급되는 단기 서명 URL 이라, URL 을
/// 키로 쓰면 방에 들어올 때마다 같은 사진을 다시 받는다. 낙관적 버블의 로컬 파일도 같은 경로로
/// 그린다(Kingfisher 가 `file://` 을 로컬 제공자로 읽는다).
///
/// ponytail: 뷰어는 공지(`ImageViewerScreen`)와 따로 둔다. 그쪽은 이니셜라이저가 모듈 밖에
/// 열려 있지 않고 URL 을 캐시 키로 쓴다. 세 번째 사용처가 생기면 CoreUIComponents 로 올린다.
struct ImageMessageContent: View {

    // MARK: - Property

    let files: [ThreadMessageFile]

    @State private var selectedIndex = 0
    @State private var isViewerPresented = false
    @Environment(\.displayScale) private var displayScale

    // MARK: - Body

    var body: some View {
        LazyVGrid(
            columns: Array(
                repeating: GridItem(.fixed(thumbnailSide), spacing: Constants.spacing),
                count: min(files.count, Constants.columnCount)
            ),
            spacing: Constants.spacing
        ) {
            ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                Button {
                    selectedIndex = index
                    isViewerPresented = true
                } label: {
                    thumbnail(file)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("사진 \(index + 1)/\(files.count)")
                .accessibilityHint("전체 화면으로 보기")
            }
        }
        .fullScreenCover(isPresented: $isViewerPresented) {
            ImageMessageViewer(files: files, selectedIndex: selectedIndex)
        }
    }

    // MARK: - View Component

    private func thumbnail(_ file: ThreadMessageFile) -> some View {
        KFImage.resource(Self.resource(for: file))
            .placeholder {
                Image(systemName: "photo")
                    .foregroundStyle(Color.grey400)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.grey100)
            }
            // 크기를 pt 가 아니라 px 로 받는다 — 스케일을 곱해 넘겨야 레티나에서 흐리지 않다.
            .setProcessor(DownsamplingImageProcessor(
                size: CGSize(
                    width: thumbnailSide * displayScale,
                    height: thumbnailSide * displayScale
                )
            ))
            .cacheOriginalImage()
            .cancelOnDisappear(true)
            .resizable()
            .scaledToFill()
            .frame(width: thumbnailSide, height: thumbnailSide)
            .clipShape(.rect(cornerRadius: Constants.cornerRadius))
            .contentShape(.rect)
    }

    // MARK: - Computed Property

    /// 한 장이면 묶음 폭을 다 쓰고, 여러 장이면 두 칸 격자로 나눈다.
    private var thumbnailSide: CGFloat {
        guard files.count > 1 else { return Constants.contentWidth }
        let gaps = Constants.spacing * CGFloat(Constants.columnCount - 1)
        return (Constants.contentWidth - gaps) / CGFloat(Constants.columnCount)
    }

    // MARK: - Function

    static func resource(for file: ThreadMessageFile) -> KF.ImageResource? {
        URL(string: file.fileURL).map { KF.ImageResource(downloadURL: $0, cacheKey: file.id) }
    }
}

// MARK: - ImageMessageViewer

/// 전체 화면 사진 뷰어. 여러 장이면 좌우로 넘긴다.
private struct ImageMessageViewer: View {

    // MARK: - Property

    let files: [ThreadMessageFile]
    @State var selectedIndex: Int

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedIndex) {
            ForEach(Array(files.enumerated()), id: \.element.id) { index, file in
                KFImage.resource(ImageMessageContent.resource(for: file))
                    .placeholder { ProgressView().tint(.white) }
                    .setProcessor(DownsamplingImageProcessor(
                        size: CGSize(
                            width: Constants.viewerMaxPixelSize,
                            height: Constants.viewerMaxPixelSize
                        )
                    ))
                    .cacheOriginalImage()
                    .resizable()
                    .scaledToFit()
                    .accessibilityLabel("사진 \(index + 1)/\(files.count)")
                    .tag(index)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: files.count > 1 ? .always : .never))
        .background(Color.black)
        .overlay(alignment: .topTrailing) {
            closeButton
        }
    }

    // MARK: - View Component

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .foregroundStyle(Color.white)
                .frame(
                    width: DefaultConstant.minimumTouchTarget,
                    height: DefaultConstant.minimumTouchTarget
                )
                // 사진 위에 뜨는 버튼이라 `.clear` 로 비친다.
                .glassEffect(.clear.interactive(), in: .circle)
        }
        .buttonStyle(.plain)
        .padding(DefaultConstant.defaultSafeHorizon)
        .accessibilityLabel("닫기")
    }
}
