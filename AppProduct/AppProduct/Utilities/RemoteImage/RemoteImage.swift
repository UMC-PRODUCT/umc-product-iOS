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

    // MARK: - Properties
    
    /// 이미지 URL 문자열
    let urlString: String
    
    /// 이미지 뷰의 크기
    let size: CGSize
    
    /// 이미지의 모서리 둥글기 반경 (기본값: 15)
    let cornerRadius: CGFloat
    
    /// 이미지의 가로세로 비율 (옵셔널)
    let ratio: CGFloat?
    
    /// 이미지 콘텐츠 모드 (fill, fit 등)
    let contentMode: ContentMode
    
    /// 로드 실패 시 표시할 플레이스홀더 시스템 이미지 이름
    let placeholderImage: String

    // MARK: - Init
    
    /// RemoteImage 뷰를 초기화합니다.
    /// - Parameters:
    ///   - urlString: 이미지 URL 문자열
    ///   - size: 이미지 뷰의 크기 (width, height)
    ///   - cornerRadius: 모서리 둥글기 (기본값: 15)
    ///   - ratio: 이미지 비율 (옵셔널)
    ///   - contentMode: 콘텐츠 모드 (기본값: .fill)
    ///   - placeholderImage: 실패 시 보여줄 시스템 이미지 이름 (기본값: "person.circle.fill")
    init(
        urlString: String,
        size: CGSize,
        cornerRadius: CGFloat = 15,
        ratio: CGFloat? = nil,
        contentMode: ContentMode = .fill,
        placeholderImage: String = "person.circle.fill"
    ) {
        self.urlString = urlString
        self.size = size
        self.cornerRadius = cornerRadius
        self.ratio = ratio
        self.contentMode = contentMode
        self.placeholderImage = placeholderImage
    }
    
    // MARK: - Body
    
    var body: some View {
        Group {
            // URL 문자열이 유효한 경우 Kingfisher를 통해 이미지 로드
            if let url = URL(string: urlString) {
                KFImage(url)
                    .placeholder {
                        // 로딩 중일 때 표시할 인디케이터
                        ProgressView()
                            .controlSize(.regular)
                    }
                    .resizable() // 크기 조절 가능하도록 설정
                    .retry(maxCount: 1, interval: .seconds(2))
                    .onFailureImage(UIImage(systemName: placeholderImage)) // 최종 실패 시 표시할 이미지
                    .fade(duration: 0.25) // 이미지 로드 완료 시 페이드 효과
            }
        }
        .aspectRatio(ratio, contentMode: contentMode) // 비율 및 콘텐츠 모드 설정
        .frame(maxWidth: size.width) // 최대 너비 설정
        .frame(height: size.height) // 높이 설정
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius)) // 둥근 모서리 적용
    }
}
