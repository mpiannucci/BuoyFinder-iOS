//
//  ExploreViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import SwiftLocation
import BuoyFinderDataKit

class ExploreViewController: UIViewController {
    
    @IBOutlet weak var exploreMapView: GMSMapView!
    @IBOutlet weak var nearbyBuoysTable: UITableView!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var nearbyBuoys: [GTLRStation_ApiApiMessagesStationMessage] = []
    
    var selectedBuoyStation: String = ""

    override func viewDidLoad() {
        super.viewDidLoad()

        // Setup the map settings
        self.exploreMapView.delegate = self
        self.exploreMapView.mapType = GMSMapViewType.hybrid
        self.exploreMapView.settings.setAllGesturesEnabled(true)
        self.exploreMapView.settings.compassButton = true
        self.exploreMapView.settings.myLocationButton = true
        
        // Set up the nearby buoys list and searching
        self.nearbyBuoysTable.dataSource = self
        self.nearbyBuoysTable.delegate = self
        
        // Set up the search controllers
        self.resultsViewController = GMSAutocompleteResultsViewController()
        self.resultsViewController?.delegate = self
        self.searchController = UISearchController(searchResultsController: resultsViewController)
        self.searchController?.searchResultsUpdater = resultsViewController
        self.searchController?.hidesNavigationBarDuringPresentation = false
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
    
        // Try and get the users location to give a better view of buoys around them
        let locationRequest = SwiftLocation.Location.getLocation(accuracy: .city, frequency: .oneShot, success: { (locRequest, foundLocation) -> (Void) in
            self.exploreMapView.camera = GMSCameraPosition.camera(withTarget: foundLocation.coordinate, zoom: 6)
            self.mapView(self.exploreMapView, didChange: self.exploreMapView.camera)
        }) { (locRequest, lastValidLocation, error) -> (Void) in
            self.exploreMapView.camera = GMSCameraPosition.camera(withLatitude: 39.8, longitude: -98.6, zoom: 3)
            self.mapView(self.exploreMapView, didChange: self.exploreMapView.camera)
        }
        locationRequest.resume()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.updateBuoyStations()
        NotificationCenter.default.addObserver(self, selector: #selector(ExploreViewController.updateBuoyStations), name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
        super.viewWillDisappear(animated)
    }
    
    func updateBuoyStations() {
        DispatchQueue.main.async {
            if let stations = BuoyModel.sharedModel.buoys {
                for (_, station) in stations {
                    let marker = GMSMarker()
                    marker.position = CLLocation(latitude: station.location!.latitude!.doubleValue, longitude: station.location!.longitude!.doubleValue).coordinate
                    marker.title = station.location!.name!
                    marker.snippet = "Station: " + station.stationId! + ", " + (station.program ?? "")
                    marker.map = self.exploreMapView
                }
            }
            
            self.mapView(self.exploreMapView, didChange: self.exploreMapView.camera)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let buoyView = segue.destination as? BuoyViewController {
            buoyView.buoy = BuoyModel.sharedModel.buoys?[selectedBuoyStation]
//            buoyView.buoy?.fetchAllDataIfNeeded()
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
        if let snippet = self.exploreMapView.selectedMarker?.snippet {
            self.selectedBuoyStation = parseStationID(snippet: snippet)
        }
        self.performSegue(withIdentifier: "exploreShowBuoySegue", sender: self)
    }

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        DispatchQueue.global().async {
            let location = GTLRStation_ApiApiMessagesLocationMessage()
            location.latitude = NSNumber.init(value: position.target.latitude)
            location.longitude = NSNumber.init(value: position.target.longitude)
            self.nearbyBuoys = BuoyModel.sharedModel.nearbyBuoys(location: location, radius: 120, units: SyncManager.instance.units)
            
            DispatchQueue.main.sync {
                self.nearbyBuoysTable.reloadData()
            }
        }
    }
}

// Google Places Autocompletion Delegate
extension ExploreViewController: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        self.exploreMapView.camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: 6)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

// Table View Delegate
extension ExploreViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Nearby Buoys"
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyBuoys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyBuoyCell", for: indexPath)
        
        if indexPath.row >= self.nearbyBuoys.count {
            return cell
        }
        
        let buoy = self.nearbyBuoys[indexPath.row]
        cell.textLabel?.text = buoy.location?.name
        cell.detailTextLabel?.text = "Station: " + buoy.stationId! + " " + (buoy.program ?? "")
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row >= self.nearbyBuoys.count {
            tableView.deselectRow(at: indexPath, animated: true)
            return
        }
        
        self.selectedBuoyStation = self.nearbyBuoys[indexPath.row].stationId!
        self.performSegue(withIdentifier: "exploreShowBuoySegue", sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
