//
//  Logo.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct Logo: View {
    // MARK: - Property
    @Environment(\.colorScheme) var mode
    
    let logoSize: CGFloat
    
    init(logoSize: CGFloat = 200) {
        self.logoSize = logoSize
    }
    
    private enum Constants {
        static let logoVspacing: CGFloat = 16
        static let logoSubtitle: String = "University Makeus Challenge"
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.logoVspacing, content: {
            Image(logoImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: self.logoSize)
            
            Text(Constants.logoSubtitle)
                .appFont(.title3, color: .grey900)
        })
    }
    
    private var logoImage: ImageResource {
        if mode == .dark {
            return .logoDark
        } else {
            return .logoLight
        }
    }
}

#Preview {
    SplashView()
}

