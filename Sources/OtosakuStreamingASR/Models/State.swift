//
//  State.swift
//  OtosakuStreamingASR
//
//  Created by Marat Zainullin on 14/06/2025.
//

import Foundation
import CoreML


struct ConformerLayerState {
    var k: MLMultiArray
    var v: MLMultiArray
    var conv: MLMultiArray
    
    init() {
        k = try! MLMultiArray(shape: [1, 8, 70, 64], dataType: .float32)
        v = try! MLMultiArray(shape: [1, 8, 70, 64], dataType: .float32)
        conv = try! MLMultiArray(shape: [1, 512, 8], dataType: .float32)
        
        k.fill(value: 0)
        v.fill(value: 0)
        conv.fill(value: 0)
    }
}


public struct State {
    var pre_encode_state_1: MLMultiArray
    var pre_encode_state_2: MLMultiArray
    var pre_encode_state_3: MLMultiArray
    var layer_states: [ConformerLayerState]
    var processed_length: MLMultiArray
    private var processed: Float32
    
    
    
    init() {
        processed = 0
        pre_encode_state_1 = try! MLMultiArray(shape: [1, 1, 2, 80], dataType: .float32)
        pre_encode_state_2 = try! MLMultiArray(shape: [1, 256, 2, 41], dataType: .float32)
        pre_encode_state_3 = try! MLMultiArray(shape: [1, 256, 2, 21], dataType: .float32)
        layer_states = (0..<17).map{ _ in ConformerLayerState() }
        
        processed_length = try! MLMultiArray(shape: [1], dataType: .float32)
        
        pre_encode_state_1.fill(value: 0)
        pre_encode_state_2.fill(value: 0)
        pre_encode_state_3.fill(value: 0)
        processed_length.fill(value: NSNumber(value: processed))
    }
    
    public mutating func step(size: Float32) {
        processed += size
        processed_length.fill(value: NSNumber(value: processed))
    }
}
