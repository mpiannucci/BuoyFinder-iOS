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
    public var favoriteBuoyIds: [String] = []
    public private(set) var units: String = kGTLRStationUnitsMetric
    
    public enum InitialView: String {
        case explore = "explore"
        case favorites = "favorites"
        case defaultBuoy = "default buoy"
    }
    public private(set) var initialView: InitialView = .explore

    public private(set) var defaultBuoyId: String = ""
    public var defaultbuoy: GTLRStation_ApiApiMessagesStationMessage? {
        get {
            return BuoyModel.sharedModel.buoys[self.defaultBuoyId]
        }
    }
    
    public private(set) var todayVariable: BuoyDataItem.Variable = .waves
    
    // Data cache states
    private let userDefaults = UserDefaults(suiteName: "group.com.mpiannucci.BuoyFinder")
    private var userRef: DatabaseReference? = nil
    private var latestSnapshot: DataSnapshot? = nil
    
    // Settings keys
    let favoriteBuoysKey = "favoriteBuoys"
    let unitsKey = "units"
    let initialViewKey = "initialView"
    let defaultBuoyKey = "defaultBuoy"
    let todayVariableKey = "todayVariable"
    
    private init() {
        self.loadFromLocal()
        
        Auth.auth().addStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.resetLocalDefaults()
                
                self.userRef = Database.database().reference(withPath: "user/" + user!.uid)
                
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
                
                self.loadFromLocal()
            }
            
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        })
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.newBuoysLoaded), name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
    }
    
    public func deleteUser() {
        if let user = self.userRef {
            user.removeAllObservers()
            user.removeValue()
            self.latestSnapshot = nil
        }
    }
    
    public func changeUnits(newUnits: String) {
        if self.units == newUnits {
            return
        }
        
        self.units = newUnits
        self.saveUnits()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func changeInitialView(newInitialView: InitialView) {
        if self.initialView == newInitialView {
            return
        }
        
        self.initialView = newInitialView
        self.saveInitialView()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func changeDefaultBuoy(buoyId: String) {
        if self.defaultBuoyId == buoyId {
            return
        }
        
        self.defaultBuoyId = buoyId
        self.saveDefaultBuoy()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func changeTodayVariable(newVariable: BuoyDataItem.Variable) {
        if self.todayVariable == newVariable {
            return
        }
        
        self.todayVariable = newVariable
        self.saveTodayVariable()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func addFavoriteBuoy(newBuoyId: String) {
        if self.favoriteBuoyIds.contains(newBuoyId) {
            return
        }
        
        self.favoriteBuoyIds.append(newBuoyId)
        self.saveFavoriteBuoys()
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    public func removeFavoriteBuoy(buoyId: String) {
        if let index = self.favoriteBuoyIds.index(of: buoyId) {
            self.favoriteBuoyIds.remove(at: index)
            self.saveFavoriteBuoys()
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        }
    }
    
    public func moveFavoriteBuoy(currentIndex: Int, newIndex: Int) {
        self.favoriteBuoyIds.insert(self.favoriteBuoyIds.remove(at: currentIndex), at: newIndex)
        self.saveFavoriteBuoys()
    }
    
    public func isBuoyAFavorite(buoyId: String) -> Bool {
        return self.favoriteBuoyIds.contains(buoyId)
    }
    
    @objc private func newBuoysLoaded() {
        if self.userRef != nil {
            self.loadFromRemote()
        } else {
            self.loadFromLocal()
        }
    }
    
    private func loadFromRemote() {
        if self.latestSnapshot == nil {
            return
        }
        
        var changed = false
        
        if let newUnits = self.latestSnapshot?.childSnapshot(forPath: self.unitsKey).value as? String {
            if newUnits != self.units {
                self.units = newUnits
                changed = true
            }
        }
        
        if let newInitialView = self.latestSnapshot?.childSnapshot(forPath: self.initialViewKey).value as? String {
            if newInitialView != self.initialView.rawValue {
                self.initialView = InitialView(rawValue: newInitialView)!
                changed = true
            }
        }
        
        if let newDefaultBuoyID = self.latestSnapshot?.childSnapshot(forPath: self.defaultBuoyKey).value as? String {
            if newDefaultBuoyID != self.defaultBuoyId {
                self.defaultBuoyId = newDefaultBuoyID
                changed = true
            }
        }
        
        if let newTodayVariable = self.latestSnapshot?.childSnapshot(forPath: self.todayVariableKey).value as? String {
            if newTodayVariable != self.todayVariable.rawValue {
                self.todayVariable = BuoyDataItem.Variable(rawValue: newTodayVariable)!
                changed = true
            }
        }
        
        if let rawFavoriteBuoys = self.latestSnapshot?.childSnapshot(forPath: self.favoriteBuoysKey).value as? NSArray {
            let newFavoriteBuoys = rawFavoriteBuoys as! [String]
            for newFavoriteBuoyID in newFavoriteBuoys {
                if self.favoriteBuoyIds.contains(newFavoriteBuoyID) {
                    continue
                }
                
                self.favoriteBuoyIds.append(newFavoriteBuoyID)
                changed = true
            }
            
            let currentFavorites = self.favoriteBuoyIds
            for currentFavorite in currentFavorites.reversed() {
                if newFavoriteBuoys.contains(currentFavorite) {
                    continue
                }
                
                if let index = currentFavorites.index(of: currentFavorite) {
                    self.favoriteBuoyIds.remove(at: index)
                    changed = true
                }
            }
        }
        
        self.saveData()
        
        if changed {
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        }
    }
    
    private func loadFromLocal() {
        var changed = false
        
        
        if let newUnits = userDefaults?.value(forKey: self.unitsKey) as? String {
            if newUnits != self.units {
                self.units = newUnits
                changed = true
            }
        }
        
        if let newInitialView = userDefaults?.value(forKey: self.initialViewKey) as? String {
            if newInitialView != self.initialView.rawValue {
                self.initialView = InitialView(rawValue: newInitialView)!
                changed = true
            }
        }
        
        if let newDefaultBuoyID = userDefaults?.value(forKey: self.defaultBuoyKey) as? String {
            if newDefaultBuoyID != self.defaultBuoyId {
                self.defaultBuoyId = newDefaultBuoyID
                changed = true
            }
        }
        
        if let newTodayVariable = userDefaults?.value(forKey: self.todayVariableKey) as? String {
            if newTodayVariable != self.todayVariable.rawValue {
                self.todayVariable = BuoyDataItem.Variable(rawValue: newTodayVariable)!
                changed = true
            }
        }
        
        if let newFavoriteBuoyIDs = userDefaults?.value(forKey: self.favoriteBuoysKey) as? [String] {
            for newFavoriteBuoyID in newFavoriteBuoyIDs {
                if self.favoriteBuoyIds.contains(newFavoriteBuoyID) {
                    continue
                }
                
                self.favoriteBuoyIds.append(newFavoriteBuoyID)
                changed = true
            }
            
            let currentFavorites = self.favoriteBuoyIds
            for currentFavorite in currentFavorites.reversed() {
                if newFavoriteBuoyIDs.contains(currentFavorite) {
                    continue
                }
                
                if let index = currentFavorites.index(of: currentFavorite) {
                    self.favoriteBuoyIds.remove(at: index)
                    changed = true
                }
            }
        }
        
        
        if changed {
            NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
        }
    }
    
    private func saveFavoriteBuoys() {
        if self.userRef != nil {
            self.userRef!.child(self.favoriteBuoysKey).setValue(self.favoriteBuoyIds as NSArray)
        } else {
            self.userDefaults?.setValue(self.favoriteBuoyIds, forKey: self.favoriteBuoysKey)
        }
    }
    
    private func saveUnits() {
        self.userDefaults?.setValue(self.units, forKey: self.unitsKey)
        if self.userRef != nil {
            self.userRef!.child(self.unitsKey).setValue(self.units as NSString)
        }
    }
    
    private func saveInitialView() {
        self.userDefaults?.setValue(self.initialView.rawValue, forKey: self.initialViewKey)
        if self.userRef != nil {
            self.userRef!.child(self.initialViewKey).setValue(self.initialView.rawValue as NSString)
        }
    }
    
    private func saveDefaultBuoy() {
        self.userDefaults?.setValue(self.defaultBuoyId, forKey: self.defaultBuoyKey)
        if self.userRef != nil {
            self.userRef!.child(self.defaultBuoyKey).setValue(self.defaultBuoyId as NSString)
        }
    }
    
    private func saveTodayVariable() {
        self.userDefaults?.setValue(self.todayVariable.rawValue, forKey: self.todayVariableKey)
        if self.userRef != nil {
            self.userRef!.child(self.todayVariableKey).setValue(self.todayVariable.rawValue as NSString)
        }
    }
    
    private func saveData() {
        self.saveFavoriteBuoys()
        self.saveDefaultBuoy()
        self.saveUnits()
        self.saveInitialView()
        self.saveTodayVariable()
    }
    
    private func resetLocalDefaults() {
        self.units = kGTLRStationUnitsMetric
        self.initialView = .explore
        self.favoriteBuoyIds = []
        self.defaultBuoyId = ""
        self.todayVariable = .waves
        saveData()
    }
    
    @objc private func userDefaultsChanged(notification: NSNotification) {
        NotificationCenter.default.post(name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
}
