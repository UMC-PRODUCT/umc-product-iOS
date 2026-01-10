//
//  CoreManagementFormView.swift
//  AppProduct
//
//  Created by 이예지 on 1/9/26.
//

import SwiftUI

struct CoreManagementFormView<Header: View, Content: View>: View {
    
    let header: Header
    let content: Content
    
    init(@ViewBuilder header: () -> Header, @ViewBuilder content: () -> Content) {
        self.header = header()
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Section(content: {
                content
            }, header: {
                header
            })
        }
    }
}
