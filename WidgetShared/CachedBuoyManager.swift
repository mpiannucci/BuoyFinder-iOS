//
//  CachedBuoyManager.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 5/16/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import Foundation
#if os(watchOS)
import BuoyFinderWatchDataKit
#else
import BuoyFinderDataKit
#endif

public class CachedBuoyManager {
    
    public var defaultBuoy: GTLRStation_ApiApiMessagesStationMessage? = nil
    public var defaultUnits: String = kGTLRStationUnitsEnglish
    
    public init() {
        self.restoreFromCache()
    }
    
    public func checkDefaultBuoyID(buoyID: String) -> Bool {
        guard let buoy = defaultBuoy else {
            return false
        }
        
        if buoy.stationId == buoyID {
            return true
        } else {
            return false
        }
    }
    
    public func setDefaultUnits(newUnits: String) {
        self.defaultUnits = newUnits
    }
    
    public func getDefaultBuoy(buoyId: String, updateHandler: @escaping (GTLRStation_ApiApiMessagesDataMessage) -> Void) {
        BuoyModel.sharedModel.fetchBuoyStationInfo(stationId: buoyId ) { station in
            self.defaultBuoy = station
            
            // TODO: Get units from userdefaults
            self.fetchUpdate(forceUpdate: true, updateHandler: updateHandler)
        }
    }
    
    public func fetchUpdate(forceUpdate: Bool, updateHandler: @escaping (GTLRStation_ApiApiMessagesDataMessage) -> Void) {
        var needsUpdate = forceUpdate
        
        guard let buoy = self.defaultBuoy else {
            return
        }
    
        if let lastUpdateTime = buoy.latestUpdateTime, let _ = buoy.data?.first {
            needsUpdate = lastUpdateTime.timeIntervalSinceNow > 30*60
        } else {
            needsUpdate = true
        }
        
        if !needsUpdate {
            updateHandler(buoy.data!.first!)
            return
        }
        
        // TODO: Get the units from settings
        BuoyModel.sharedModel.fetchLatestBuoyData(stationId: buoy.stationId!, units: self.defaultUnits) { newData in
            self.defaultBuoy!.setData(newData: [newData])
            self.saveToCache()
            updateHandler(newData)
        }
    }
    
    public func restoreFromCache() {
        let defaults = UserDefaults.standard
        if let rawDefaultBuoy = defaults.object(forKey: "defaultBuoyCache") {
            self.defaultBuoy = NSKeyedUnarchiver.unarchiveObject(with: rawDefaultBuoy as! Data) as? GTLRStation_ApiApiMessagesStationMessage
        }
        if let rawDefaultUnit = defaults.object(forKey: "defaultUnitCache") {
            self.defaultUnits = NSKeyedUnarchiver.unarchiveObject(with: rawDefaultUnit as! Data) as! String!
        }
        defaults.synchronize()
    }
    
    public func saveToCache() {
        let defaults = UserDefaults.standard
        if let buoy = self.defaultBuoy {
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: buoy), forKey: "defaultBuoyCache")
        }
        defaults.set(NSKeyedArchiver.archivedData(withRootObject: self.defaultUnits), forKey: "defaultUnitCache")
        defaults.synchronize()
    }
    
}
