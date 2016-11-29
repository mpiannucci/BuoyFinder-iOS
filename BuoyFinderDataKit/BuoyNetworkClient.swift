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
            (data, response, error) -> Void in
            
            if error != nil {
                callback(nil)
            }
            
            // TODO: Parse the buoys nad return them? IDKKKKK
        }
        fetchTask.resume()
    }
}
