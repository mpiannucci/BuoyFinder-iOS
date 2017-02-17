//
//  ExploreViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import UIKit
import GoogleMaps
import SwiftLocation
import BuoyFinderDataKit

class ExploreViewController: UIViewController {
    
    @IBOutlet public weak var mapView: GMSMapView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the map settings
        self.mapView.delegate = self
        self.mapView.mapType = GMSMapViewType.hybrid
        self.mapView.settings.setAllGesturesEnabled(true)
        self.mapView.settings.compassButton = true
        self.mapView.settings.myLocationButton = true
        
        // Set the default camera to be directly over america
        self.mapView.camera = GMSCameraPosition.camera(withLatitude: 39.8, longitude: -98.6, zoom: 3)
        
        // Try and get the users location to give a better view of buoys around them
        let locationRequest = Location.getLocation(withAccuracy: .city, onSuccess: { foundLocation in
            // Change the view of the map to center around the location
            self.mapView.camera = GMSCameraPosition.camera(withTarget: foundLocation.coordinate, zoom: 6)
        }) { (lastValidLocation, error) in
            // Do nothing
        }
        locationRequest.start()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(ExploreViewController.updateBuoyStations), name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    func updateBuoyStations() {
        DispatchQueue.main.sync {
            if let stations = BuoyModel.sharedModel.buoys {
                for (_, station) in stations {
                    let marker = GMSMarker()
                    marker.position = CLLocation(latitude: station.location.latitude, longitude: station.location.longitude).coordinate
                    marker.title = station.name
                    marker.snippet = "Station: " + station.stationID + ", " + station.program!
                    marker.map = mapView
                }
            }
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let selectedStation = parseStationID(snippet: self.mapView.selectedMarker!.snippet!)
        if let buoyView = segue.destination as? BuoyViewController {
            buoyView.buoy = BuoyModel.sharedModel.buoys?[selectedStation]
            buoyView.buoy?.fetchAllLatestData()
        }
    }
    
    func parseStationID(snippet: String) -> String {
        return snippet.components(separatedBy: ",")[0].components(separatedBy: ":")[1].trimmingCharacters(in: .whitespacesAndNewlines)
    }

}

// GSMapViewDelegate
extension ExploreViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, didTapInfoWindowOf marker: GMSMarker) {
        // Navigate to buoy page of the given marker
        self.performSegue(withIdentifier: "exploreShowBuoySegue", sender: self)
    }
}
