//
//  ARViewInteractor.swift
//  AR_Navigation
//
//  Created by Gleb Radchenko on 10/1/17.
//  Copyright © 2017 Gleb Radchenko. All rights reserved.
//

import ARKit
import SceneKit
import CoreLocation

protocol ARViewInteractorInput: class {
    var lastRecognizedLocation: CLLocation? { get set }
    var lastRecognizedCameraTransform: matrix_float4x4? { get set }
    
    func handleLocationUpdate(newLocation: CLLocation, currentCameraTransform: matrix_float4x4)
}

protocol ARViewInteractorOutput: class {
    func handleInitialPositioning()
    func handlePositionUpdate(locationDiff: Difference<CLLocation>, cameraDiff: Difference<matrix_float4x4>)
    func handleReset()
}

class ARViewInteractor: Interactor {
    typealias Presenter = ARViewInteractorOutput
    
    weak var output: Presenter!
    
    fileprivate var errorFactorCount = 0
    fileprivate let errorThreshold = 10
    fileprivate let acceptableDistanceDiff: Double = 5 // in meters
    
    var lastRecognizedLocation: CLLocation?
    var lastRecognizedCameraTransform: matrix_float4x4?
}

extension ARViewInteractor: ARViewInteractorInput {
    func handleLocationUpdate(newLocation: CLLocation, currentCameraTransform: matrix_float4x4) {
        if let lastLocation = lastRecognizedLocation, let lastTransform = lastRecognizedCameraTransform {
            let locationDifference = Difference(oldValue: lastLocation, newValue: newLocation)
            let cameraDifference = Difference(oldValue: currentCameraTransform, newValue: lastTransform)
            
            if isChangesAcceptable(locationDiff: locationDifference, cameraDiff: cameraDifference) {
                errorFactorCount = 0
                output.handlePositionUpdate(locationDiff: locationDifference, cameraDiff: cameraDifference)
            } else {
                errorFactorCount += 1
                if errorFactorCount >= errorThreshold {
                    errorFactorCount = 0
                    output.handleReset()
                }
            }
            
            lastRecognizedLocation = newLocation
            lastRecognizedCameraTransform = currentCameraTransform
        } else {
            lastRecognizedLocation = newLocation
            lastRecognizedCameraTransform = currentCameraTransform
            output.handleInitialPositioning()
        }
    }
    
    fileprivate func isChangesAcceptable(locationDiff: Difference<CLLocation>, cameraDiff: Difference<matrix_float4x4>) -> Bool {
        let locationTranslation = locationDiff.bias()
        let cameraTranslation = cameraDiff.bias()
        
        let actualDiff = abs(locationTranslation - cameraTranslation)
        
        return actualDiff <= acceptableDistanceDiff
    }
}

