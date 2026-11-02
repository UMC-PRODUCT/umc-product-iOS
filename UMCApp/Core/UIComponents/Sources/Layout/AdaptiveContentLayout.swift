//
//  AdaptiveContentLayout.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 11/2/26.
//

import SwiftUI

/// 컨테이너가 제안한 폭으로 열 수를 정한다. 크기 변경 시 자식 뷰의 identity를 유지한다.
public struct AdaptiveContentLayout: Layout {
    public var layoutDirection: LayoutDirection

    /// 행은 높이를 맞추고, 열은 각 열의 다음 콘텐츠를 바로 이어 배치한다.
    public enum VerticalFlow {
        case rows
        case columns
    }

    public var verticalFlow: VerticalFlow
    public var minimumColumnWidth: CGFloat
    public var maximumColumns: Int
    public var spacing: CGFloat

    public init(
        minimumColumnWidth: CGFloat = 340,
        maximumColumns: Int = 2,
        spacing: CGFloat = 24,
        verticalFlow: VerticalFlow = .rows,
        layoutDirection: LayoutDirection = .leftToRight
    ) {
        self.layoutDirection = layoutDirection
        self.verticalFlow = verticalFlow
        self.minimumColumnWidth = minimumColumnWidth
        self.maximumColumns = maximumColumns
        self.spacing = spacing
    }

    public func sizeThatFits(
        proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) -> CGSize {
        let width = resolvedWidth(proposal.width, subviews: subviews)
        let frames = frames(width: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    public func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        for (index, frame) in frames(width: bounds.width, subviews: subviews).enumerated() {
            let originX = layoutDirection == .rightToLeft
                ? bounds.maxX - frame.maxX : bounds.minX + frame.minX
            subviews[index].place(
                at: CGPoint(x: originX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: frame.width, height: frame.height)
            )
        }
    }

    /// 크기 미지정/무한 제안에서는 자식의 이상적인 폭을 사용한다.
    private func resolvedWidth(_ proposed: CGFloat?, subviews: Subviews) -> CGFloat {
        if let proposed, proposed.isFinite { return max(0, proposed) }
        return subviews.map { $0.sizeThatFits(.unspecified).width }
            .filter(\.isFinite).max() ?? max(1, minimumColumnWidth)
    }

    private func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        let columns = columnCount(width: width, itemCount: subviews.count)
        let gap = max(0, spacing)
        let columnWidth = max(0, (width - CGFloat(columns - 1) * gap) / CGFloat(columns))
        var result: [CGRect] = []
        var rowY: CGFloat = 0
        var rowHeight: CGFloat = 0
        var columnOffsets = Array(repeating: CGFloat.zero, count: columns)
        for index in subviews.indices {
            let column = index % columns
            if column == 0, index > 0 {
                rowY += rowHeight + gap
                rowHeight = 0
            }
            let size = subviews[index].sizeThatFits(
                ProposedViewSize(width: columnWidth, height: nil)
            )
            let height = size.height.isFinite ? max(0, size.height) : 0
            result.append(CGRect(
                x: CGFloat(column) * (columnWidth + gap),
                y: verticalFlow == .columns ? columnOffsets[column] : rowY,
                width: columnWidth, height: height
            ))
            rowHeight = max(rowHeight, height)
            columnOffsets[column] += height + gap
        }
        return result
    }

    func columnCount(width: CGFloat, itemCount: Int) -> Int {
        guard width.isFinite, width > 0 else { return 1 }
        let minimum = max(1, minimumColumnWidth)
        let gap = max(0, spacing)
        let capacity = min(CGFloat(max(1, maximumColumns)), (width + gap) / (minimum + gap))
        return max(1, min(max(1, itemCount), Int(capacity)))
    }
}

public extension View {
    /// 넓은 창에서도 본문이 읽기 좋은 길이를 유지하고 여백을 양쪽에 배분한다.
    func adaptiveReadableWidth(maximum: CGFloat = 720) -> some View {
        frame(maxWidth: maximum)
            .frame(maxWidth: .infinity)
    }
}
