//
//  String+Extension.swift
//  Community - Find Your People
//
//  Created by Xilin Liu on 1/31/20.
//

import Foundation

extension String {
    /// Given self as the singular form and quantity as the number, returns a pluralized version of the string
    /// "apple".plural(1) -> "1 apple"
    /// "orange".plural(2) -> "2 oranges"
    func plural(_ quantity: Int) -> String {
        if quantity == 1 {
            // singular
            return "\(quantity) \(self)"
        } else {
            // special cases
            // people
            if self == "person" {
                return "\(quantity) people"
            }

            // plural
            return "\(quantity) \(self)s"
        }
    }

    /// converts any phone number to E164 format
    var asE164: String {
        let filtered = trimmingCharacters(in: .whitespacesAndNewlines).filter("+1234567890".contains)
        switch filtered.prefix(1) {
        case "+": return filtered
        case "1": return "+\(filtered)"
        default: return "+1\(filtered)"
        }
    }

    /// extracts first letter of each word in string
    var asInitials: String {
        return String(split(separator: " ").compactMap({ $0.first })).uppercased().filter { !$0.isEmoji }
    }

    /// converts text to `snake_case`
    var snakeized: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self, options: [], range: range, withTemplate: "$1_$2").lowercased() ?? ""
    }

    // TODO get phone number kit to verify
    var isPhoneNumber: Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue)
        let matches = detector?.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        return matches?.first.flatMap { res in res.resultType == .phoneNumber && res.range.location == 0 && res.range.length == count } ?? false
    }

    var containsEmoji: Bool {
        return contains { $0.isEmoji }
    }

    /// Converts empty string to nil value, no op otherwise
    var emptyOrNil: String? {
        return isEmpty ? nil : self
    }
}

extension Character {
    var isSimpleEmoji: Bool {
        guard let firstProperties = unicodeScalars.first?.properties else { return false }
        return unicodeScalars.count == 1 && (firstProperties.isEmojiPresentation || firstProperties.generalCategory == .otherSymbol)
    }

    var isCombinedIntoEmoji: Bool {
        return (
            unicodeScalars.count > 1 &&
            unicodeScalars.contains {
                $0.properties.isJoinControl ||
                $0.properties.isVariationSelector
            }
        ) || unicodeScalars.allSatisfy { $0.properties.isEmojiPresentation }
    }

    var isEmoji: Bool {
        return isSimpleEmoji || isCombinedIntoEmoji
    }
}
