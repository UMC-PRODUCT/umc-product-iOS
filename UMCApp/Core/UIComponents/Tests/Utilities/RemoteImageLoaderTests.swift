//
//  RemoteImageLoaderTests.swift
//  CoreUIComponentsTests
//
//  Created by euijjang97 on 8/31/26.
//

import CoreGraphics
import Kingfisher
import Testing
import UIKit
@testable import CoreUIComponents

/// ``RemoteImageLoader`` 가 의존하는 Kingfisher 다운샘플 규칙을 못박는다.
///
/// 네트워크는 타지 않는다 — 이 파일이 지키는 건 「목표 크기를 **픽셀**로 해석한다」
/// 하나다. `DownsamplingImageProcessor` 는 크기를 pt 로 보고 스케일을 곱하므로
/// `.scaleFactor(1)` 을 빠뜨리면 3배 화면에서 텍스처가 1536px 로 올라가
/// 카드 한 장이 0.93MB 가 아니라 8MB 를 먹는다. 눈으로는 안 보이는 회귀다.
@Suite("RemoteImageLoader — 다운샘플 픽셀 크기")
struct RemoteImageLoaderTests {

    @Test("scaleFactor(1) 은 목표 픽셀을 그대로 준다")
    func downsamplingProducesTargetPixels() throws {
        let source = try #require(Self.solidImage(side: 1_024).cgImage)

        #expect(source.width == 1_024)

        let processor = DownsamplingImageProcessor(
            size: CGSize(width: Self.targetPixels, height: Self.targetPixels)
        )
        let scaled = try #require(processor.process(
            item: .image(Self.solidImage(side: 1_024)),
            options: KingfisherParsedOptionsInfo([.scaleFactor(1)])
        ))

        #expect(scaled.scale == 1)
        #expect(scaled.cgImage?.width == Int(Self.targetPixels))
        #expect(scaled.cgImage?.height == Int(Self.targetPixels))
    }

    @Test("원본이 목표보다 작으면 키우지 않는다")
    func smallerSourceIsNotUpscaled() throws {
        let processor = DownsamplingImageProcessor(
            size: CGSize(width: Self.targetPixels, height: Self.targetPixels)
        )
        let scaled = try #require(processor.process(
            item: .image(Self.solidImage(side: 64)),
            options: KingfisherParsedOptionsInfo([.scaleFactor(1)])
        ))

        #expect(scaled.cgImage?.width == 64)
    }

    // MARK: - Fixture

    /// 다운샘플 목표 픽셀. 이 값 자체가 검증 대상은 아니고, 위아래 두 테스트가
    /// 「목표보다 큰 원본은 깎고 작은 원본은 두는지」를 같은 기준으로 보게 묶어 둔다.
    private static let targetPixels: CGFloat = 512

    private static func solidImage(side: CGFloat) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        return UIGraphicsImageRenderer(
            size: CGSize(width: side, height: side),
            format: format
        ).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }
}
