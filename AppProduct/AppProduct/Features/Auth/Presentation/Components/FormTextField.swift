//
//  FormTextField.swift
//  AppProduct
//
//  Created by euijjang97 on 1/12/26.
//

import SwiftUI

/// 앱 내 설문/입력 폼에서 일관된 스타일로 사용되는 텍스트 필드 컴포넌트입니다.
/// 
/// 제목(Title)과 입력 필드(TextField)가 수직(VStack)으로 배치된 형태입니다.
/// 필수 입력 여부를 표시할 수 있으며, 키보드 완료 동작 등을 커스터마이징 할 수 있습니다.
///
/// - Usage:
/// ```swift
/// @State private var name: String = ""
///
/// var body: some View {
///     FormTextField(
///         title: "이름",
///         placeholder: "이름을 입력해주세요",
///         text: $name,
///         isRequired: true,
///         submitLabel: .done,
///         onSubmit: {
///             print("입력 완료")
///         }
///     )
/// }
/// ```
struct FormTextField: View {

    // MARK: - Property
    
    /// 입력 필드 상단에 표시될 제목입니다.
    let title: String
    
    /// 입력 값이 없을 때 보여질 플레이스홀더 텍스트입니다.
    let placeholder: String
    
    /// 입력된 텍스트와 바인딩되는 속성입니다.
    @Binding var text: String
    
    /// 필수 입력 항목인지 여부를 나타냅니다. (기본값: true)
    /// true일 경우 제목 옆에 필수 표시(예: *)가 나타날 수 있습니다.
    var isRequired: Bool = true
    
    /// 키보드의 엔터 키 타입을 설정합니다. (기본값: .next)
    var submitLabel: SubmitLabel = .next
    
    /// 엔터 키를 눌렀을 때 실행될 액션입니다.
    var onSubmit: (() -> Void)?
    
    // MARK: - Body
    
    var body: some View {
        // 제목과 텍스트 필드를 수직으로 정렬
        VStack(alignment: .leading, spacing: DefaultSpacing.spacing8, content: {
            // 필수 여부에 따른 제목 표시
            TitleLabel(title: title, isRequired: isRequired)
            // 실제 텍스트 입력 필드
            textFieldView
        })
    }
    
    /// 텍스트 작성 필드 뷰입니다.
    ///
    /// - 스타일: 배경색이 없는 투명한 텍스트 필드에 유리 효과(glassEffect) background modifiers가 적용된 것으로 보입니다.
    /// - 글자색, 패딩, 제출 동작 등이 정의되어 있습니다.
    private var textFieldView: some View {
        TextField("", text: $text, prompt: placeholderView)
            .foregroundStyle(.grey900) // 입력 텍스트 색상
            .padding(DefaultConstant.defaultTextFieldPadding) // 내부 패딩
            .glassEffect(.regular) // 커스텀 유리 효과 수정자 적용
            .submitLabel(submitLabel) // 키보드 리턴 키 설정
            .onSubmit {
                // 엔터 키 입력 시 전달된 클로저 실행
                onSubmit?()
            }
    }
    
    /// 텍스트 필드 내부에 표시될 커스텀 플레이스홀더 뷰입니다.
    /// SwiftUI 기본 placeholder보다 상세한 스타일링을 위해 사용됩니다.
    private var placeholderView: Text {
        Text(placeholder)
            .font(.callout)
            .foregroundStyle(.gray)
    }
}

#Preview {
    ZStack(alignment: .trailing) {
        FormTextField(title: "이름", placeholder: "중앙대학교", text: .constant(""))
            .disabled(true)
    }
}
