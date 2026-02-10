//
//  ImageAttachmentCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import SwiftUI
import PhotosUI

struct ImageAttachmentCard: View, Equatable {

    // MARK: - Property
    let id: UUID
    let imageData: Data?
    let isLoading: Bool
    var onDismiss: () -> Void

    // MARK: - Constant
    fileprivate enum Constants {
        static let imageSize: CGSize = .init(width: 100, height: 100)
        static let xmarkPadding: CGFloat = 10
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id &&
        lhs.isLoading == rhs.isLoading
    }

    // MARK: - Body
    var body: some View {
        ZStack(alignment: .topTrailing) {
            imageCard
            if !isLoading {
                xButton
            }
        }
    }

    private var imageCard: some View {
        Group {
            if isLoading {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(.grey200)
                    .overlay {
                        Progress(size: .small)
                    }
            } else if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
        }
        .frame(width: Constants.imageSize.width, height: Constants.imageSize.height)
        .clipShape(RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius))
        .glassEffect(.clear, in: .rect(cornerRadius: DefaultConstant.defaultCornerRadius))
    }

    private var xButton: some View {
        Button(action: {
            onDismiss()
        }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.grey700)
                .glassEffect()
                .padding(Constants.xmarkPadding)
        }
    }
}

// MARK: - Preview
#Preview("기본 이미지 카드") {
    @Previewable @State var noticeImageItems: [NoticeImageItem] = []
    @Previewable @State var selectedItems: [PhotosPickerItem] = []
    
    VStack {
        ScrollView(.horizontal) {
            HStack(spacing: 12) {
                ForEach(noticeImageItems) { item in
                    ImageAttachmentCard(
                        id: item.id,
                        imageData: item.imageData,
                        isLoading: item.isLoading
                    ) {
                        noticeImageItems.removeAll { $0.id == item.id }
                    }
                }
            }
        }
        PhotosPicker("사진 추가", selection: $selectedItems, maxSelectionCount: 10, matching: .images)
    }
    .onChange(of: selectedItems) { _, newValues in
        Task {
            for item in newValues {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    noticeImageItems.append(NoticeImageItem(imageData: data, isLoading: false))
                }
            }
            selectedItems.removeAll()
        }
    }
}

#Preview("로딩 중인 카드") {
    HStack(spacing: 12) {
        // 로딩 중인 카드
        ImageAttachmentCard(
            id: UUID(),
            imageData: nil,
            isLoading: true,
            onDismiss: {}
        )
        
        // 로딩 중인 카드 2개
        ImageAttachmentCard(
            id: UUID(),
            imageData: nil,
            isLoading: true,
            onDismiss: {}
        )
        
        // 로드된 카드 (예시용 더미 데이터)
        ImageAttachmentCard(
            id: UUID(),
            imageData: UIImage(systemName: "photo")?.pngData(),
            isLoading: false,
            onDismiss: {}
        )
    }
    .padding()
}
