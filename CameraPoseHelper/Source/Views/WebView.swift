//
//  WebViewModel.swift
//  CameraPoseHelper
//
//  Created by Denis Kotelnikov on 24.05.2025.


import SwiftUI
import WebKit

class WebViewModel: ObservableObject {
    @Published var urlString: String
    
    init(urlString: String) {
        self.urlString = urlString
    }
}

struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: viewModel.urlString) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
    }
}

struct WebViewScreen: View {
    @StateObject var viewModel: WebViewModel

    init(url: String) {
        _viewModel = StateObject(wrappedValue: WebViewModel(urlString: url))
    }

    var body: some View {
        WebView(viewModel: viewModel)
    }
}
