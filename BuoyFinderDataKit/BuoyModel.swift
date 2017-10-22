//
//  BuoyModel.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/14/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

public class BuoyModel: NSObject {
    
    public static let sharedModel = BuoyModel()
    
    // Station notifications
    public static let buoyStationsFetchStartedNotification = Notification.Name("buoyStationFetchStarted")
    public static let buoyStationsUpdatedNotification = Notification.Name("buoyStationsUpdated")
    public static let buoyStationsUpdateFailedNotification = Notification.Name("buoyStationUpdateFailed")
    
    // Buoy data notifications
    public static let buoyDataFetchStartedNotification = Notification.Name("buoyDataFetchStarted")
    public static let buoyDataUpdatedNotification = Notification.Name("buoyDataUpdated")
    public static let buoyDataUpdateFailedNotification = Notification.Name("buoyDataUpdateFailed")
    public static let buoyNextUpdateTimeUpdatedNotification = Notification.Name("buoyNextUpdateTimeUpdated")
    
    // Buoys
    public private(set) var buoys: [String:GTLRStation_ApiApiMessagesStationMessage]? = nil
    
    // Keys
    private let buoyFinderAPIKey = "AIzaSyDDlpruyR4OVCDCdkkbHHlysaKf51zkh68"
    
    private override init() {
        
    }
    
    // MARK: NSCoding
    public required init?(coder aDecoder: NSCoder) {
        if let savedBuoys = aDecoder.decodeObject(forKey: "buoys") as? [String:GTLRStation_ApiApiMessagesStationMessage] {
            self.buoys = savedBuoys
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.buoys, forKey: "buoys")
    }
    
    public func isBuoyIdValid(buoyID: String) -> Bool {
        return self.buoys?[buoyID] != nil
    }
    
    // Fetching
    public func fetchBuoyStations() {
        let stationsQuery = GTLRStationQuery_Stations.query()
        let service = GTLRStationService()
        service.apiKey = buoyFinderAPIKey
        service.executeQuery(stationsQuery) { (ticket, obj, err) in
            if err != nil {
                NotificationCenter.default.post(name: BuoyModel.buoyStationsUpdateFailedNotification, object: nil)
                return
            }
            
            let rawBuoys = (obj as? GTLRStation_ApiApiMessagesStationsMessage)?.stations
            self.buoys = rawBuoys?.reduce([String:GTLRStation_ApiApiMessagesStationMessage]()) {
                dict, station in
                
                var newDict = dict
                newDict[station.stationId!] = station
                return newDict
            }
            NotificationCenter.default.post(name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
        }
    }
    
    public func fetchLatestBuoyData(stationId: String, units: String, dataType: String? = nil) {
        let latestDataQuery = GTLRStationQuery_Data.query(withUnits: units, stationId: stationId)
        if let dType = dataType {
            latestDataQuery.dataType = dType
        }
        let service = GTLRStationService()
        service.apiKey = buoyFinderAPIKey
        service.executeQuery(latestDataQuery) { (ticket, response, error) in
            if error != nil {
                // TODO: Notify failure?
                return;
            }
            
            // TODO: Parse out depending on the data type of the fetch etc
        }
    }
    
    public func fetchLatestDataForBuoys(ids: [String]) {
        ids.forEach { (stationId) in
            if let buoy = self.buoys?[stationId] {
                // TODO
            }
        }
    }
    
    public func nearbyBuoys(location: GTLRStation_ApiApiMessagesLocationMessage, radius: Double, units: String) -> [GTLRStation_ApiApiMessagesStationMessage] {
        if let resolvedBuoys = self.buoys {
            return resolvedBuoys.filter({ (arg) -> Bool in
                let (_, value) = arg
                return value.location!.distance(location: location, units: units) < radius
            }).map({ (arg) -> GTLRStation_ApiApiMessagesStationMessage in
                let (_, value) = arg
                return value
            }).sorted(by: { (buoy1, buoy2) -> Bool in
                return buoy1.location!.distance(location: location, units: units) < buoy2.location!.distance(location: location, units: units)
            })
        } else {
            return []
        }
    }
}
