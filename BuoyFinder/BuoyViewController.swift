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
    public var buoyId: String? {
        didSet {
            // Set the default camera to be directly over america
            guard let _ = self.buoyId else {
                return
            }
            
            self.setupViews()
        }
    }
    var weatherKeys: [String] = []
    var weatherData: [String:String] = [:]
    
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
        self.buoyDataTable.refreshControl?.tintColor = UIColor(red: 0, green: 179.0/255.0, blue: 134.0/255.0, alpha: 255.0/255.0)
        self.buoyDataTable.refreshControl?.addTarget(self, action: #selector(self.fetchNewBuoyData), for: .valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.setupViews()
        
        guard let buoyId_ = self.buoyId else {
            return
        }
        
        if BuoyModel.sharedModel.isBuoyDataFetching(stationId: buoyId_) && !self.buoyDataTable.refreshControl!.isRefreshing {
            self.buoyDataTable.refreshControl?.beginRefreshing()
            self.buoyDataTable.setContentOffset(CGPoint(x: 0, y: -60.0), animated: true)
        }
        
        // Register notification listeners
        NotificationCenter.default.addObserver(self, selector: #selector(handleBuoyDataUpdate(_:)), name: Buoy.buoyDataUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleBuoyDataUpdate(_:)), name: Buoy.buoyDataUpdateFailedNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        // Deregister notification listeners
        NotificationCenter.default.removeObserver(self)
        
        super.viewDidDisappear(animated)
    }
    
    func setupViews() {
        guard let buoyId_ = self.buoyId, let buoy = BuoyModel.sharedModel.buoys[buoyId_], let mapView = self.mapView else { return }
        
        // Set the title
        self.title = buoy.name
        
        // Set the favorites button
        self.setFavoriteBuoyIcon(isFavorite: SyncManager.instance.isBuoyAFavorite(buoyId: buoyId_))
        
        // Clear the map
        self.mapView.clear()
        
        // Set up the map of the buoy
        self.mapView.camera = GMSCameraPosition.camera(withLatitude: buoy.location!.latitude!.doubleValue + 0.5, longitude: buoy.location!.longitude!.doubleValue, zoom: 6)
        
        // Clear existing markers and create the marker for our location
        let marker = GMSMarker()
        marker.position = CLLocation(latitude: buoy.location!.latitude!.doubleValue, longitude: buoy.location!.longitude!.doubleValue).coordinate
        marker.title = "Station: " + buoy.stationId!
        marker.snippet = buoy.program ?? ""
        marker.map = mapView
        
        self.mapView.selectedMarker = marker
        
        // Set the units to match the settings
        //self.buoy?.unit = SyncManager.instance.units
        
        // Try to update the table...
        if let newWeatherData = buoy.data?.first?.weatherData {
            self.weatherData = newWeatherData
            self.weatherKeys = Array(self.weatherData.keys)
        }
        self.buoyDataTable.reloadData()
    }
    
    @objc func handleBuoyDataUpdate(_ notification: NSNotification) {
        guard let stationIdInfo = notification.userInfo?["stationId"] as? String, let stationId = self.buoyId else {
            return
        }
        
        if stationIdInfo != stationId {
            return
        }
        
        reloadTableData()
    }
    
    @objc func reloadTableData() {
        DispatchQueue.main.async{
            
            if let buoyId_ = self.buoyId, let buoy = BuoyModel.sharedModel.buoys[buoyId_] {
                if !BuoyModel.sharedModel.isBuoyDataFetching(stationId: buoyId_) && self.buoyDataTable.refreshControl!.isRefreshing {
                    self.buoyDataTable.refreshControl?.endRefreshing()
                }

                if let updateDate = buoy.latestUpdateTime {
                    let dateString = DateFormatter.localizedString(from: updateDate, dateStyle: .short, timeStyle: .short)
                    self.mapView.selectedMarker?.snippet = "\(self.mapView.selectedMarker?.snippet ?? "")\nUpdated \(dateString)"
                }
                
                if let newWeatherData = buoy.data?.first?.weatherData {
                    self.weatherData = newWeatherData
                    self.weatherKeys = Array(self.weatherData.keys)
                }
            }
            
            self.buoyDataTable.reloadData()
        }
    }
    
    @objc func toggleBuoyFavorite() {
        guard let buoyId_ = self.buoyId else { return }
        
        if SyncManager.instance.isBuoyAFavorite(buoyId: buoyId_) {
            SyncManager.instance.removeFavoriteBuoy(buoyId: buoyId_)
            setFavoriteBuoyIcon(isFavorite: false)
        } else {
            SyncManager.instance.addFavoriteBuoy(newBuoyId: buoyId_)
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
        guard let stationId = self.buoyId else {
            return
        }
        
        BuoyModel.sharedModel.fetchAllLatestBuoyData(stationId: stationId, units: SyncManager.instance.units)
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let buoyId_ = self.buoyId, let buoy = BuoyModel.sharedModel.buoys[buoyId_] else {
            return 0
        }
        
        switch section {
        case 0:
            if buoy.data?.first?.waveSummary != nil {
                return 1
            }
            return 0
        case 1:
            return self.weatherData.count
        case 2:
            if buoy.data?.first?.directionSpectraPlot != nil {
                return 1
            }
            return 0
        case 3:
            if buoy.data?.first?.energySpectraPlot != nil {
                return 1
            }
            return 0
        case 4:
            return 4
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "Waves"
        case 1:
            return "Weather";
        case 2:
            return "Directional Wave Spectra"
        case 3:
            return "Wave Energy Distribution"
        case 4:
            return "Station Info"
        default:
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        
        switch indexPath.section {
        case 0:
            return 150.0
        case 1:
            return 50.0
        case 2:
            return screenWidth
        case 3:
            return screenWidth * 3.0 / 4.0
        default:
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if (self.tableView(tableView, numberOfRowsInSection: section) == 0) {
            return 0.0
        } else {
            return UITableViewAutomaticDimension
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        guard let buoyId_ = self.buoyId, let buoy = BuoyModel.sharedModel.buoys[buoyId_] else {
            cell = UITableViewCell()
            return cell
        }
        
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveStatusCell", for: indexPath)
            guard let waveSummaryView = cell.viewWithTag(41) as? UILabel,
                let primaryComponentView = cell.viewWithTag(42) as? UILabel,
                let secondaryComponentView = cell.viewWithTag(43) as? UILabel else { return cell }

            if let waveSummary = buoy.data?.first?.waveSummary {
                waveSummaryView.text = waveSummary.simpleDescription
            }

            if let swellComponents = buoy.data?.first?.swellComponents {
                if swellComponents.count > 0 {
                    primaryComponentView.text = swellComponents[0].detailedDescription
                } else {
                    primaryComponentView.text = "No primary swell"
                }

                if swellComponents.count > 1 {
                    secondaryComponentView.text = swellComponents[1].detailedDescription
                } else {
                    secondaryComponentView.text = "No secondary swell"
                }
            } else {
                primaryComponentView.text = "No Component Information Available"
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "weatherInfoCell", for: indexPath)
            let key = self.weatherKeys[indexPath.row]
            cell.textLabel?.text = key
            cell.detailTextLabel?.text = self.weatherData[key]
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveDirectionalSpectraCell", for: indexPath)
            guard let plotView = cell.viewWithTag(51) as? AsyncImageView else { return cell }
            if let plotURL = buoy.data?.first?.directionSpectraPlot {
                plotView.imageURL = URL.init(string: plotURL)
            }
        case 3:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveEnergyDistributionCell", for: indexPath)
            guard let plotView = cell.viewWithTag(51) as? AsyncImageView else { return cell }
            if let plotURL = buoy.data?.first?.energySpectraPlot {
                plotView.imageURL = URL.init(string: plotURL)
            }
        case 4:
            cell = tableView.dequeueReusableCell(withIdentifier: "weatherInfoCell", for: indexPath)
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Active"
                cell.detailTextLabel?.text = "\(buoy.active!.boolValue)".capitalized
                if buoy.active?.boolValue ?? false {
                    cell.textLabel?.textColor = UIColor.green.darker()
                    cell.detailTextLabel?.textColor = UIColor.green.darker()
                } else {
                    cell.textLabel?.textColor = UIColor.red.darker()
                    cell.detailTextLabel?.textColor = UIColor.red.darker()
                }
            case 1:
                cell.textLabel?.text = "Type"
                cell.detailTextLabel?.text = "\(buoy.stationType!.capitalized)"
            case 2:
                cell.textLabel?.text = "Owner"
                cell.detailTextLabel?.text = "\(buoy.owner!)"
            case 3:
                cell.textLabel?.text = "Program"
                cell.detailTextLabel?.text = "\(buoy.program!)"
            default:
                break
            }
        default:
            // Do Nothing and give back an empty cell
            cell = UITableViewCell()
        }
     
        return cell
    }
}
