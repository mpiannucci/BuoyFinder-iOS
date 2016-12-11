//
//  Units.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/10/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

enum Units: String {
    case Metric = "metric"
    case English = "english"
    
    func lengthUnit() -> String {
        switch self {
        case .Metric:
            return "m"
        case .English:
            return "ft"
        }
    }
    
    func speedUnit() -> String {
        switch self {
        case .Metric:
            return "m/s"
        case .English:
            return "mph"
        }
    }
    
    func temperatureUnit() -> String {
        switch self {
        case .Metric:
            return "°C"
        case .English:
            return "°F"
        }
    }
    
    func pressureUnit() -> String {
        switch self {
        case .Metric:
            return "hPa"
        case .English:
            return "inHG"
        }
    }
    
    func visibilityUnit() -> String {
        return "nmi"
    }
    
    func degreesUnit() -> String {
        return "°"
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
