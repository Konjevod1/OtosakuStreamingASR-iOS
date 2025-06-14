//
//  Layers.swift
//  OtosakuStreamingASR
//
//  Created by Marat Zainullin on 14/06/2025.
//

import Foundation
import CoreML


enum ModelPredictError: Error {
    case outputExtractionFailed
}


public class Model {
    var model: MLModel
    
    public init(url: URL, configuration: MLModelConfiguration) throws {
        model = try MLModel(contentsOf: url, configuration: configuration)
    }
}


public class PreEncoder: Model {
    
    public func predict(x: MLMultiArray, state1: MLMultiArray, state2: MLMultiArray, state3: MLMultiArray) throws -> (MLMultiArray, MLMultiArray, MLMultiArray, MLMultiArray) {
        
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: [
            "x": MLFeatureValue(multiArray: x),
            "state_1": MLFeatureValue(multiArray: state1),
            "state_2": MLFeatureValue(multiArray: state2),
            "state_3": MLFeatureValue(multiArray: state3),
        ])
        
        let out = try model.prediction(from: featureProvider)
        guard let features = out.featureValue(for: "features")?.multiArrayValue, let newState1 = out.featureValue(for: "new_state_1")?.multiArrayValue,
              let newState2 = out.featureValue(for: "new_state_2")?.multiArrayValue, let newState3 = out.featureValue(for: "new_state_3")?.multiArrayValue else {
            throw ModelPredictError.outputExtractionFailed
        }
        
        return (features, newState1, newState2, newState3)
        
    }
}


public class Mask: Model {
    public func predict(processedLength: MLMultiArray) throws -> MLMultiArray {
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: [
            "processed_length": MLFeatureValue(multiArray: processedLength),
        ])
        
        let out = try model.prediction(from: featureProvider)
        guard let mask = out.featureValue(for: "mask")?.multiArrayValue else {
            throw ModelPredictError.outputExtractionFailed
        }
        
        return mask
    }
}



public class ConformerLayer: Model {
    public func predict(x: MLMultiArray, mask: MLMultiArray, k: MLMultiArray, v: MLMultiArray, conv: MLMultiArray, posEmb: MLMultiArray) throws -> (MLMultiArray, MLMultiArray, MLMultiArray, MLMultiArray) {
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: [
            "x": MLFeatureValue(multiArray: x),
            "mask": MLFeatureValue(multiArray: mask),
            "state_k": MLFeatureValue(multiArray: k),
            "state_v": MLFeatureValue(multiArray: v),
            "conv_state": MLFeatureValue(multiArray: conv),
            "pos_emb": MLFeatureValue(multiArray: posEmb),
        ])
        
        let out = try model.prediction(from: featureProvider)
        guard let features = out.featureValue(for: "features")?.multiArrayValue, let new_state_k = out.featureValue(for: "new_state_k")?.multiArrayValue, let new_state_v = out.featureValue(for: "new_state_v")?.multiArrayValue, let new_conv_state = out.featureValue(for: "new_conv_state")?.multiArrayValue else {
            throw ModelPredictError.outputExtractionFailed
        }
        
        return (features, new_state_k, new_state_v, new_conv_state)
    }
}


class CTCDecoder: Model {
    public func predict(encoded: MLMultiArray) throws -> MLMultiArray {
        let featureProvider = try MLDictionaryFeatureProvider(dictionary: [
            "enc_output": MLFeatureValue(multiArray: encoded),
        ])
        
        let out = try model.prediction(from: featureProvider)
        guard let bestPath = out.featureValue(for: "best_path")?.multiArrayValue else {
            throw ModelPredictError.outputExtractionFailed
        }
        
        return bestPath
    }
}
