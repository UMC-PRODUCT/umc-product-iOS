//
//  NoticeImageCard.swift
//  AppProduct
//
//  Created by 이예지 on 2/2/26.
//

import SwiftUI
import Kingfisher

// MARK: - NoticeImageCard
struct NoticeImageCard: View {
    
    // MARK: - Property
    let imageURLs: [String]
    @State private var selectedImageIndex: Int?
    
    // MARK: - Constants
    fileprivate enum Constants {
        static let imageSize: CGFloat = 160
    }
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DefaultSpacing.spacing8) {
                    ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                        KFImage(URL(string: url))
                            .placeholder {
                                Progress(size: .small)
                                    .frame(width: Constants.imageSize, height: Constants.imageSize)
                                    .background(Color(.systemGroupedBackground))
                            }
                            .retry(maxCount: 3, interval: .seconds(3))
                            .fade(duration: 0.3)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: Constants.imageSize, height: Constants.imageSize)
                            .clipped()
                            .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
                            .onTapGesture {
                                selectedImageIndex = index
                            }
                    }
                }
                .padding(.horizontal, DefaultConstant.defaultSafeHorizon)
            }
        }
        .fullScreenCover(item: Binding(
            get: { selectedImageIndex.map { ImageViewerItem(index: $0) } },
            set: { selectedImageIndex = $0?.index }
        )) { item in
            ImageViewerScreen(
                imageURLs: imageURLs,
                selectedIndex: item.index,
                onDismiss: { selectedImageIndex = nil }
            )
        }
    }
}

// MARK: - ImageViewerScreen
/// 전체화면 이미지 뷰어
struct ImageViewerScreen: View {
    
    // MARK: - Property
    let imageURLs: [String]
    @State var selectedIndex: Int
    let onDismiss: () -> Void
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let bgOpacity: Double = 0.7
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
                .opacity(Constants.bgOpacity)
            
            TabView(selection: $selectedIndex) {
                ForEach(Array(imageURLs.enumerated()), id: \.offset) { index, url in
                    KFImage(URL(string: url))
                        .placeholder {
                            Progress(progressColor: .grey200, message: "이미지 로딩중", messageColor: .grey400, size: .large)
                        }
                        .retry(maxCount: 3, interval: .seconds(3))
                        .fade(duration: 0.3)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundStyle(.grey400)
                            .padding()
                    }
                }
                Spacer()
            }
        }
    }
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    NoticeImageCard(imageURLs: [
        "https://picsum.photos/200/200",
        "https://picsum.photos/200/201",
        "https://picsum.photos/200/202",
        "https://picsum.photos/200/203",
        "https://picsum.photos/200/204"
    ])
}

#Preview("로딩 중", traits: .sizeThatFitsLayout) {
    NoticeImageCard(imageURLs: [
        "https://httpbin.org/delay/10",
        "https://httpbin.org/delay/10",
        "https://httpbin.org/delay/10"
    ])
}
