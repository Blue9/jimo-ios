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

    /// converts text to `snake_case`
    var snakeized: String {
        let pattern = "([a-z0-9])([A-Z])"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(location: 0, length: count)
        return regex?.stringByReplacingMatches(
            in: self, options: [], range: range, withTemplate: "$1_$2").lowercased() ?? ""
    }
}
