//
//  Buoy.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

class Buoy: NSObject {
    
    // Required
    var stationID: String
    var location: Location
    
    // Optional
    var owner: String?
    var program: String?
    var buoyType: String?
    var active: Bool?
    var currents: Bool?
    var waterQuality: Bool?
    var dart: Bool?
    
    // Data
    var latestData: BuoyDataItem?
    
    // Update management
    var lastWaveUpdateTime: Date?
    var lastWeatherUpdateTime: Date?
    
    var needsUpdate: Bool {
        get {
            if latestData == nil {
                return true
            }
            
            if let weatherInterval = lastWeatherUpdateTime?.timeIntervalSinceNow {
                if weatherInterval > 30*60 {
                    return true
                }
            } else {
                return true
            }
            
            if let waveInterval = lastWaveUpdateTime?.timeIntervalSinceNow {
                if waveInterval > 30*60 {
                    return true
                }
            } else {
                return true
            }
            
            return false
        }
    }
    
    init(stationID_: String, location_: Location) {
        self.stationID = stationID_
        self.location = location_
        
        super.init()
    }
    
    init(jsonData: JSON) {
        self.stationID = jsonData["StationID"].stringValue
        self.location = Location(latitude: jsonData["Latitude"].doubleValue, longitude: jsonData["Longitude"].doubleValue, altitude: jsonData["Elevation"].doubleValue, locationName: jsonData["LocationName"].stringValue)
        super.init()
        
        // Load the rest of the station info
        loadInfo(jsonData: jsonData)
        self.latestData = nil
    }
    
    internal func loadInfo(jsonData: JSON) {
        self.owner = jsonData["Owner"].string
        self.program = jsonData["PGM"].string
        self.buoyType = jsonData["Type"].string
        
        self.active = (jsonData["Active"].stringValue == "y") as Bool?
        self.currents = (jsonData["Currents"].stringValue == "y") as Bool?
        self.waterQuality = (jsonData["WaterQuality"].stringValue == "y") as Bool?
        self.dart = (jsonData["Dart"].stringValue == "y") as Bool?
    }
    
    internal func loadLatestWaveData(jsonData: JSON) {
        prepareForDataUpdate(rawTime: jsonData["Date"].stringValue)
        
        self.latestData?.waveSummary = Swell(jsonData: jsonData["WaveSummary"])
        self.latestData?.swellComponents = jsonData["SwellComponents"].arrayValue.map({ (swellJSON) -> Swell in
            return Swell(jsonData: swellJSON)
        })
        self.latestData?.steepness = jsonData["Steepness"].string
        self.latestData?.averagePeriod = jsonData["AveragePeriod"].double
        self.latestData?.directionalSpectraPlotURL = jsonData["DirectionalSpectraPlot"].string
        self.latestData?.spectralDistributionPlotURL = jsonData["SpectraDistributionPlot"].string
        
        self.lastWaveUpdateTime = Date()
    }
    
    internal func loadLatestWeatherData(jsonData: JSON) {
        prepareForDataUpdate(rawTime: jsonData["Date"].stringValue)
        
        self.latestData?.windDirection = jsonData["WindDirection"].double
        self.latestData?.windSpeed = jsonData["WindSpeed"].double
        self.latestData?.windGust = jsonData["WindGust"].double
        self.latestData?.pressure = jsonData["Pressure"].double
        self.latestData?.airTemperature = jsonData["AirTemperature"].double
        self.latestData?.waterTemperature = jsonData["WaterTemperature"].double
        self.latestData?.dewpointTemperature = jsonData["DewpointTemperature"].double
        self.latestData?.visibility = jsonData["Visibility"].double
        self.latestData?.pressureTendency = jsonData["PressureTendency"].double
        self.latestData?.waterLevel = jsonData["WaterLevel"].double
        
        self.lastWeatherUpdateTime = Date()
    }
    
    internal func loadLatestData(jsonData: JSON) {
        prepareForDataUpdate(rawTime: jsonData["Date"].stringValue)
        
        self.latestData?.windDirection = jsonData["WindDirection"].double
        self.latestData?.windSpeed = jsonData["WindSpeed"].double
        self.latestData?.windGust = jsonData["WindGust"].double
        self.latestData?.waveSummary = Swell(jsonData: jsonData["WaveSummary"])
        self.latestData?.swellComponents = jsonData["SwellComponents"].arrayValue.map({ (swellJSON) -> Swell in
            return Swell(jsonData: swellJSON)
        })
        self.latestData?.pressure = jsonData["Pressure"].double
        self.latestData?.airTemperature = jsonData["AirTemperature"].double
        self.latestData?.waterTemperature = jsonData["WaterTemperature"].double
        self.latestData?.dewpointTemperature = jsonData["DewpointTemperature"].double
        self.latestData?.visibility = jsonData["Visibility"].double
        self.latestData?.pressureTendency = jsonData["PressureTendency"].double
        self.latestData?.waterLevel = jsonData["WaterLevel"].double
        
        self.lastWaveUpdateTime = Date()
        self.lastWeatherUpdateTime = Date()
    }
    
    private func prepareForDataUpdate(rawTime: String) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let timestamp = dateFormatter.date(from: rawTime)
        
        if self.latestData == nil {
            self.latestData = BuoyDataItem(newDate: timestamp!)
            return
        }
        
        let existingInterval = self.latestData?.date.timeIntervalSince(timestamp!)
        if existingInterval! > 60*60 {
            self.latestData = BuoyDataItem(newDate: timestamp!)
            return
        }

        if let weatherInterval = self.lastWeatherUpdateTime?.timeIntervalSince(timestamp!) {
            if weatherInterval > 60*60 {
                self.latestData?.resetWeatherData()
            }
        }
        
        if let waveInterval = self.lastWaveUpdateTime?.timeIntervalSince(timestamp!) {
            if waveInterval > 60*60 {
                self.latestData?.resetWaveData()
            }
        }
    }
}
