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
//
//import SwiftUI
//
//struct SignUpView: View {
//    // MARK: - Property
////    @State var viewModel: SignUpViewModel
////
////    private enum Constants {
////        static let naviSubTitle: String = "동아리 활동을 위해 정보를 입려해주세요."
////    }
//    
////    // MARK: - Init
////    init() {
////        self._viewModel = .init(wrappedValue: .init())
////    }
//    
//    // MARK: - Body
//    var body: some View {
//        VStack {
//            Text("!")
//            //            ForEach(SignUpFieldType.allCases, id: \.self) { field in
//            //                buildField(field)
//            //                Spacer()
//            //            }
//            //            Spacer()
//            //
//            //            MainButton("다음", action: {
//            //                print("다음")
//            //            })
//            //            .safeAreaPadding(.horizontal, DefaultConstant.defaultSafeHorizon)
//            //            .disabled(viewModel.isFormValid)
//            //            .buttonStyle(.glassProminent)
//            //            .navigationSubtitle(Constants.naviSubTitle)
//            //        }
//        }
//    }
////
////    @ViewBuilder
////    private func buildField(_ field: SignUpFieldType) -> some View {
////        switch field.type {
////        case .text:
////            FormTextField(
////                title: field.title,
////                placeholder: field.placeholder,
////                text: binding(
////                    field
////                ),
////                isRequired: field.isRequired
////            )
////        case .email:
////            FormEmailField(title: field.title,
////                           placeholder: field.placeholder,
////                           text: binding(field),
////                           onButtonTap: { print("hello") }
////            )
////        case .picker:
////            FormPickerField(
////                title: field.title,
////                placeholder: field.placeholder,
////                selection: $viewModel.selectedUniv,
////                options: viewModel.univList,
////                displayText: { $0 }
////            )
////        }
////    }
////
////    private func binding(_ field: SignUpFieldType) -> Binding<String> {
////        switch field {
////        case .name:
////            return $viewModel.name
////        case .nickname:
////            return $viewModel.nickname
////        case .email:
////            return $viewModel.email
////        case .univ:
////            return .constant("")
////        }
////    }
//}
//
//#Preview {
//    SignUpView()
//}
