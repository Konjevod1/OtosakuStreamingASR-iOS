//
//  MLMultiArray+Extensions.swift
//  OtosakuStreamingASR
//
//  Created by Marat Zainullin on 14/06/2025.
//

import CoreML

extension MLMultiArray {
    public func fill(value: NSNumber) {
        for i in 0..<count {
            self[i] = value
        }
    }
}
