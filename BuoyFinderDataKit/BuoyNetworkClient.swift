//
//  BuoyNetworkClient.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import Foundation
import SwiftyJSON

public class BuoyNetworkClient: NSObject {
    
    public static func fetchAllBuoys(callback: @escaping ([String:Buoy]?) -> Void) {
        let allStationsURL = URL(string: "https://buoyfinder.appspot.com/api/stations")!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: allStationsURL) {
            (rawData, response, error) -> Void in
            
            // Handle Errors
            if checkErrors(data: rawData, response: response, error: error) != nil {
                callback(nil)
                return
            }
            
            // Parse the buoys and return them? IDKKKKK
            let json = JSON(data: rawData!)
            let buoys = json["Stations"].arrayValue.map({
                (rawStation: JSON) -> Buoy in
                Buoy(jsonData: rawStation)
            }).reduce([String:Buoy]()) {
                dict, newBuoy in
                var newDict = dict
                newDict[newBuoy.stationID] = newBuoy
                return newDict
            };
            
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
                return
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
                return
            }
            
            // Add the new station info to the existing Buoy
            let json = JSON(data: rawData!)
            buoy.loadInfo(jsonData: json)
            
            // Let the listener know we are finished without errors
            callback(nil)
        }
        fetchTask.resume()
    }
    
    public static func fetchLatestBuoyWaveData(buoy: Buoy, callback: @escaping (FetchError?) -> Void) {
        let stationInfoURL = URL(string: "https://buoyfinder.appspot.com/api/latest/wave/charts/" + buoy.stationID)!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: stationInfoURL) {
            (rawData, response, error) -> Void in
            
            // Handle Errors
            if let fetchError = checkErrors(data: rawData, response: response, error: error) {
                callback(fetchError)
                return
            }
            
            // Add the latest wave data to the existing Buoy
            let json = JSON(data: rawData!)
            buoy.loadLatestWaveData(allJsonData: json)
            
            // Let the listener know we are finished without errors
            callback(nil)
        }
        fetchTask.resume()
    }
    
    public static func fetchLatestBuoyWeatherData(buoy: Buoy, callback: @escaping (FetchError?) -> Void) {
        let stationInfoURL = URL(string: "https://buoyfinder.appspot.com/api/latest/weather/" + buoy.stationID)!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: stationInfoURL) {
            (rawData, response, error) -> Void in
            
            // Handle Errors
            if let fetchError = checkErrors(data: rawData, response: response, error: error) {
                callback(fetchError)
                return
            }
            
            // Add the latest weather data to the existing Buoy
            let json = JSON(data: rawData!)
            let buoyDataJSON = json["BuoyData"]
            buoy.loadLatestWeatherData(jsonData: buoyDataJSON)
            
            // Let the listener know we are finished without errors
            callback(nil)
        }
        fetchTask.resume()
    }
    
    public static func fetchLatestBuoyData(buoy: Buoy, callback: @escaping (FetchError?) -> Void) {
        let stationInfoURL = URL(string: "https://buoyfinder.appspot.com/api/latest/" + buoy.stationID)!
        let session = URLSession.shared
        let fetchTask = session.dataTask(with: stationInfoURL) {
            (rawData, response, error) -> Void in
            
            // Handle Errors
            if let fetchError = checkErrors(data: rawData, response: response, error: error) {
                callback(fetchError)
                return
            }
            
            // Add the latest data to the existing Buoy
            let json = JSON(data: rawData!)
            let buoyDataJSON = json["BuoyData"]
            buoy.loadLatestData(jsonData: buoyDataJSON)
            
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
    
    public enum FetchError: Error {
        case urlSessionError
        case noDataReceived
        case badResponseCode
    }
}
