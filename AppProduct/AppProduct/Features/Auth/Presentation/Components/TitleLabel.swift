//
//  TitleLabel.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct TitleLabel: View {
    
    // MARK: - Property
    let title: String
    let isRequired: Bool
    
    // MARK: - Constant
    private enum Constants {
        static let titleSpacing: CGFloat = 2
    }
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: Constants.titleSpacing, content: {
            Text(title)
                .appFont(.body, color: .grey900)
            
            if isRequired {
                Text("*")
                    .appFont(.body, color: .red)
            }
        })
    }
}
