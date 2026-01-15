//
//  StripeBuyButtonView.swift
//  Sioree
//
//  Created by Sioree Team
//

import SwiftUI
import WebKit

struct StripeBuyButtonView: View {
    let buyButtonId: String
    let publishableKey: String
    var height: CGFloat = 60

    var body: some View {
        StripeBuyButtonWebView(
            buyButtonId: buyButtonId,
            publishableKey: publishableKey
        )
        .frame(height: height)
    }
}

private struct StripeBuyButtonWebView: UIViewRepresentable {
    let buyButtonId: String
    let publishableKey: String

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        loadHTML(into: webView)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        loadHTML(into: uiView)
    }

    private func loadHTML(into webView: WKWebView) {
        let html = """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background: transparent;
            }
            stripe-buy-button {
              display: block;
              width: 100%;
            }
          </style>
        </head>
        <body>
          <script async src="https://js.stripe.com/v3/buy-button.js"></script>
          <stripe-buy-button
            buy-button-id="\(buyButtonId)"
            publishable-key="\(publishableKey)">
          </stripe-buy-button>
        </body>
        </html>
        """
        webView.loadHTMLString(html, baseURL: URL(string: "https://js.stripe.com"))
    }
}



