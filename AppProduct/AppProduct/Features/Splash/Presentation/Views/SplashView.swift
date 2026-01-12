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
    @State var viewModel: SplashViewModel

    // MARK: - Init
    init() {
        self._viewModel = .init(wrappedValue: .init())
    }
    
    // MARK: - Body
    var body: some View {
        Logo()
    }
}

#Preview {
    SplashView()
}
