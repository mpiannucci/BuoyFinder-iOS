//
//  Buoy.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

public class Buoy: NSCoding {
    
    public static let buoyDataFetchStartedNotification = Notification.Name("buoyDataFetchStarted")
    public static let buoyDataUpdatedNotification = Notification.Name("buoyDataUpdated")
    public static let buoyDataUpdateFailedNotification = Notification.Name("buoyDataUpdateFailed")
    
    // Required
    public var stationID: String
    public var location: Location
    
    // Optional
    public var owner: String?
    public var program: String?
    public var buoyType: String?
    public var active: Bool?
    public var currents: Bool?
    public var waterQuality: Bool?
    public var dart: Bool?
    
    // Data
    public var latestData: BuoyDataItem?
    
    // Update management
    public var lastWaveUpdateTime: Date?
    public var lastWeatherUpdateTime: Date?
    private var fetching: Int = 0
    public var isFetching: Bool {
        get {
            return self.fetching > 0
        }
    }
    
    // Units
    public var units: Units {
        didSet(oldValue) {
            if oldValue == self.units {
                return
            }
            
            self.latestData?.units = self.units
        }
    }
    
    // Convienence
    public var fullName: String {
        get {
            return location.locationName!
        }
    }

    public var name: String {
        get {
            var prettyName = fullName
            if prettyName.contains("-") {
                prettyName = prettyName.components(separatedBy: "-")[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            } else if prettyName.contains("(") {
                prettyName = prettyName.components(separatedBy: "(")[0].trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            }
            return prettyName
        }
    }
    
    public var needsUpdate: Bool {
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
    
    init(stationID: String, location: Location) {
        self.stationID = stationID
        self.location = location
        self.units = .metric
    }
    
    convenience init(jsonData: JSON) {
        let stationId = jsonData["StationID"].stringValue
        let locale = Location(latitude: jsonData["Latitude"].doubleValue, longitude: jsonData["Longitude"].doubleValue, altitude: jsonData["Elevation"].doubleValue, locationName: jsonData["LocationName"].stringValue)
        
        self.init(stationID: stationId, location: locale)
        
        // Load the rest of the station info
        self.loadInfo(jsonData: jsonData)
        self.latestData = nil
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        if let station = aDecoder.decodeObject(forKey: "stationID") as? String,
            let locale = aDecoder.decodeObject(forKey: "location") as? Location {
            self.init(stationID: station, location: locale)
        } else {
            return nil
        }
        
        self.owner = aDecoder.decodeObject(forKey: "owner") as? String
        self.program = aDecoder.decodeObject(forKey: "program") as? String
        self.buoyType = aDecoder.decodeObject(forKey: "buoyType") as? String
        self.active = aDecoder.decodeObject(forKey: "active") as? Bool
        self.currents = aDecoder.decodeObject(forKey: "currents") as? Bool
        self.waterQuality = aDecoder.decodeObject(forKey: "waterQuality") as? Bool
        self.dart = aDecoder.decodeObject(forKey: "dart") as? Bool
        self.latestData = aDecoder.decodeObject(forKey: "latestData") as? BuoyDataItem
        self.lastWaveUpdateTime = aDecoder.decodeObject(forKey: "lastWaveUpdateTime") as? Date
        self.lastWeatherUpdateTime = aDecoder.decodeObject(forKey: "lastWeatherUpdateTime") as? Date
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.stationID, forKey: "stationID")
        aCoder.encode(self.location, forKey: "location")
        aCoder.encode(self.owner, forKey: "owner")
        aCoder.encode(self.program, forKey: "program")
        aCoder.encode(self.buoyType, forKey: "buoyType")
        aCoder.encode(self.active, forKey: "active")
        aCoder.encode(self.currents, forKey: "currents")
        aCoder.encode(self.waterQuality, forKey: "waterQuality")
        aCoder.encode(self.dart, forKey: "dart")
        aCoder.encode(self.latestData, forKey: "latestData")
        aCoder.encode(self.lastWaveUpdateTime, forKey: "lastWaveUpdateTime")
        aCoder.encode(self.lastWeatherUpdateTime, forKey: "lastWeatherUpdateTime")
    }
    
    public func fetchLatestData() {
        self.fetching += 1
        NotificationCenter.default.post(name: Buoy.buoyDataFetchStartedNotification, object: self.stationID)
        
        BuoyNetworkClient.fetchLatestBuoyData(buoy: self) {
            (fetchError) in
            self.fetching -= 1
            if fetchError != nil {
                NotificationCenter.default.post(name: Buoy.buoyDataUpdateFailedNotification, object: self.stationID)
            }
            
            NotificationCenter.default.post(name: Buoy.buoyDataUpdatedNotification, object: self.stationID)
        }
    }
    
    public func fetchLatestWaveData() {
        self.fetching += 1
        NotificationCenter.default.post(name: Buoy.buoyDataFetchStartedNotification, object: self.stationID)
        
        BuoyNetworkClient.fetchLatestBuoyWaveData(buoy: self) {
            (fetchError) in
            self.fetching -= 1
            if fetchError != nil {
                NotificationCenter.default.post(name: Buoy.buoyDataUpdateFailedNotification, object: self.stationID)
            }
            
            NotificationCenter.default.post(name: Buoy.buoyDataUpdatedNotification, object: self.stationID)
        }
    }
    
    public func fetchLatestWeatherData() {
        self.fetching += 1
        NotificationCenter.default.post(name: Buoy.buoyDataFetchStartedNotification, object: self.stationID)
        
        BuoyNetworkClient.fetchLatestBuoyWeatherData(buoy: self) {
            (fetchError) in
            self.fetching -= 1;
            if fetchError != nil {
                NotificationCenter.default.post(name: Buoy.buoyDataUpdateFailedNotification, object: self.stationID)
            }
            
            NotificationCenter.default.post(name: Buoy.buoyDataUpdatedNotification, object: self.stationID)
        }
    }
    
    public func fetchAllLatestData() {
        self.fetchLatestWaveData()
        self.fetchLatestWeatherData()
    }
    
    public func fetchAllDataIfNeeded() {
        if let interval = self.latestData?.date.timeIntervalSinceNow {
            if interval > 50 * 60 {
                fetchAllLatestData()
            }
        } else {
            fetchAllLatestData()
        }
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
    
    internal func loadLatestWaveData(allJsonData: JSON) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let jsonData = allJsonData["BuoyData"]
        prepareForDataUpdate(rawTime: jsonData["Date"].stringValue)
        
        self.latestData?.waveSummary = Swell(jsonData: jsonData["WaveSummary"])
        self.latestData?.swellComponents = jsonData["SwellComponents"].arrayValue.map({ (swellJSON) -> Swell in
            return Swell(jsonData: swellJSON)
        })
        self.latestData?.steepness = jsonData["Steepness"].string
        self.latestData?.averagePeriod = jsonData["AveragePeriod"].double
        self.latestData?.directionalSpectraPlotURL = allJsonData["DirectionalSpectraPlot"].string
        self.latestData?.spectralDistributionPlotURL = allJsonData["SpectraDistributionPlot"].string
        
        self.lastWaveUpdateTime = Date()
        self.latestData?.units = self.units
    }
    
    internal func loadLatestWeatherData(jsonData: JSON) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
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
        self.latestData?.units = self.units
    }
    
    internal func loadLatestData(jsonData: JSON) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        prepareForDataUpdate(rawTime: jsonData["Date"].stringValue)
        
        self.latestData?.windDirection = jsonData["WindDirection"].double
        self.latestData?.windSpeed = jsonData["WindSpeed"].double
        self.latestData?.windGust = jsonData["WindGust"].double
        self.latestData?.waveSummary = Swell(jsonData: jsonData["WaveSummary"])
        self.latestData?.swellComponents = jsonData["SwellComponents"].arrayValue.map({
            (swellJSON) -> Swell in
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
        
        self.latestData?.units = self.units
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
        
        // Set the units to metric for standardized loading
        self.latestData?.units = .metric
    }
}
