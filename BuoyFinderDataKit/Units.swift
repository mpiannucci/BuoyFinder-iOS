//
//  Units.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/10/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

public enum Units: String {
    case metric = "metric"
    case english = "english"
    
    public func lengthUnit() -> String {
        switch self {
        case .metric:
            return "m"
        case .english:
            return "ft"
        }
    }
    
    public func speedUnit() -> String {
        switch self {
        case .metric:
            return "m/s"
        case .english:
            return "mph"
        }
    }
    
    public func temperatureUnit() -> String {
        switch self {
        case .metric:
            return "°C"
        case .english:
            return "°F"
        }
    }
    
    public func pressureUnit() -> String {
        switch self {
        case .metric:
            return "hPa"
        case .english:
            return "in HG"
        }
    }
    
    public func visibilityUnit() -> String {
        return "nmi"
    }
    
    public func degreesUnit() -> String {
        return "°"
    }
    
    public func earthRadius() -> Double {
        switch self {
        case .metric:
            return 6373
        case .english:
            return 3961
        }
    }
    
    static func metersToFeet(metricValue: Double) -> Double {
        return metricValue * 3.28
    }
    
    static func feetToMeters(feetValue: Double) -> Double {
        return feetValue / 3.28
    }
    
    static func metersPerSecondToMPH(mpsValue: Double) -> Double {
        return mpsValue * 2.237
    }
    
    static func mphToMetersPerSecond(mphValue: Double) -> Double {
        return mphValue / 2.237
    }
    
    static func celsiusToFahrenheit(celsiusValue: Double) -> Double {
        return (celsiusValue * (9.0/5.0)) + 32.0
    }
    
    static func fahrenheitToCelsius(fahrenheitValue: Double) ->Double {
        return (fahrenheitValue - 32.0) * (5.0/9.0)
    }
    
    static func hpaToInchMercury(hpaValue: Double) -> Double {
        return hpaValue / 33.8638
    }
    
    static func inchMercuryToHpa(inhgValue: Double) -> Double {
        return inhgValue * 33.8638
    }
}

protocol UnitsProtocol {
    mutating func convertToMetric()
    mutating func convertToEnglish()
}
