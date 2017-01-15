//
//  BuoyViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/26/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import UIKit
import GoogleMaps
import BuoyFinderDataKit

class BuoyViewController: UIViewController {
    
    // Variables
    public var buoy: Buoy? {
        didSet {
            // Set the default camera to be directly over america
            if let newBuoy = buoy {
                setupViews()
            }
        }
    }
    
    // UI Elements
    @IBOutlet weak var mapView: GMSMapView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the map settings
        self.mapView.mapType = kGMSTypeHybrid
        self.mapView.settings.setAllGesturesEnabled(false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupViews()
    }
    
    func setupViews() {
        if self.buoy == nil || self.mapView == nil {
            return
        }
        
        // Set the title
        self.title = self.buoy!.location.locationName
        
        // Clear the map
        self.mapView.clear()
        
        // Set up the map of the buoy
        self.mapView.camera = GMSCameraPosition.camera(withLatitude: self.buoy!.location.latitude, longitude: self.buoy!.location.longitude, zoom: 6)
        
        // Clear existing markers and create the marker for our location
        let marker = GMSMarker()
        marker.position = CLLocation(latitude: self.buoy!.location.latitude, longitude: self.buoy!.location.longitude).coordinate
        marker.title = "Station: " + self.buoy!.stationID
        marker.snippet = self.buoy!.program!
        marker.map = mapView
        
        mapView.selectedMarker = marker
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

extension BuoyViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)
     
        // Configure the cell..
        return cell
    }
}
