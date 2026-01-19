//
//  CardIconImage.swift
//  AppProduct
//
//  Created by euijjang97 on 1/19/26.
//

import Foundation
import SwiftUI

struct CardIconImage: View {
    
    let image: String
    let color: Color
    @Binding var isLoading: Bool
    
    private enum Constants {
        static let iconPadding: CGFloat = 8
        static let iconSize: CGFloat = 36
        static let cornerRadius: CGFloat = 24
    }
    
    var body: some View {
        iconView
    }
    
    @ViewBuilder
    private var iconView: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(.black)
            } else {
                Image(systemName: image)
                    .font(.title2)
                    .foregroundStyle(color)
            }
        }
        .frame(width: Constants.iconSize, height: Constants.iconSize)
        .padding(Constants.iconPadding)
        .background(color.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: Constants.cornerRadius))
    }
}
