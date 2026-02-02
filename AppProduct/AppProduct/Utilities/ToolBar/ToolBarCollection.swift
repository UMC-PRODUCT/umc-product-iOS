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
        let disable: Bool
        
        init(action: @escaping () -> Void, disable: Bool = false) {
            self.action = action
            self.disable = disable
        }
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(role: .confirm, action: {
                    action()
                    dismiss()
                })
                .tint(.indigo500)
                .disabled(disable)
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
    
    /// 커뮤니티 주차별 필터
    struct CommunityWeekFilter: ToolbarContent {
        let weeks: [Int]
        @Binding var selection: Int
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    weekPicker
                } label: {
                    Text("\(selection)주차")
                        .appFont(.subheadline, weight: .medium)
                }
            }
        }
        
        private var weekPicker: some View {
            Picker("주차 선택", selection: $selection) {
                ForEach(weeks, id: \.self) { week in
                    Text("\(week)주차")
                        .tag(week)
                }
            }
            .pickerStyle(.inline)
        }
    }
    
    /// 커뮤니티 학교/파트 필터
    struct CommunityUnivFilter: ToolbarContent {
        @Binding var selectedUniversity: String
        let universities: [String]
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(universities, id: \.self) { university in
                        Toggle(university, isOn: Binding(
                            get: { selectedUniversity == university },
                            set: { isOn in
                                selectedUniversity = isOn ? university : "전체"
                            })
                        )
                    }
                } label: {
                    Image(systemName: "graduationcap.fill")
                        .appFont(.subheadline)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
    }
    
    struct CommunityPartFilter: ToolbarContent {
        @Binding var selectedPart: String
        let parts: [String]
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(parts, id: \.self) { part in
                        Toggle(part, isOn: Binding(
                            get: { selectedPart == part },
                            set: { isOn in
                                selectedPart = isOn ? part : "전체"
                            })
                        )
                    }
                } label: {
                    Image(systemName: "building.columns.fill")
                        .appFont(.subheadline)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
    }
    
    /// 커뮤니티 글 작성 완료 버튼
    struct CommunityPostDoneBtn: ToolbarContent {
        @Environment(\.dismiss) var dismiss
        let isEnabled: Bool
        let action: () -> Void
        
        init(isEnabled: Bool, action: @escaping () -> Void) {
            self.isEnabled = isEnabled
            self.action = action
        }
        
        var body: some ToolbarContent {
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    action()
                    dismiss()
                }) {
                    Image(systemName: "checkmark")
                        .appFont(.body, color: isEnabled ? .indigo700 : .grey400)
                }
                .disabled(!isEnabled)
            }
        }
    }
    

    /// 상단 중앙 섹션 메뉴 툴바 (Button 기반, 애니메이션 지원)
    struct ToolBarCenterMenu<Item: Identifiable & Hashable>: ToolbarContent {
        let items: [Item]
        @Binding var selection: Item
        let itemLabel: (Item) -> String
        let itemIcon: ((Item) -> String)?

        init(
            items: [Item],
            selection: Binding<Item>,
            itemLabel: @escaping (Item) -> String,
            itemIcon: ((Item) -> String)? = nil
        ) {
            self.items = items
            self._selection = selection
            self.itemLabel = itemLabel
            self.itemIcon = itemIcon
        }

        var body: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(items) { item in
                        Button {
                            withAnimation(.snappy) {
                                selection = item
                            }
                        } label: {
                            if let itemIcon = itemIcon {
                                Label(itemLabel(item), systemImage: itemIcon(item))
                            } else {
                                Text(itemLabel(item))
                            }
                        }
                    }
                } label: {
                    menuLabel
                }
            }
        }

        private var menuLabel: some View {
            HStack(spacing: DefaultSpacing.spacing4) {
                Text(itemLabel(selection))
                    .appFont(.subheadline, weight: .medium)
                Image(systemName: "chevron.down.circle.fill")
                    .foregroundStyle(.gray.opacity(0.5))
                    .font(.caption)
            }
            .padding(DefaultConstant.defaultToolBarTitlePadding)
            .glassEffect(.regular)
        }
    }
    
    /// 상단 오른쪽 섹션 메뉴 툴바 (•••)
    struct ToolbarTrailingMenu: ToolbarContent {
        let actions: [ActionItem]
        
        struct ActionItem: Identifiable {
            let id = UUID()
            let title: String
            let icon: String
            let role: ButtonRole?
            let action: () -> Void
            
            init(title: String,
                 icon: String,
                 role: ButtonRole? = nil,
                 action: @escaping () -> Void
            ) {
                self.title = title
                self.icon = icon
                self.role = role
                self.action = action
            }
        }

        var body: some ToolbarContent {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    ForEach(actions) { item in
                        Button(role: item.role) {
                            item.action()
                        } label: {
                            Label(item.title, systemImage: item.icon)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
    }
}
