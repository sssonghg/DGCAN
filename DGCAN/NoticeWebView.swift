//
//  NoticeWebView.swift
//  DGCAN
//
//  Created by AI Assistant on 2/26/26.
//

import SwiftUI
import WebKit

/// 특정 공지의 URL을 로드해서 보여주는 WebView 화면
struct NoticeWebView: View {
    let notice: Notice

    var body: some View {
        WebView(urlString: notice.url)
            .navigationTitle("공지 상세")
            .navigationBarTitleDisplayMode(.inline)
    }
}

/// WKWebView를 SwiftUI에서 쓰기 위한 래퍼
struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()

        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // 필요 시 추후 새 URL 로딩 로직 추가 가능
    }
}

#Preview {
    NoticeWebView(
        notice: Notice(
            title: "2026-1학기 SW연계전공 <튜터> 지원 공고(~3/9(월)오전10시까지)",
            date: "2026-02-25",
            url: "https://cs.dongguk.edu/article/notice/detail/226"
        )
    )
}

