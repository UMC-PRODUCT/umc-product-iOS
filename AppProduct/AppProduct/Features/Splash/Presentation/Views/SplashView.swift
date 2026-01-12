//
//  SplashView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct SplashView: View {
    // MARK: - Property
    @Environment(\.di) var di
    @Environment(\.colorScheme) var mode
    @State var viewModel: SplashViewModel
    
    private enum Constants {
        static let logoVspacing: CGFloat = 16
        static let logoSubtitle: String = "University Makeus Challenge"
    }
    
    // MARK: - Init
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.logoVspacing, content: {
            Image(logoImage)
            
            Text(Constants.logoSubtitle)
                .appFont(.body, color: .grey900)
                .font(.body)
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
