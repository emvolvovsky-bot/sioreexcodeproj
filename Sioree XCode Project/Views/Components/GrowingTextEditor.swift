//
//  GrowingTextEditor.swift
//  Sioree
//
//  Created by Assistant
//

import SwiftUI
import UIKit

/// A UITextView-backed editor that grows/shrinks to fit its content between min & max heights.
struct GrowingTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    var minHeight: CGFloat = 52
    var maxHeight: CGFloat = 220
    var isFirstResponder: Bool = false
    var font: UIFont = .preferredFont(forTextStyle: .body)

    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.font = font
        tv.backgroundColor = .clear
        tv.isScrollEnabled = false
        tv.textContainerInset = UIEdgeInsets(top: 10, left: 8, bottom: 10, right: 8)
        tv.delegate = context.coordinator
        tv.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        tv.text = text
        tv.isEditable = true
        tv.isSelectable = true
        tv.autocorrectionType = .default
        tv.returnKeyType = .default
        return tv
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
        uiView.font = font

        // Update first responder state
        if isFirstResponder && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        }
        if !isFirstResponder && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }

        // Recalculate height
        DispatchQueue.main.async {
            let size = uiView.sizeThatFits(CGSize(width: uiView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            let height = min(max(size.height, minHeight), maxHeight)
            if self.calculatedHeight != height {
                self.calculatedHeight = height
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: GrowingTextEditor

        init(parent: GrowingTextEditor) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            let size = textView.sizeThatFits(CGSize(width: textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            let height = min(max(size.height, parent.minHeight), parent.maxHeight)
            if parent.calculatedHeight != height {
                parent.calculatedHeight = height
            }
        }
    }
}

