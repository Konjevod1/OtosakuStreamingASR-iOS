//
//  Array+Extensions.swift.swift
//  OtosakuStreamingASR
//
//  Created by Marat Zainullin on 14/06/2025.
//

import Foundation

extension Array where Iterator.Element: FloatingPoint {
    static func zeros(length: Int) -> [Element] {
        var result: [Element] = [Element]()
        
        for _ in 0..<length {
            result.append(Element.zero)
        }
        
        return result
    }
}
