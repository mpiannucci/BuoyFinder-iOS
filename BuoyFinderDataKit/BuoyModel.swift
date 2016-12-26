//
//  BuoyModel.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/14/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

class BuoyModel: NSObject {
    
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
    internal required init?(coder aDecoder: NSCoder) {
        if let savedBuoys = aDecoder.decodeObject(forKey: "buoys") as? [String:Buoy] {
            self.buoys = savedBuoys
        }
    }
    
    public func encode(with aCoder: NSCoder) {
        aCoder.encode(self.buoys, forKey: "buoys")
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
    
}
