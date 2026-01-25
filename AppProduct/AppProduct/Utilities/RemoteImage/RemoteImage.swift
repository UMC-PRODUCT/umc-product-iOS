//
//  RemoteImage.swift
//  AppProduct
//
//  Created by euijjang97 on 1/24/26.
//

import SwiftUI
import Kingfisher

struct RemoteImage: View {
    typealias ContentMode = SwiftUI.ContentMode
    
    // MARK: - Property
    let urlString: String
    let size: CGSize
    let cornerRadius: CGFloat
    let ratio: CGFloat?
    let contentMode: ContentMode
    
    // MARK: - Init
    init(
        urlString: String,
        size: CGSize,
        cornerRadius: CGFloat = 15,
        ratio: CGFloat? = nil,
        contentMode: ContentMode = .fill
    ) {
        self.urlString = urlString
        self.size = size
        self.cornerRadius = cornerRadius
        self.ratio = ratio
        self.contentMode = contentMode
    }
    
    // MARK: - Body
    var body: some View {
        if let url = URL(string: urlString) {
            KFImage(url)
                .placeholder {
                    ProgressView()
                        .controlSize(.regular)
                }
                .resizable()
                .retry(maxCount: 2, interval: .seconds(2))
                .aspectRatio(ratio, contentMode: contentMode)
                .frame(maxWidth: size.width)
                .frame(height: size.height)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }
}
