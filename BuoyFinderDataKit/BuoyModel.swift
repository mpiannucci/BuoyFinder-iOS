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
    public private(set) var buoys: [String:GTLRStation_ApiApiMessagesStationMessage] = [:]
    
    // Cache
    private var buoyFetchCache: [String:GTLRStation_ApiApiMessagesDataMessage] = [:]
    private var buoyFetchCounter: [String:DispatchGroup] = [:]
    private var buoyFetchHistory: [String:Date] = [:]
    
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
        return self.buoys[buoyID] != nil
    }
    
    // Fetching
    public func fetchBuoyStations() {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        let stationsQuery = GTLRStationQuery_Stations.query()
        let service = GTLRStationService()
        service.apiKey = buoyFinderAPIKey
        service.executeQuery(stationsQuery) { (ticket, obj, err) in
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            if err != nil {
                NotificationCenter.default.post(name: BuoyModel.buoyStationsUpdateFailedNotification, object: nil)
                return
            }
            
            let rawBuoys = (obj as? GTLRStation_ApiApiMessagesStationsMessage)?.stations
            self.buoys = (rawBuoys?.reduce([String:GTLRStation_ApiApiMessagesStationMessage]()) {
                dict, station in
                
                var newDict = dict
                newDict[station.stationId!] = station
                return newDict
                })!
            NotificationCenter.default.post(name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
        }
    }
    
    public func fetchLatestBuoyData(stationId: String, units: String, dataType: String? = nil) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        
        if let fetchGroup = self.buoyFetchCounter[stationId] {
            fetchGroup.enter()
        }
        
        let latestDataQuery = GTLRStationQuery_Data.query(withUnits: units, stationId: stationId)
        if let dType = dataType {
            latestDataQuery.dataType = dType
        }
        let service = GTLRStationService()
        service.apiKey = buoyFinderAPIKey
        service.executeQuery(latestDataQuery) { (ticket, response, error) in
            objc_sync_enter(self)
            defer { objc_sync_exit(self) }
            
            guard error == nil, let newData = response as? GTLRStation_ApiApiMessagesDataMessage else {
                print(error!)
                
                if let fetchGroup = self.buoyFetchCounter[stationId] {
                    fetchGroup.leave()
                }
                return
            }
            
            // Leave the dispatch group
            if let fetchGroup = self.buoyFetchCounter[stationId] {
                if self.buoyFetchCache[stationId] == nil {
                    self.buoyFetchCache[stationId] = newData
                } else {
                    self.buoyFetchCache[stationId]?.mergeData(newData: newData, dataType: dataType ?? "")
                }
                fetchGroup.leave()
            } else {
                self.buoys[stationId]?.addData(newData: newData)
            }
        }
    }
    
    public func fetchAllLatestBuoyData(stationId: String, units: String) {
        guard self.buoyFetchCounter[stationId] == nil, doesBuoyNeedUpdate(stationId: stationId, units: units) else {
            return
        }
        
        NotificationCenter.default.post(name: BuoyModel.buoyDataFetchStartedNotification, object: nil, userInfo: ["stationId": stationId])
        
        self.buoyFetchCounter[stationId] = DispatchGroup()
        
        self.fetchLatestBuoyData(stationId: stationId, units: units, dataType: kGTLRStationDataTypeSpectra)
        self.fetchLatestBuoyData(stationId: stationId, units: units, dataType: kGTLRStationDataTypeWeather)
        
        self.buoyFetchCounter[stationId]?.notify(queue: DispatchQueue.main, execute: {
            // Finished multiple data fetch... cleanup
            var success = false
            if let newData = self.buoyFetchCache[stationId] {
                self.buoys[stationId]?.addData(newData: newData)
                self.buoyFetchHistory[stationId] = Date()
                success = true
            } else {
                success = false
            }
            self.buoyFetchCache.removeValue(forKey: stationId)
            self.buoyFetchCounter.removeValue(forKey: stationId)
            
            if success {
                NotificationCenter.default.post(name: BuoyModel.buoyDataUpdatedNotification, object: nil, userInfo: ["stationId": stationId])
            } else {
                NotificationCenter.default.post(name: BuoyModel.buoyDataUpdateFailedNotification, object: nil, userInfo: ["stationId": stationId])
            }
        })
    }
    
    public func doesBuoyNeedUpdate(stationId: String, units: String) -> Bool {
        guard let lastUpdateTime = self.buoyFetchHistory[stationId], let oldUnits = self.buoys[stationId]?.data?.first?.units?.unit else {
            return true
        }
        
        if oldUnits != units {
            return true
        }
        
        return lastUpdateTime.timeIntervalSinceNow > 30*60
    }
    
    public func isBuoyDataFetching(stationId: String) -> Bool {
        return self.buoyFetchCounter[stationId] != nil
    }
    
    public func nearbyBuoys(location: GTLRStation_ApiApiMessagesLocationMessage, radius: Double, units: String) -> [GTLRStation_ApiApiMessagesStationMessage] {
        return self.buoys.filter({ (arg) -> Bool in
            let (_, value) = arg
            return value.location!.distance(location: location, units: units) < radius
        }).map({ (arg) -> GTLRStation_ApiApiMessagesStationMessage in
            let (_, value) = arg
            return value
        }).sorted(by: { (buoy1, buoy2) -> Bool in
            return buoy1.location!.distance(location: location, units: units) < buoy2.location!.distance(location: location, units: units)
        })
    }
}
