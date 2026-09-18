//
//  UIImage+Upload.swift
//  CorePhoto
//
//  Created by euijjang97 on 9/19/26.
//

import UIKit

fileprivate enum Constants {
    static let compressionQualities: [CGFloat] = [0.9, 0.7, 0.5, 0.3]
}

public extension UIImage {
    /// 업로드용 JPEG 데이터를 만듭니다.
    ///
    /// 긴 변을 `maxPixelLength` 픽셀 이하로 줄인 뒤, 결과가 `maxByteCount` 이하가 될 때까지
    /// 압축 품질을 단계적으로 낮춥니다.
    ///
    /// - Returns: 인코딩에 실패하거나 최저 품질로도 `maxByteCount`를 넘으면 `nil`
    func jpegDataForUpload(maxPixelLength: CGFloat, maxByteCount: Int) -> Data? {
        let source = resized(toMaxPixelLength: maxPixelLength)
        for quality in Constants.compressionQualities {
            guard let data = source.jpegData(compressionQuality: quality) else {
                return nil
            }
            if data.count <= maxByteCount {
                return data
            }
        }
        return nil
    }

    private func resized(toMaxPixelLength maxPixelLength: CGFloat) -> UIImage {
        let pixelWidth = size.width * scale
        let pixelHeight = size.height * scale
        let longestPixelLength = max(pixelWidth, pixelHeight)
        guard longestPixelLength > maxPixelLength else {
            return self
        }

        let ratio = maxPixelLength / longestPixelLength
        let targetSize = CGSize(
            width: (pixelWidth * ratio).rounded(),
            height: (pixelHeight * ratio).rounded()
        )
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: targetSize, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
