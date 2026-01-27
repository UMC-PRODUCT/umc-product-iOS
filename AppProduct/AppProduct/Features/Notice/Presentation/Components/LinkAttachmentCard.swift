//
//  LinkAttachmentCard.swift
//  AppProduct
//
//  Created by 이예지 on 1/26/26.
//

import SwiftUI

struct LinkAttachmentCard: View, Equatable {
    
    // MARK: - Property
    @Binding var link: String
    var onDismiss: () -> Void
    
    // MARK: - Constant
    fileprivate enum Constants {
        static let xmarkSize: CGFloat = 12
        static let topSectionHPadding: CGFloat = 8
    }
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.link == rhs.link
    }
    
    // MARK: - Body
    var body: some View {
        VStack {
            topSection
            textfieldSection
        }
        .padding(DefaultConstant.defaultBtnPadding)
        .background {
            RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                .fill(.indigo100)
        }
        .glass()
    }
    
    /// 링크 카드 타이틀, 카드 삭제 버튼
    private var topSection: some View {
        HStack {
            Image(systemName: "link")
            Text("링크 첨부")
                .appFont(.footnote, weight: .bold)
            Spacer()
            Button(action: {
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: Constants.xmarkSize))
                    .foregroundStyle(.grey500)
            }
        }
        .padding(.horizontal, Constants.topSectionHPadding)
    }
    
    /// 링크 TextField
    private var textfieldSection: some View {
        TextField("",
                  text: $link,
                  prompt: Text("https://example.com").foregroundStyle(.grey400))
            .textInputAutocapitalization(.never)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .appFont(.callout)
            .padding(DefaultConstant.defaultTextFieldPadding)
            .background {
                RoundedRectangle(cornerRadius: DefaultConstant.defaultCornerRadius)
                    .fill(.grey000)
            }
    }
}

// MARK: - Preview
#Preview {
    @Previewable @State var linkItems: [LinkItem] = []
    
    VStack(spacing: 12) {
        ForEach($linkItems) { $item in
            LinkAttachmentCard(link: $item.link) {
                linkItems.removeAll { $0.id == item.id }
            }
        }
        
        Button("링크 카드 추가") {
            linkItems.append(LinkItem())
        }
    }
}
