import Foundation
import C_h2md

/// A lightweight wrapper around the C `h2md` library for HTML-to-Markdown conversion.
///
/// Provide static methods to convert HTML strings into GitHub-Flavored Markdown,
/// suitable for parsing with Apple's `swift-markdown` package.
enum H2MD {

    /// Converts an HTML string to Markdown.
    ///
    /// Returns an empty string if the input is empty. If the underlying C converter
    /// fails, the original HTML is returned unchanged.
    ///
    /// - Parameter html: The HTML string to convert.
    /// - Returns: The resulting Markdown string, trimmed of leading and trailing
    ///   whitespace and newlines.
    static func convert(_ html: String) -> String {
        guard !html.isEmpty else { return "" }
        return html.withCString { cStr in
            guard let result = h2md_convert(cStr) else { return html }
            let swiftString = String(cString: result)
            h2md_free(result)
            return swiftString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }
}
