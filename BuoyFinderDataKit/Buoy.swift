//
//  Buoy.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation

class Buoy: NSObject {
    
    // Required
    var stationID: String
    var location: Location
    
    // Optional
    var owner: String?
    var program: String?
    var buoyType: String?
    var active: String?
    var currents: String?
    var waterQuality: String?
    var dart: String?
    
    // Data
    var latestData: [BuoyDataItem]?
    
    init(stationID_: String, location_: Location) {
        self.stationID = stationID_
        self.location = location_
        
        super.init()
    }
}
