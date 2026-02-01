//
//  LoginPreview.swift
//  AppProduct
//
//  Created by euijjang97 on 1/31/26.
//

import Foundation
import SwiftUI

#Preview("로그인") {
    LoginView()
}


#Preview("회원가입") {
    @Previewable @State var show: Bool = false
    
    NavigationStack {
        Button(action: {
            show.toggle()
        }, label: {
            Text("!1")
        })
        .navigationDestination(isPresented: $show, destination: {
            SignUpView()
        })
    }
}

#Preview("실패시 화면") {
    FailedVerificationUMC()
}

#Preview("홈") {
    NavigationStack {
        HomeView()
    }
    .environment(DIContainer())
    .environment(ErrorHandler())
}
