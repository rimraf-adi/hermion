import Foundation

public struct CommandParser {
    public static func processText(_ rawText: String) -> String {
        var text = rawText
        
        let replacements: [(pattern: String, replacement: String)] = [
            ("(?i)\\bnew line\\b", "\n"),
            ("(?i)\\bnew paragraph\\b", "\n\n"),
            ("(?i)\\bcomma\\b", ","),
            ("(?i)\\bperiod\\b|(?i)\\bfull stop\\b", "."),
            ("(?i)\\bquestion mark\\b", "?"),
            ("(?i)\\bexclamation mark\\b|(?i)\\bexclamation point\\b", "!"),
            ("(?i)\\bcolon\\b", ":"),
            ("(?i)\\bsemicolon\\b", ";"),
            ("(?i)\\bopen paren\\b|(?i)\\bopen parenthesis\\b", "("),
            ("(?i)\\bclose paren\\b|(?i)\\bclose parenthesis\\b", ")"),
            ("(?i)\\bopen bracket\\b", "["),
            ("(?i)\\bclose bracket\\b", "]"),
            ("(?i)\\bopen brace\\b", "{"),
            ("(?i)\\bclose brace\\b", "}"),
            ("(?i)\\bhyphen\\b|(?i)\\bdash\\b", "-"),
            ("(?i)\\bunderscore\\b", "_"),
            ("(?i)\\bforward slash\\b|(?i)\\bslash\\b", "/"),
            ("(?i)\\bbackslash\\b", "\\"),
            ("(?i)\\bat sign\\b", "@"),
            ("(?i)\\bhashtag\\b|(?i)\\bhash sign\\b", "#"),
            ("(?i)\\bdollar sign\\b", "$"),
            ("(?i)\\bpercent sign\\b", "%"),
            ("(?i)\\bampersand\\b", "&"),
            ("(?i)\\basterisk\\b", "*"),
            ("(?i)\\bquote\\b|(?i)\\bquotation mark\\b", "\""),
            ("(?i)\\btab key\\b|(?i)\\btab\\b", "\t")
        ]
        
        for (pattern, replacement) in replacements {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                text = regex.stringByReplacingMatches(
                    in: text,
                    options: [],
                    range: NSRange(location: 0, length: text.utf16.count),
                    withTemplate: replacement
                )
            }
        }
        
        // Clean up unwanted spaces before punctuation
        let punctuationFixes = [
            " ,": ",",
            " .": ".",
            " ?": "?",
            " !": "!",
            " :": ":",
            " ;": ";",
            " )": ")",
            "( ": "(",
            " ]": "]",
            "[ ": "[",
            " }": "}",
            "{ ": "{"
        ]
        
        for (target, replacement) in punctuationFixes {
            text = text.replacingOccurrences(of: target, with: replacement)
        }
        
        return text
    }
}
