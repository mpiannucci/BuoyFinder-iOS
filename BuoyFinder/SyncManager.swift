//
//  SyncManager.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 2/20/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import Foundation
import BuoyFinderDataKit
import Firebase


public class SyncManager {
    
    public static let instance = SyncManager()
    
    // Notifications
    public static let syncDataUpdatedNotification = Notification.Name("syncDataUpdated")
    
    // Data variables
    public private(set) var favoriteBuoys: [Buoy] = []
    public var favoriteBuoyIDs: [String] {
        get {
            return self.favoriteBuoys.map({ (buoy) -> String in
                return buoy.stationID
            })
        }
    }
    public private(set) var units: Units = Units.metric
    
    // Data cache states
    private let userDefaults = UserDefaults(suiteName: "group.com.mpiannucci.BuoyFinder")
    private var userRef: FIRDatabaseReference? = nil
    private var latestSnapshot: FIRDataSnapshot? = nil
    
    // Settings keys
    let favoriteBuoysKey = "favoriteBuoys"
    let unitsKey = "units"
    
    private init() {
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.favoriteBuoys.removeAll()
                self.userRef = FIRDatabase.database().reference(withPath: "user/" + user!.uid)
                self.userRef?.observe(.value, with: {
                    snapshot in
                    self.latestSnapshot = snapshot
                    self.loadFromRemote()
                })
            } else {
                // Logged out
                if self.userRef != nil {
                    self.userRef?.removeAllObservers()
                    self.userRef = nil
                    self.latestSnapshot = nil
                }
                
                self.favoriteBuoys.removeAll()
                self.loadFromLocal()
            }
            
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        })
    }
    
    public func changeUnits(newUnits: Units) {
        if self.units == newUnits {
            return
        }
        
        self.units = newUnits
        self.saveUnits()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func addFavoriteBuoy(newBuoy: Buoy) {
        if self.favoriteBuoys.contains(where: { (buoy) -> Bool in
            buoy.stationID == newBuoy.stationID
        }) {
            return
        }
        
        self.favoriteBuoys.append(newBuoy)
        self.saveFavoriteBuoys()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func addFavoriteBuoy(newBuoyID: String) {
        if let buoy = BuoyModel.sharedModel.buoys?[newBuoyID] {
            addFavoriteBuoy(newBuoy: buoy)
        }
    }
    
    public func removeFavoriteBuoy(buoy: Buoy) {
        if let index = self.favoriteBuoys.index(where: { (oldBuoy) -> Bool in
            oldBuoy.stationID == buoy.stationID
        }) {
            self.favoriteBuoys.remove(at: index)
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        }
    }
    
    public func remoteFavoriteBuoy(buoyID: String) {
        if let buoy = BuoyModel.sharedModel.buoys?[buoyID] {
            removeFavoriteBuoy(buoy: buoy)
        }
    }
    
    public func isBuoyAFavorite(buoy: Buoy) -> Bool {
        return self.favoriteBuoys.contains(where: { (oldBuoy) -> Bool in
            return oldBuoy.stationID == buoy.stationID
        })
    }
    
    private func loadFromRemote() {
        if self.latestSnapshot == nil {
            return
        }
        
        var changed = false
        
        if let newUnits = self.latestSnapshot?.childSnapshot(forPath: self.unitsKey).value as? String {
            if newUnits != self.units.rawValue {
                self.units = Units(rawValue: newUnits)!
                changed = true
            }
        }
        
        if let newFavoriteBuoys = self.latestSnapshot?.childSnapshot(forPath: self.favoriteBuoysKey).value as? [String] {
            for favoriteBuoyID in newFavoriteBuoys {
                if !self.favoriteBuoys.contains(where: { (buoy) -> Bool in
                    buoy.stationID == favoriteBuoyID
                }) {
                    if let newBuoy = BuoyModel.sharedModel.buoys?[favoriteBuoyID] {
                        self.favoriteBuoys.append(newBuoy)
                        changed = true
                    }
                }
            }
        }
        
        if changed {
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        }
    }
    
    private func loadFromLocal() {
        var changed = false
        
        
        if let newUnits = userDefaults?.value(forKey: self.unitsKey) as? String {
            if newUnits != self.units.rawValue {
                self.units = Units(rawValue: newUnits)!
                changed = true
            }
        }
        
        if let newFavoriteBuoyIDs = userDefaults?.value(forKey: self.favoriteBuoysKey) as? [String] {
            for favoriteBuoyID in newFavoriteBuoyIDs {
                if !self.favoriteBuoys.contains(where: { (buoy) -> Bool in
                    buoy.stationID == favoriteBuoyID
                }) {
                    if let newBuoy = BuoyModel.sharedModel.buoys?[favoriteBuoyID] {
                        self.favoriteBuoys.append(newBuoy)
                        changed = true
                    }
                }
            }
        }
        
        
        if changed {
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        }
    }
    
    private func saveFavoriteBuoys() {
        if self.userRef != nil {
            self.userRef!.child(self.favoriteBuoysKey).setValue(self.favoriteBuoyIDs as NSArray)
        } else {
            self.userDefaults?.setValue(self.favoriteBuoyIDs, forKey: self.favoriteBuoysKey)
        }
    }
    
    private func saveUnits() {
        if self.userRef != nil {
            self.userRef!.child(self.unitsKey).setValue(self.units.rawValue as NSString)
        } else {
            self.userDefaults?.setValue(self.units.rawValue, forKey: self.unitsKey)
        }
    }
    
    private func saveData() {
        self.saveFavoriteBuoys()
        self.saveUnits()
    }
    
    @objc private func userDefaultsChanged(notification: NSNotification) {
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
}
