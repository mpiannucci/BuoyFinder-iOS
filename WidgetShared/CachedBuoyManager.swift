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
    
    public var defaultBuoy: Buoy? = nil
    
    public init() {
        self.restoreFromCache()
    }
    
    public func checkDefaultBuoyID(buoyID: String) -> Bool {
        if let buoy = self.defaultBuoy {
            if buoy.stationID == buoyID{
                return true
            }
        }
        
        return false
    }
    
    public func getDefaultBuoy(buoyID: String, updateHandler: @escaping ((Buoy?) -> Void)) {
        BuoyNetworkClient.fetchBuoyStationInfo(stationID: buoyID) { (buoy) in
            self.defaultBuoy = buoy
            if let defBuoy = self.defaultBuoy {
                BuoyNetworkClient.fetchLatestBuoyData(buoy: defBuoy) {
                    (_) in
                    updateHandler(defBuoy)
                }
            }
        }
    }
    
    public func fetchUpdate(forceUpdate: Bool, updateHandler: @escaping ((Buoy?) -> Void)) {
        var needsUpdate = forceUpdate
        
        if let buoy = self.defaultBuoy {
            if let nextUpdateTime = buoy.nextUpdateTime {
                if Date.init() > nextUpdateTime {
                    needsUpdate = true
                } else if buoy.latestData == nil {
                    needsUpdate = true
                }
            } else if buoy.needsUpdate {
                needsUpdate = true
            }
            
            if needsUpdate {
                BuoyNetworkClient.fetchLatestBuoyData(buoy: buoy, callback: { (_) in
                    self.saveToCache()
                    updateHandler(buoy)
                    
                    BuoyNetworkClient.fetchNextUpdateTime(buoy: buoy, callback: { (_) in
                        self.saveToCache()
                    })
                })
                
            }
        } else {
            updateHandler(self.defaultBuoy)
        }
    }
    
    public func restoreFromCache() {
        let defaults = UserDefaults.standard
        if let rawDefaultBuoy = defaults.object(forKey: "defaultBuoyCache") {
            self.defaultBuoy = NSKeyedUnarchiver.unarchiveObject(with: rawDefaultBuoy as! Data) as? Buoy
        }
    }
    
    public func saveToCache() {
        let defaults = UserDefaults.standard
        if let buoy = self.defaultBuoy {
            defaults.set(NSKeyedArchiver.archivedData(withRootObject: buoy), forKey: "defaultBuoyCache")
        }
    }
    
}
