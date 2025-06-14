//
//  ConformerEncoder.swift
//  OtosakuStreamingASR
//
//  Created by Marat Zainullin on 14/06/2025.
//


import Foundation
import CoreML
import Dispatch


enum ConformerEncoderError: Error {
    case posEmbeddingLoadError(String)
    case unexpectedFeatShape(NSNumber)
}


public class ConformerEncoder {
    private let feat_size_size_80ms: NSNumber = 16
    private let feat_size_size_480ms: NSNumber = 56
    private let feat_size_size_1040ms: NSNumber = 112
    
    private var preEncoder: PreEncoder
    private var mask_80ms: Mask
    private var mask_480ms: Mask
    private var mask_1040ms: Mask
    private var layers: [ConformerLayer]
    private var longTernState = State()
    private var shortTernState = State()
    private let xScale: Double = sqrt(512.0)
    private var pos_emb_80ms: MLMultiArray
    private var pos_emb_480ms: MLMultiArray
    private var pos_emb_1040ms: MLMultiArray
    
    private let TAG = "ConformerEncoder"
    
    public init(from directoryURL: URL, configuration: MLModelConfiguration) throws {
        preEncoder = try PreEncoder(url: directoryURL.appendingPathComponent("pre_encode.mlmodelc"), configuration: configuration)
        mask_80ms = try Mask(url: directoryURL.appendingPathComponent("mask_80ms.mlmodelc"), configuration: configuration)
        mask_480ms = try Mask(url: directoryURL.appendingPathComponent("mask_480ms.mlmodelc"), configuration: configuration)
        mask_1040ms = try Mask(url: directoryURL.appendingPathComponent("mask_1040ms.mlmodelc"), configuration: configuration)
        layers = try (0...16).map { try ConformerLayer(url: directoryURL.appendingPathComponent("layer\($0).mlmodelc"), configuration: configuration) }
        pos_emb_80ms = try ConformerEncoder.loadPosEmb(by: directoryURL.appendingPathComponent("pos_emb_80ms.npy"), length: 143)
        pos_emb_480ms = try ConformerEncoder.loadPosEmb(by: directoryURL.appendingPathComponent("pos_emb_480ms.npy"), length: 153)
        pos_emb_1040ms = try ConformerEncoder.loadPosEmb(by: directoryURL.appendingPathComponent("pos_emb_1040ms.npy"), length: 167)
    }
    
    public func reset() {
        longTernState = State()
        shortTernState = State()
    }
    
    public func predict(x: MLMultiArray) throws -> MLMultiArray {
        
        var maskOut: MLMultiArray
        var pos_emb: MLMultiArray
        
        var state: State
        
        if x.shape[1] == feat_size_size_80ms {
            state = shortTernState
            maskOut = try mask_80ms.predict(processedLength: state.processed_length)
            pos_emb = pos_emb_80ms
        } else if x.shape[1] == feat_size_size_480ms {
            state = longTernState
            maskOut = try mask_480ms.predict(processedLength: state.processed_length)
            pos_emb = pos_emb_480ms
        } else {
            if x.shape[1] != feat_size_size_1040ms {
                throw ConformerEncoderError.unexpectedFeatShape(x.shape[1])
            }
            state = longTernState
            maskOut = try mask_1040ms.predict(processedLength: state.processed_length)
            pos_emb = pos_emb_1040ms
        }
        
        let (preEncoderOut, state1, state2, state3) = try preEncoder.predict(x: x, state1: state.pre_encode_state_1, state2: state.pre_encode_state_2, state3: state.pre_encode_state_3)
        state.pre_encode_state_1 = state1
        state.pre_encode_state_2 = state2
        state.pre_encode_state_3 = state3
        
        scaleTensor(tensor: preEncoderOut)
        
        var out = preEncoderOut
        
        for (i, layer) in layers.enumerated() {
            let (layerOut, k, v, conv) = try layer.predict(x: out, mask: maskOut, k: state.layer_states[i].k, v: state.layer_states[i].v, conv: state.layer_states[i].conv, posEmb: pos_emb)
            out = layerOut
            state.layer_states[i].k = k
            state.layer_states[i].v = v
            state.layer_states[i].conv = conv
        }
        
        state.step(size: x.shape[1].floatValue)
        
        if x.shape[1] == feat_size_size_1040ms {
            longTernState = state
            shortTernState = state
        } else if x.shape[1] == feat_size_size_480ms {
            shortTernState = state
        } else if x.shape[1] == feat_size_size_80ms {
            shortTernState = state
        }
        
        return out
    }
    
    private func scaleTensor(tensor: MLMultiArray) {
        let scaler: Float32 = Float32(xScale)
        let pointer = UnsafeMutablePointer<Float32>(OpaquePointer(tensor.dataPointer))
        for i in 0..<tensor.count {
            pointer[i] *= scaler
        }
    }
    
    
    private static func loadPosEmb(by url: URL, length: NSNumber) throws -> MLMultiArray {
        guard let data = try? Data(contentsOf: url) else {
            throw ConformerEncoderError.posEmbeddingLoadError("Failed to load pos embedding file")
        }
        let headerSize = 128
        let validData = data.dropFirst(headerSize)
        let array = validData.withUnsafeBytes { pointer -> [Float] in
            let buffer = pointer.bindMemory(to: Float.self)
            return Array(buffer)
        }
        let shape: [NSNumber] = [1, length, 512]
        guard let mlArray = try? MLMultiArray(shape: shape, dataType: .float32) else {
            throw ConformerEncoderError.posEmbeddingLoadError("Failed to create MLMultiArray")
        }
        for i in 0..<array.count {
            mlArray[i] = NSNumber(value: array[i])
        }
        return mlArray
    }
    
    
}
