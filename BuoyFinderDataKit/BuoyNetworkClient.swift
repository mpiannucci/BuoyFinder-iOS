//
//  BuoyNetworkClient.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

class BuoyNetworkClient: NSObject {
    
    public static func fetchAllBuoys(callback: @escaping ([Buoy]?) -> Void) {
        let allStationsURL = URL(string: "https://buoyfinder.appspot.com/api/stations")!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: allStationsURL) {
            (rawData, response, error) -> Void in
            
            if error != nil {
                callback(nil)
            }
            
            // Parse the buoys and return them? IDKKKKK
            let json = JSON(data: rawData!)
            let buoys = json["Stations"].arrayValue.map({
                (rawStation: JSON) -> Buoy in
                Buoy(jsonData: rawStation)
            })
            
            callback(buoys)
        }
        fetchTask.resume()
    }
}
