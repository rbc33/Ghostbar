import WebKit

class StreamDelegate: NSObject, URLSessionDataDelegate {
    let webView: WKWebView
    let parser:  StreamParser
    var buffer = Data()
    var httpError: String? = nil

    init(webView: WKWebView, parser: StreamParser) {
        self.webView = webView; self.parser = parser
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask,
                    didReceive response: URLResponse,
                    completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
            httpError = "HTTP \(http.statusCode)"
        }
        completionHandler(.allow)
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        buffer.append(data)
        if httpError != nil { return }
        // Split on newline bytes before decoding, so a multi-byte UTF-8 character
        // split across chunks stays in the buffer instead of failing the decode.
        guard let lastNewline = buffer.lastIndex(of: 0x0A) else { return }
        let complete = buffer[buffer.startIndex..<lastNewline]
        let lines = (String(data: complete, encoding: .utf8) ?? "").components(separatedBy: "\n")
        buffer = Data(buffer[buffer.index(after: lastNewline)...])
        for line in lines {
            guard !line.isEmpty else { continue }
            if let token = parser.token(from: line) {
                let escaped = token
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "`", with: "\\`")
                    .replacingOccurrences(of: "$", with: "\\$")
                DispatchQueue.main.async {
                    self.webView.evaluateJavaScript("appendToken(`\(escaped)`)", completionHandler: nil)
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        var isError = error != nil
        var msg: String? = nil
        if let e = httpError {
            isError = true
            let body = String(data: buffer, encoding: .utf8) ?? ""
            let detail = body.prefix(200).trimmingCharacters(in: .whitespacesAndNewlines)
            msg = detail.isEmpty ? e : "\(e): \(detail)"
        }
        DispatchQueue.main.async {
            if let m = msg {
                let esc = m.replacingOccurrences(of: "\\", with: "\\\\")
                           .replacingOccurrences(of: "'", with: "\\'")
                self.webView.evaluateJavaScript("appendToken('\(esc)')", completionHandler: nil)
            }
            self.webView.evaluateJavaScript("endStream(\(isError))", completionHandler: nil)
        }
    }
}
