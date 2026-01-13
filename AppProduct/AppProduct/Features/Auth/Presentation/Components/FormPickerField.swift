//
//  FormPickerField.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

struct FormPickerField<T: Hashable>: View {
    // MARK: - Property
    let title: String 
    let placeholder: String 
    @Binding var selection: T?
    let options: [T]
    let displayText: (T) -> String 
    let isRequired: Bool = true
    
    let mainVspacing: CGFloat = 8
    
    var body: some View {
        VStack(alignment: .leading, spacing: mainVspacing, content: {
            TitleLabel(title: title, isRequired: isRequired)
            pickerView
        })
    }
    
    /// 피커 버튼 구성 및 외부 모습
    private var pickerView: some View {
        Menu(content: {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    selection = option
                }, label: {
                    Text(displayText(option))
                })
            }
        }, label: {
            menuLabel
        })
    }
    
    /// 피커 버튼 외부 모습
    private var menuLabel: some View {
        HStack {
            Text(selection.map(displayText) ?? placeholder)
                .appFont(.body, color: selection == nil ? .grey400 : .grey900)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundStyle(.grey900)
        }
        .padding(DefaultConstant.defaultTextFieldPadding)
        .glassEffect(.regular.interactive())
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedOption: String?
        let options = ["서울대학교", "연세대학교", "고려대학교", "서강대학교"]
        
        var body: some View {
            VStack {
                FormPickerField(
                    title: "학교",
                    placeholder: "학교를 선택하세요",
                    selection: $selectedOption,
                    options: options,
                    displayText: { $0 }
                )
            }
            .padding()
        }
    }
    
    return PreviewWrapper()
}
