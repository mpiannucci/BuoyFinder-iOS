//
//  BuoyViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 12/26/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import UIKit
import GoogleMaps
import AsyncImageView
import BuoyFinderDataKit

class BuoyViewController: UIViewController {
    
    // Variables
    public var buoy: Buoy? {
        didSet {
            // Set the default camera to be directly over america
            if buoy != nil {
                setupViews()
            }
        }
    }
    
    // UI Elements
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var buoyDataTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the map settings
        self.mapView.mapType = kGMSTypeHybrid
        self.mapView.settings.setAllGesturesEnabled(false)
        
        // Set up the tableview
        self.buoyDataTable.delegate = self
        self.buoyDataTable.dataSource = self
        
        // Add a refresh control to the data table
        self.buoyDataTable.refreshControl = UIRefreshControl()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupViews()
        
        if let buoy_ = self.buoy {
            if buoy_.isFetching && !self.buoyDataTable.refreshControl!.isRefreshing {
                self.buoyDataTable.refreshControl?.beginRefreshing()
                self.buoyDataTable.setContentOffset(CGPoint(x: 0, y: -60.0), animated: true)
            }
        }
    
        // Register notification listeners
        NotificationCenter.default.addObserver(self, selector: #selector(reloadTableData), name: Buoy.buoyDataUpdatedNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Deregister notification listeners
        NotificationCenter.default.removeObserver(self)
        
        super.viewDidDisappear(animated)
    }
    
    func setupViews() {
        if self.buoy == nil || self.mapView == nil {
            return
        }
        
        // Set the title
        self.title = self.buoy!.name
        
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
        
        // Try to update the table...
        self.buoyDataTable.reloadData()
    }
    
    @objc func reloadTableData() {
        DispatchQueue.main.async{
            self.buoyDataTable.reloadData()
            
            if let buoy_ = self.buoy {
                if !buoy_.isFetching && self.buoyDataTable.refreshControl!.isRefreshing {
                    self.buoyDataTable.refreshControl?.endRefreshing()
                }
            }
        }
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
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        // #warning Incomplete implementation, return the number of rows
        switch section {
        case 0:
            return 2
        case 1:
            return 1
        case 2:
            return 1
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Latest Buoy Data";
        case 1:
            return "Directional Wave Spectra"
        case 2:
            return "Wave Energy Distribution"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                return 150.0
            } else {
                return 50.0
            }
        case 1:
            return screenWidth
        case 2:
            return screenWidth * 2 / 3
        default:
            return 150.0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        switch indexPath.section {
        case 0:
            if indexPath.row == 0 {
                cell = tableView.dequeueReusableCell(withIdentifier: "waveStatusCell", for: indexPath)
                let waveSummaryView = cell.viewWithTag(41) as! UILabel
                let primaryComponentView = cell.viewWithTag(42) as! UILabel
                let secondaryComponentView = cell.viewWithTag(43) as! UILabel
                
                if let waveSummary = buoy?.latestData?.waveSummary {
                    waveSummaryView.text = waveSummary.simpleDescription()
                }
                if let primaryComponent = buoy?.latestData?.swellComponents?[0] {
                    primaryComponentView.text = primaryComponent.detailedDescription()
                }
                if let secondaryComponent = buoy?.latestData?.swellComponents?[1] {
                    secondaryComponentView.text = secondaryComponent.detailedDescription()
                }
                
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "weatherInfoCell", for: indexPath)
                switch indexPath.row {
                case 1:
                    if let waterTemp = buoy?.latestData?.waterTemperature {
                        cell.textLabel?.text = "Water Temperature"
                        cell.detailTextLabel?.text = String(describing: waterTemp) + " " + buoy!.latestData!.units.temperatureUnit()
                    }
                default:
                    break
                }
            }
            break
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveDirectionalSpectraCell", for: indexPath)
            let plotView = cell.viewWithTag(51) as! AsyncImageView
            if let plotURL = buoy?.latestData?.directionalSpectraPlotURL {
                plotView.imageURL = URL.init(string: plotURL)
            }
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveEnergyDistributionCell", for: indexPath)
            let plotView = cell.viewWithTag(51) as! AsyncImageView
            if let plotURL = buoy?.latestData?.spectralDistributionPlotURL {
                plotView.imageURL = URL.init(string: plotURL)
            }
        default:
            // Do Nothing and give back an empty cell
            cell = UITableViewCell()
        }
     
        // Configure the cell..
        return cell
    }
}
