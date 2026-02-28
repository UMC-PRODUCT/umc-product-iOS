//
//  FlowLayout.swift
//  Catchy
//
//  Created by euijjang97 on 12/4/25.
//

import SwiftUI

struct FlowLayout: Layout {
    var alignment: Alignment
    var spacing: CGFloat

    // MARK: - Init
    init(
        alignment: Alignment = .leading,
        spacing: CGFloat = 10
    ) {
        self.alignment = alignment
        self.spacing = spacing
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        height = y + rowHeight

        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }

            subview.place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + y), proposal: .init(size))

            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
    }
}
