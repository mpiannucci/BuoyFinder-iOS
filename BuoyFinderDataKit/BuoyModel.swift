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
    
    // Notifications
    public static let buoyStationsFetchStartedNotification = Notification.Name("buoyStationFetchStarted")
    public static let buoyStationsUpdatedNotification = Notification.Name("buoyStationsUpdated")
    public static let buoyStationsUpdateFailedNotification = Notification.Name("buoyStationUpdateFailed")
    
    // Buoys
    public private(set) var buoys: [String:Buoy]? = nil
    
    private override init() {
        
    }
    
    // MARK: NSCoding
    public required init?(coder aDecoder: NSCoder) {
        if let savedBuoys = aDecoder.decodeObject(forKey: "buoys") as? [String:Buoy] {
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
        BuoyNetworkClient.fetchAllBuoys {
            (newBuoys) in
            if newBuoys == nil {
                NotificationCenter.default.post(name: BuoyModel.buoyStationsUpdateFailedNotification, object: nil)
                return
            }
            
            self.buoys = newBuoys
            NotificationCenter.default.post(name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
        }
    }
    
    public func fetchLatestDataForBuoys(ids: [String]) {
        ids.forEach { (stationId) in
            if let buoy = self.buoys?[stationId] {
                buoy.fetchAllDataIfNeeded()
            }
        }
    }
    
    public func nearbyBuoys(location: Location, radius: Double, units: Units) -> [Buoy] {
        if let resolvedBuoys = self.buoys {
            return resolvedBuoys.filter({ (key, value) -> Bool in
                return value.location.distance(location: location, units: units) < radius
            }).map({ (key, value) -> Buoy in
                return value
            }).sorted(by: { (buoy1, buoy2) -> Bool in
                return buoy1.location.distance(location: location, units: units) < buoy2.location.distance(location: location, units: units)
            })
        } else {
            return []
        }
    }
}
