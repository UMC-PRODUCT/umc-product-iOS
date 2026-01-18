//
//  ToolBarCollection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import SwiftUI

struct ToolBarCollection {
    
    /// 일정 추가 버튼
    struct AddBtn: ToolbarContent {
        let action: () -> Void
        var tintColor: Color = .grey900
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: { action() }, label: {
                    Image(systemName: "magnifyingglass")
                })
                .tint(tintColor)
            })
        }
    }
    
    struct BellBtn: ToolbarContent {
        let action: () -> Void
        var tintColor: Color = .grey900
        let recentPush: Bool = false
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: { action() }, label: {
                    Image(systemName: recentPush ? "bell.badge" : "bell")
                })
                .tint(tintColor)
            })
        }
    }
}
