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
    var date: NSDate
    
    // Wind
    var windDirection: Double?
    var windSpeed: Double?
    var windGust: Double?
    
    // Waves
    var waveSummary: Swell?
    var swellComponents: [Swell]?
    var steepness: String?
    var averagePeriod: Double?
    
    // Weather
    var pressure: Double?
    var airTemperature: Double?
    var waterTemperature: Double?
    var dewpointTemperature: Double?
    var visibility: Double?
    var pressureTendency: Double?
    var waterLevel: Double?
}
