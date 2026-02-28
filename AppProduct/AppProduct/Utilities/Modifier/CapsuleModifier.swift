//
//  CapsuleModifier.swift
//  AppProduct
//
//  Created by euijjang97 on 1/18/26.
//

import Foundation
import SwiftUI

struct CapsuleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(width: 40, height: 5)
            .foregroundStyle(.grey400)
    }
}
