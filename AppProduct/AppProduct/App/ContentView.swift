//
//  ContentView.swift
//  AppProduct
//
//  Created by jaewon Lee on 12/30/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(Color.primary500)

            Text("Hello, world!")
                .appFont(.headline, weight: .bold, color: .textPrimary)

            Text("디자인 시스템 테스트")
                .appFont(.body, color: .textSecondary)

            Button("Primary Button") { }
                .buttonStyle(.primary)

            Button("Secondary Button") { }
                .buttonStyle(.secondary)
        }
        .padding()
        .background(Color.background)
    }
}

#Preview {
    ContentView()
}
