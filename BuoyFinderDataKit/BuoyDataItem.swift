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
    
    init(newDate: Date) {
        self.date = newDate
        
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
