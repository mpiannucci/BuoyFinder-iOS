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
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet public weak var mapView: GMSMapView!
    @IBOutlet weak var nearbyBuoysTable: UITableView!
    
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var nearbyBuoys: [Buoy] = []

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
        
        // Set up the nearby buoys list and searching
        self.nearbyBuoysTable.dataSource = self
        self.nearbyBuoysTable.delegate = self
        
        // Set up the search controllers
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Set up the search bar
        let subView = UIView(frame: CGRect(x: 0, y: 65.0, width: UIScreen.main.bounds.width, height: 45.0))
        subView.addSubview((searchController?.searchBar)!)
        view.addSubview(subView)
        searchController?.searchBar.sizeToFit()
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        definesPresentationContext = true
        
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
            buoyView.buoy?.fetchAllDataIfNeeded()
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

    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        DispatchQueue.global().async {
            let location = Location(latitude: position.target.latitude, longitude: position.target.longitude)
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
        self.mapView.camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: 6)
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

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.nearbyBuoys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "nearbyBuoyCell", for: indexPath)
        
        if indexPath.row >= self.nearbyBuoys.count {
            return cell
        }
        
        let buoy = self.nearbyBuoys[indexPath.row]
        cell.textLabel?.text = buoy.name
        cell.detailTextLabel?.text = "Station: " + buoy.stationID + " " + buoy.program!
        
        return cell
    }
}
