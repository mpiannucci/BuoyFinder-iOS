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
            
            // Handle Errors
            if checkErrors(data: rawData, response: response, error: error) != nil {
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
    
    public static func fetchBuoyStationInfo(stationID: String, callback: @escaping (Buoy?) -> Void) {
        let stationInfoURL = URL(string: "https://buoyfinder.appspot.com/api/stationinfo/" + stationID)!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: stationInfoURL) {
            (rawData, response, error) -> Void in
            
            // Handle Errors
            if checkErrors(data: rawData, response: response, error: error) != nil {
                callback(nil)
            }
            
            // Add the new station info to the existing Buoy
            let json = JSON(data: rawData!)
            let buoy = Buoy(jsonData: json)
            
            // Let the listener know we are finished without errors
            callback(buoy)
        }
        fetchTask.resume()
    }
    
    public static func fetchBuoyStationInfo(buoy: Buoy, callback: @escaping (FetchError?) -> Void) {
        let stationInfoURL = URL(string: "https://buoyfinder.appspot.com/api/stationinfo/" + buoy.stationID)!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: stationInfoURL) {
            (rawData, response, error) -> Void in
            
            // Handle Errors
            if let fetchError = checkErrors(data: rawData, response: response, error: error) {
                callback(fetchError)
            }
            
            // Add the new station info to the existing Buoy
            let json = JSON(data: rawData!)
            buoy.loadInfo(jsonData: json)
            
            // Let the listener know we are finished without errors
            callback(nil)
        }
        fetchTask.resume()
    }
    
    private static func checkErrors(data: Data?, response: URLResponse?, error: Error?) -> FetchError? {
        var fetchError: FetchError?
        
        if error != nil {
            fetchError = FetchError.urlSessionError
        } else if data == nil {
            fetchError = FetchError.noDataReceived
        }
        
        // If the status code is not 200 exit early
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                fetchError = FetchError.badResponseCode
            }
        }
        
        return fetchError
    }
    
    enum FetchError: Error {
        case urlSessionError
        case noDataReceived
        case badResponseCode
    }
}
