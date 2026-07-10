import Foundation
import C_h2md

public enum H2MD {
    public static func convert(_ html: String) -> String {
        guard !html.isEmpty else { return "" }
        return html.withCString { cStr in
            guard let result = h2md_convert(cStr) else { return html }
            let swiftString = String(cString: result)
            h2md_free(result)
            return swiftString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    public static func convertBatch(_ items: [String]) -> [String] {
        items.map { convert($0) }
    }

    public static var version: String {
        String(cString: h2md_version())
    }
}
