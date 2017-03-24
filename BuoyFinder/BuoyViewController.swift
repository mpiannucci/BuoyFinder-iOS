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
            if self.buoy != nil {
                self.setupViews()
            }
        }
    }
    
    // UI Elements
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var buoyDataTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the map settings
        self.mapView.mapType = GMSMapViewType.hybrid
        self.mapView.settings.setAllGesturesEnabled(false)
        
        // Set up the tableview
        self.buoyDataTable.delegate = self
        self.buoyDataTable.dataSource = self
        
        // Add a refresh control to the data table
        self.buoyDataTable.refreshControl = UIRefreshControl()
        self.buoyDataTable.refreshControl?.backgroundColor = UIColor.white
        self.buoyDataTable.refreshControl?.tintColor = UIColor(colorLiteralRed: 0, green: 179.0/255.0, blue: 134.0/255.0, alpha: 255.0/255.0)
        self.buoyDataTable.refreshControl?.addTarget(self, action: #selector(self.fetchNewBuoyData), for: .valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.setupViews()
        
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
        
        // Set the favorites button
        self.setFavoriteBuoyIcon(isFavorite: SyncManager.instance.isBuoyAFavorite(buoy: self.buoy!))
        
        // Clear the map
        self.mapView.clear()
        
        // Set up the map of the buoy
        self.mapView.camera = GMSCameraPosition.camera(withLatitude: self.buoy!.location.latitude + 0.5, longitude: self.buoy!.location.longitude, zoom: 6)
        
        // Clear existing markers and create the marker for our location
        let marker = GMSMarker()
        marker.position = CLLocation(latitude: self.buoy!.location.latitude, longitude: self.buoy!.location.longitude).coordinate
        marker.title = "Station: " + self.buoy!.stationID
        marker.snippet = self.buoy!.program!
        marker.map = mapView
        
        self.mapView.selectedMarker = marker
        
        // Set the units to match the settings
        self.buoy?.units = SyncManager.instance.units
        
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
                
                if let updateDate = buoy_.latestUpdateTime {
                    let dateString = DateFormatter.localizedString(from: updateDate, dateStyle: .short, timeStyle: .short)
                    self.mapView.selectedMarker?.snippet = "\(self.mapView.selectedMarker!.snippet!)\nUpdated \(dateString)"
                }
            }
        }
    }
    
    @objc func toggleBuoyFavorite() {
        if self.buoy == nil {
            return
        }
        
        if SyncManager.instance.isBuoyAFavorite(buoy: self.buoy!) {
            SyncManager.instance.removeFavoriteBuoy(buoy: self.buoy!)
            setFavoriteBuoyIcon(isFavorite: false)
        } else {
            SyncManager.instance.addFavoriteBuoy(newBuoy: self.buoy!)
            setFavoriteBuoyIcon(isFavorite: true)
        }
    }
    
    func setFavoriteBuoyIcon(isFavorite: Bool) {
        let barButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: #selector(self.toggleBuoyFavorite))
        if isFavorite {
            barButtonItem.image = UIImage(named: "ic_star_white")
        } else {
            barButtonItem.image = UIImage(named: "ic_star_border_white")
        }
        self.navigationItem.rightBarButtonItem = barButtonItem
    }
    
    @objc func fetchNewBuoyData() {
        self.buoy?.fetchAllLatestData()
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
        switch section {
        case 0:
            return 6
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
                
                if let waveSummary = self.buoy?.latestData?.waveSummary {
                    waveSummaryView.text = waveSummary.simpleDescription()
                }
                if let primaryComponent = self.buoy?.latestData?.swellComponents?[0] {
                    primaryComponentView.text = primaryComponent.detailedDescription()
                }
                if let secondaryComponent = self.buoy?.latestData?.swellComponents?[1] {
                    secondaryComponentView.text = secondaryComponent.detailedDescription()
                }
                
            } else {
                cell = tableView.dequeueReusableCell(withIdentifier: "weatherInfoCell", for: indexPath)
                switch indexPath.row {
                case 1:
                    cell.textLabel?.text = "Wind"
                    if let windSpeed = self.buoy?.latestData?.windSpeed, let windDir = self.buoy?.latestData?.windDirection {
                        cell.detailTextLabel?.text = String(format: "%.1f \(self.buoy!.units.speedUnit()) %.0f\(self.buoy!.units.degreesUnit())", windSpeed, windDir)
                    }
                case 2:
                    cell.textLabel?.text = "Wind Gust"
                    if let windGust = self.buoy?.latestData?.windGust {
                        cell.detailTextLabel?.text = String(format: "%.1f \(self.buoy!.units.speedUnit())", windGust)
                    }
                case 3:
                    cell.textLabel?.text = "Water Temperature"
                    if let waterTemp = self.buoy?.latestData?.waterTemperature {
                        cell.detailTextLabel?.text = String(format: "%.2f", waterTemp) + " " + buoy!.latestData!.units.temperatureUnit()
                    } else {
                        cell.detailTextLabel?.text = "N/A"
                    }
                case 4:
                    cell.textLabel?.text = "Air Temperature"
                    if let airTemp = self.buoy?.latestData?.airTemperature {
                        cell.detailTextLabel?.text = String(format: "%.2f", airTemp) + " " + buoy!.latestData!.units.temperatureUnit()
                    } else {
                        cell.detailTextLabel?.text = "N/A"
                    }
                case 5:
                    cell.textLabel?.text = "Pressure"
                    if let pressure  = self.buoy?.latestData?.pressure {
                        cell.detailTextLabel?.text = String(format: "%.2f", pressure) + " " + buoy!.latestData!.units.pressureUnit()
                        if let _ = self.buoy?.latestData?.pressureTendency {
                            cell.detailTextLabel?.text = cell.detailTextLabel!.text! + " " + self.buoy!.latestData!.pressureTendencyString
                        }
                    } else {
                        cell.detailTextLabel?.text = "N/A"
                    }
                default:
                    break
                }
            }
            break
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveDirectionalSpectraCell", for: indexPath)
            let plotView = cell.viewWithTag(51) as! AsyncImageView
            if let plotURL = self.buoy?.latestData?.directionalSpectraPlotURL {
                plotView.imageURL = URL.init(string: plotURL)
            }
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveEnergyDistributionCell", for: indexPath)
            let plotView = cell.viewWithTag(51) as! AsyncImageView
            if let plotURL = self.buoy?.latestData?.spectralDistributionPlotURL {
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
