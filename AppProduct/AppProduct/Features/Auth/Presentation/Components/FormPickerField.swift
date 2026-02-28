//
//  FormPickerField.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 선택 옵션을 제공하는 폼 피커 필드
///
/// 드롭다운 Menu 형태로 옵션을 선택할 수 있는 제네릭 컴포넌트입니다.
/// Hashable 프로토콜을 준수하는 모든 타입의 옵션 리스트를 지원합니다.
///
/// - Generic Parameter T: 선택 가능한 옵션의 타입 (Hashable 준수 필요)
struct FormPickerField<T: Hashable>: View {

    // MARK: - Property

    /// 필드 제목
    let title: String

    /// 선택되지 않았을 때 표시할 플레이스홀더 텍스트
    let placeholder: String

    /// 선택된 값 바인딩 (nil이면 미선택 상태)
    @Binding var selection: T?

    /// 선택 가능한 옵션 배열
    let options: [T]

    /// 옵션을 문자열로 변환하는 클로저
    let displayText: (T) -> String

    /// 필수 입력 여부 (기본값: true)
    let isRequired: Bool = true

    /// 제목과 피커 간 수직 간격
    let mainVspacing: CGFloat = DefaultSpacing.spacing8

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: mainVspacing, content: {
            TitleLabel(title: title, isRequired: isRequired)
            pickerView
        })
    }

    /// 드롭다운 메뉴 피커
    ///
    /// Menu를 사용하여 옵션 리스트를 드롭다운 형태로 표시합니다.
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

    /// 피커 메뉴 레이블
    ///
    /// 선택된 값 또는 플레이스홀더를 표시하고, chevron 아이콘을 우측에 배치합니다.
    /// 선택 상태에 따라 텍스트 색상이 변경됩니다.
    private var menuLabel: some View {
        HStack {
            Text(selection.map(displayText) ?? placeholder)
                .appFont(.callout, color: selection == nil ? Color(.placeholderText) : .black)
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
