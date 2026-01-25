//
//  ToolBarCollection.swift
//  AppProduct
//
//  Created by euijjang97 on 1/13/26.
//

import Foundation
import SwiftUI

struct ToolBarCollection {
    /// 취소 버튼
    struct CancelBtn: ToolbarContent {
        @Environment(\.dismiss) var dismiss
        var action: () -> Void
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .cancellationAction, content: {
                Button(role: .cancel, action: {
                    action()
                    dismiss()
                })
            })
        }
    }
    
    /// 확인 버튼
    struct ConfirmBtn: ToolbarContent {
        @Environment(\.dismiss) var dismiss
        let action: () -> Void
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(role: .confirm, action: {
                    action()
                    dismiss()
                })
                .tint(.indigo500)
            })
        }
    }
    
    /// 추가 버튼
    struct AddBtn: ToolbarContent {
        let action: () -> Void
        let disable: Bool
        
        init(action: @escaping () -> Void, disable: Bool = false) {
            self.action = action
            self.disable = disable
        }
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing, content: {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: "plus")
                })
                .disabled(disable)
            })
        }
    }
    
    struct LeadingButton: ToolbarContent {
        let image: String
        let action: () -> Void
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading, content: {
                Button(action: {
                    action()
                }, label: {
                    Image(systemName: image)
                })
            })
        }
    }
    
    /// 상단 알림 히스토리 버튼
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
    
    /// 상단 로고 툴바
    struct Logo: ToolbarContent {
        let image: ImageResource
        @Namespace var namespace
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading, content: {
                Image(image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 40)
                    .padding(EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6))
                    .disabled(true)
            })
            .sharedBackgroundVisibility(.hidden)
            .matchedTransitionSource(id: "logo", in: namespace)
        }
    }
    
    /// 기수 필터
    struct GenerationFilter: ToolbarContent {

        let title: String
        let generations: [Generation]
        @Binding var selection: Generation

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    generationPicker
                } label: {
                    menuLabel
                }
            }
        }

        private var generationPicker: some View {
            Picker("기수 선택", selection: $selection) {
                ForEach(generations) { generation in
                    Text(generation.title).tag(generation)
                }
            }
            .pickerStyle(.inline)
        }

        private var menuLabel: some View {
            Text(title)
                .font(.callout)
                .fontWeight(.semibold)
        }
    }
    
    /// 상단 중앙 메뉴 툴바 (아이콘O)
    struct TopBarCenterMenu<Item: Identifiable & Hashable>: ToolbarContent {

        let icon: String
        let title: String
        let items: [Item]
        @Binding var selection: Item
        let itemLabel: (Item) -> String
        let itemIcon: ((Item) -> String)?

        init(
            icon: String,
            title: String,
            items: [Item],
            selection: Binding<Item>,
            itemLabel: @escaping (Item) -> String,
            itemIcon: ((Item) -> String)? = nil
        ) {
            self.icon = icon
            self.title = title
            self.items = items
            self._selection = selection
            self.itemLabel = itemLabel
            self.itemIcon = itemIcon
        }

        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                Menu {
                    Picker("선택", selection: $selection) {
                        ForEach(items) { item in
                            if let itemIcon = itemIcon {
                                Label(itemLabel(item), systemImage: itemIcon(item))
                                    .tag(item)
                            } else {
                                Text(itemLabel(item)).tag(item)
                            }
                        }
                    }
                    .pickerStyle(.inline)
                } label: {
                    menuLabel
                }
            }
            .sharedBackgroundVisibility(.visible)
        }

        private var menuLabel: some View {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Spacer()
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 10))
                    .foregroundStyle(.grey500)
            }
            .padding(10)
            .glassEffect(.regular.interactive(), in: .capsule)
        }
    }
}
