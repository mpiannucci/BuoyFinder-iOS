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
                
                // Set up the title of the view controller
                self.title = newBuoy.location.locationName
                
                // Set up the map of the buoy
                self.mapView.camera = GMSCameraPosition.camera(withLatitude: newBuoy.location.latitude, longitude: newBuoy.location.longitude, zoom: 6)
                
                let marker = GMSMarker()
                marker.position = CLLocation(latitude: newBuoy.location.latitude, longitude: newBuoy.location.longitude).coordinate
                marker.title = newBuoy.location.locationName
                marker.snippet = "Station: " + newBuoy.stationID + ", " + newBuoy.program!
                marker.map = mapView
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
