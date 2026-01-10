//
//  Dropdown.swift
//  AppProduct
//
//  Created by 이예지 on 1/9/26.
//

import SwiftUI

fileprivate struct DropdownView: View {
    
    @Binding var config: DropdownConfig
    
    var body: some View {
        List {
            ForEach(1..<3) { _ in
                
            }
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .frame(width: config.anchor.width, height: 200)
        .offset(x: config.anchor.minX, y: config.anchor.minY)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .ignoresSafeArea()
    }
}

struct SourceDropdownView: View {
    
    @Binding var config: DropdownConfig
    
    var body: some View {
        HStack {
            Text(config.school)
                .font(.app(.subheadline, weight: .bold))
            
            Text("\(config.count)")
                .font(.app(.caption1, weight: .regular))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.clear)
                        .strokeBorder(Color.border)
                )
            
            Spacer()
            
            Image(systemName: "chevron.down")
                .resizable()
                .frame(width: 8, height: 4)
                .foregroundStyle(Color.neutral800)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .onTapGesture {
            config.show = true
            withAnimation(.snappy(duration: 0.35, extraBounce: 0)) {
                config.showContent = true
            }
        }
        .onGeometryChange(for: CGRect.self) {
            $0.frame(in: .global)
        } action: { newValue in
            config.anchor = newValue
        }
    }
}

extension View {
    @ViewBuilder
    func dropdownOverlay( _ config: Binding<DropdownConfig>) -> some View {
        self
            .overlay {
                if config.wrappedValue.show {
                    DropdownView(config: config)
                        .transition(.identity)
                }
            }
    }
}

#Preview {
    SourceDropdownView(config: .constant(DropdownConfig(school: "가천대학교", count: 35)))
}
