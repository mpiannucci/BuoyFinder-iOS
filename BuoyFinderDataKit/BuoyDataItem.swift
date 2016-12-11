//
//  BuoyDataItem.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

struct BuoyDataItem {
    
    // Date
    var date: Date
    
    // Wind
    var windDirection: Double?
    var windSpeed: Double?
    var windGust: Double?
    
    // Waves
    var waveSummary: Swell?
    var swellComponents: [Swell]?
    var steepness: String?
    var averagePeriod: Double?
    var directionalSpectraPlotURL: String?
    var spectralDistributionPlotURL: String?
    
    // Weather
    var pressure: Double?
    var airTemperature: Double?
    var waterTemperature: Double?
    var dewpointTemperature: Double?
    var visibility: Double?
    var pressureTendency: Double?
    var waterLevel: Double?
    
    // Units
    var units: Units {
        didSet(oldValue) {
            if oldValue == self.units {
                return
            }
            
            switch self.units {
            case .Metric:
                convertToMetric()
            default:
                convertToEnglish()
            }
        }
    }
    
    init(newDate: Date) {
        self.date = newDate
        self.units = Units.Metric
        
        // Initialize everything else to nil as a shortcut
        self.windDirection = nil
        self.windSpeed = nil
        self.windGust = nil
        self.waveSummary = nil
        self.swellComponents = nil
        self.steepness = nil
        self.averagePeriod = nil
        self.directionalSpectraPlotURL = nil
        self.spectralDistributionPlotURL = nil
        self.pressure = nil
        self.airTemperature = nil
        self.waterTemperature = nil
        self.dewpointTemperature = nil
        self.visibility = nil
        self.pressureTendency = nil
        self.waterLevel = nil
    }
    
    public mutating func resetWaveData() {
        self.waveSummary = nil
        self.swellComponents = nil
        self.steepness = nil
        self.averagePeriod = nil
        self.directionalSpectraPlotURL = nil
        self.spectralDistributionPlotURL = nil
    }
    
    public mutating func resetWeatherData() {
        self.windDirection = nil
        self.windSpeed = nil
        self.windGust = nil
        self.pressure = nil
        self.airTemperature = nil
        self.waterTemperature = nil
        self.dewpointTemperature = nil
        self.visibility = nil
        self.pressureTendency = nil
        self.waterLevel = nil
    }
}

extension BuoyDataItem: UnitsProtocol {
    
    // Assumes everything is in english -> going to metric
    public mutating func convertToMetric() {
        if let uWindSpeed = self.windSpeed {
            self.windSpeed = Units.mphToMetersPerSecond(mphValue: uWindSpeed)
        }
        if let uWindGust = self.windGust {
            self.windGust = Units.mphToMetersPerSecond(mphValue: uWindGust)
        }
        if let uAirTemp = self.airTemperature {
            self.airTemperature = Units.fahrenheitToCelsius(fahrenheitValue: uAirTemp)
        }
        if let uWaterTemp = self.waterTemperature {
            self.waterTemperature = Units.fahrenheitToCelsius(fahrenheitValue: uWaterTemp)
        }
        if let uDewpointTemp = self.dewpointTemperature {
            self.dewpointTemperature = Units.fahrenheitToCelsius(fahrenheitValue: uDewpointTemp)
        }
        if let uPressure = self.pressure {
            self.pressure = Units.inchMercuryToHpa(inhgValue: uPressure)
        }
        if let uPressureTendency = self.pressureTendency {
            self.pressureTendency = Units.inchMercuryToHpa(inhgValue: uPressureTendency)
        }
        if let uWaterLevel = self.waterLevel {
            self.waterLevel = Units.feetToMeters(feetValue: uWaterLevel)
        }
        
        self.waveSummary?.units = self.units
        if self.swellComponents != nil {
            for i in self.swellComponents!.indices {
                self.swellComponents![i].units = self.units
            }
        }
    }
    
    // Assumes everything is in metric -> going to english
    public mutating func convertToEnglish() {
        if let uWindSpeed = self.windSpeed {
            self.windSpeed = Units.metersPerSecondToMPH(mpsValue: uWindSpeed)
        }
        if let uWindGust = self.windGust {
            self.windGust = Units.metersPerSecondToMPH(mpsValue: uWindGust)
        }
        if let uAirTemp = self.airTemperature {
            self.airTemperature = Units.celsiusToFahrenheit(celsiusValue: uAirTemp)
        }
        if let uWaterTemp = self.waterTemperature {
            self.waterTemperature = Units.celsiusToFahrenheit(celsiusValue: uWaterTemp)
        }
        if let uDewpointTemp = self.dewpointTemperature {
            self.dewpointTemperature = Units.celsiusToFahrenheit(celsiusValue: uDewpointTemp)
        }
        if let uPressure = self.pressure {
            self.pressure = Units.hpaToInchMercury(hpaValue: uPressure)
        }
        if let uPressureTendency = self.pressureTendency {
            self.pressureTendency = Units.hpaToInchMercury(hpaValue: uPressureTendency)
        }
        if let uWaterLevel = self.waterLevel {
            self.waterLevel = Units.metersToFeet(metricValue: uWaterLevel)
        }
        
        self.waveSummary?.units = self.units
        if self.swellComponents != nil {
            for i in self.swellComponents!.indices {
                self.swellComponents![i].units = self.units
            }
        }
    }
}
