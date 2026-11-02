//
//  AdaptiveContentLayoutTests.swift
//  CoreUIComponentsTests
//
//  Created by euijjang97 on 11/2/26.
//

import Testing
import SwiftUI
import UIKit
@testable import CoreUIComponents

struct AdaptiveContentLayoutTests {
    @Test @MainActor func measuredRowsGrowWithoutClippingWhenWindowNarrows() {
        let host = UIHostingController(rootView:
            AdaptiveContentLayout {
                Color.clear.frame(height: 100)
                Color.clear.frame(height: 200)
            }
        )
        let expanded = host.sizeThatFits(in: CGSize(width: 704, height: 1000))
        let compact = host.sizeThatFits(in: CGSize(width: 390, height: 1000))
        #expect(expanded.height == 200)
        #expect(compact.height == 324)
        #expect(compact.width == 390)
    }

    @Test @MainActor func independentColumnsDoNotReserveSpaceForTallerNeighbor() {
        let host = UIHostingController(rootView:
            AdaptiveContentLayout(verticalFlow: .columns) {
                Color.clear.frame(height: 100)
                Color.clear.frame(height: 200)
                Color.clear.frame(height: 300)
                Color.clear.frame(height: 50)
            }
        )
        // 첫 열 100 + 24 + 300. 두 번째 열의 200pt 카드 때문에 100pt를 비우지 않는다.
        let expanded = host.sizeThatFits(in: CGSize(width: 704, height: 2000))
        let compact = host.sizeThatFits(in: CGSize(width: 390, height: 2000))
        #expect(expanded.height == 424)
        #expect(compact.height == 722)
    }

    @Test func narrowWindowKeepsOneColumn() {
        let layout = AdaptiveContentLayout()
        #expect(layout.columnCount(width: 320, itemCount: 4) == 1)
        #expect(layout.columnCount(width: 703, itemCount: 4) == 1)
    }

    @Test func expansionRequiresSpaceForBothColumnsAndGap() {
        let layout = AdaptiveContentLayout()
        #expect(layout.columnCount(width: 704, itemCount: 4) == 2)
        #expect(layout.columnCount(width: 1100, itemCount: 4) == 2)
        #expect(layout.columnCount(width: 704, itemCount: 1) == 1)
    }

    @Test func accessibilityStaysSingleColumnAtAnyWidth() {
        let layout = AdaptiveContentLayout(maximumColumns: 1)
        #expect(layout.columnCount(width: 1100, itemCount: 4) == 1)
    }

    @Test func resizeSequenceRecomputesWithoutCachedDeviceGeometry() {
        let layout = AdaptiveContentLayout()
        let columns = [390.0, 820, 540, 1024, 390].map {
            layout.columnCount(width: $0, itemCount: 4)
        }
        #expect(columns == [1, 2, 1, 2, 1])
    }

    @Test func degenerateProposalsRemainValid() {
        let layout = AdaptiveContentLayout(minimumColumnWidth: 0, maximumColumns: 0)
        #expect(layout.columnCount(width: 0, itemCount: 0) == 1)
        #expect(layout.columnCount(width: .infinity, itemCount: 4) == 1)
    }
}
