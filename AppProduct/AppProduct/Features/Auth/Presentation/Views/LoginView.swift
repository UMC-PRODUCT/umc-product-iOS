//
//  LoginView.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct LoginView: View {
    // MARK:  - Property
    @State var viewModel: LoginViewModel
    
    // MARK: - Init
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            Spacer()
            TopLogo()
            Spacer()
            BottomSocialBtns()
        }
    }
}

// MARK: - TopLogo
fileprivate struct TopLogo: View, Equatable {
    
    // MARK: - Constant
    private enum Constants {
        static let vspacing: CGFloat = 4
        static let logoDescrip: String = "UMC 활동을 더 편하게 관리해보세요"
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.vspacing, content: {
            Logo()
            Text(Constants.logoDescrip)
                .appFont(.body, color: .grey600)
        })
    }
}

// MARK: - BottomSocialBtns
fileprivate struct BottomSocialBtns: View, Equatable {
    
    // MARK: - Constant
    private enum Constants {
        static let btnSpacing: CGFloat = 16
    }
    
    // MARK: - Body
    var body: some View {
        VStack(spacing: Constants.btnSpacing, content: {
            ForEach(SocialType.allCases, id: \.self) {
                $0.image
            }
        })
    }
}

#Preview {
    LoginView()
}
