//
//  EmojiTextField.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 9/17/26.
//

import SwiftUI
import UIKit

/// 이모지 키보드로 바로 열리는 한 줄 입력 칸.
///
/// SwiftUI `TextField` 는 키보드 종류를 고를 수 없고, `opacity(0)` 으로 숨기면 `@FocusState` 를
/// 옮겨도 first responder 가 되지 않는다(#1413). 그래서 UIKit 칸을 감싸 `isFocused` 로 키보드를
/// 직접 올리고 내린다.
///
/// `supportsAdaptiveImageGlyph` 를 끄므로 Genmoji·Memoji 는 후보로 뜨지 않고, 표준 유니코드
/// 이모지만 들어온다.
struct EmojiTextField: UIViewRepresentable {

    // MARK: - Property

    @Binding var text: String

    /// 키보드가 떠 있는지. 키보드를 내리거나 다른 칸으로 옮겨 가면 `false` 로 돌아온다.
    @Binding var isFocused: Bool

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> EmojiInputTextField {
        let textField = EmojiInputTextField()
        textField.supportsAdaptiveImageGlyph = false
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .none
        textField.returnKeyType = .done
        textField.delegate = context.coordinator
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange(_:)),
            for: .editingChanged
        )
        return textField
    }

    func updateUIView(_ uiView: EmojiInputTextField, context: Context) {
        context.coordinator.parent = self

        if uiView.text != text {
            uiView.text = text
        }
        uiView.isEnabled = context.environment.isEnabled

        guard isFocused != uiView.isFirstResponder else { return }
        // 뷰 갱신 중에 first responder 를 바꾸면 델리게이트가 그 자리에서 바인딩을 고쳐 쓴다.
        let shouldFocus = isFocused
        DispatchQueue.main.async {
            if shouldFocus {
                uiView.becomeFirstResponder()
            } else {
                uiView.resignFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UITextFieldDelegate {

        // MARK: - Property

        var parent: EmojiTextField

        // MARK: - Init

        init(parent: EmojiTextField) {
            self.parent = parent
        }

        // MARK: - Function

        @objc func textDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            parent.isFocused = true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFocused = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
        }
    }
}

/// 키보드를 띄울 때 이모지 입력 모드를 먼저 고르는 칸.
///
/// 설정에서 이모지 키보드를 꺼 둔 기기에서는 평소 키보드가 뜬다.
final class EmojiInputTextField: UITextField {

    // MARK: - Property

    override var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first { $0.primaryLanguage == "emoji" }
            ?? super.textInputMode
    }
}
