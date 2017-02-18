//
//  FavoritesManager.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 2/18/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import Foundation
import Firebase
import BuoyFinderDataKit

class FavoritesManager {
    
    public static let instance = FavoritesManager()
    public var favoriteBuoys: [Buoy] = []
    
    private init() {
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            // TODO: Observe the authentication status
        })
    }
    
    public func addFavoriteBuoy(id: String) {
        
    }
    
    public func addFavoriteBuoy(buoy: Buoy) {
        
    }
}
