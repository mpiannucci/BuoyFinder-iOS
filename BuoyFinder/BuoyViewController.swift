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
        guard let buoy = self.buoy, let mapView = self.mapView else { return }
        
        // Set the title
        self.title = buoy.name
        
        // Set the favorites button
        self.setFavoriteBuoyIcon(isFavorite: SyncManager.instance.isBuoyAFavorite(buoy: self.buoy!))
        
        // Clear the map
        self.mapView.clear()
        
        // Set up the map of the buoy
        self.mapView.camera = GMSCameraPosition.camera(withLatitude: buoy.location.latitude + 0.5, longitude: buoy.location.longitude, zoom: 6)
        
        // Clear existing markers and create the marker for our location
        let marker = GMSMarker()
        marker.position = CLLocation(latitude: self.buoy!.location.latitude, longitude: buoy.location.longitude).coordinate
        marker.title = "Station: " + buoy.stationID
        marker.snippet = buoy.program ?? ""
        marker.map = mapView
        
        self.mapView.selectedMarker = marker
        
        // Set the units to match the settings
        self.buoy?.units = SyncManager.instance.units
        
        // Try to update the table...
        if let newWeatherData = self.buoy?.latestData?.weatherData {
            self.weatherData = newWeatherData
            self.weatherKeys = Array(self.weatherData.keys)
        }
        self.buoyDataTable.reloadData()
    }
    
    @objc func reloadTableData() {
        DispatchQueue.main.async{
            if let newWeatherData = self.buoy?.latestData?.weatherData {
                self.weatherData = newWeatherData
                self.weatherKeys = Array(self.weatherData.keys)
            }
            self.buoyDataTable.reloadData()
            
            if let buoy_ = self.buoy {
                if !buoy_.isFetching && self.buoyDataTable.refreshControl!.isRefreshing {
                    self.buoyDataTable.refreshControl?.endRefreshing()
                }
                
                if let updateDate = buoy_.latestUpdateTime {
                    let dateString = DateFormatter.localizedString(from: updateDate, dateStyle: .short, timeStyle: .short)
                    self.mapView.selectedMarker?.snippet = "\(buoy_.program ?? "")\nUpdated \(dateString)"
                }
            }
        }
    }
    
    @objc func toggleBuoyFavorite() {
        guard let buoy = self.buoy else { return }
        
        if SyncManager.instance.isBuoyAFavorite(buoy: buoy) {
            SyncManager.instance.removeFavoriteBuoy(buoy: buoy)
            setFavoriteBuoyIcon(isFavorite: false)
        } else {
            SyncManager.instance.addFavoriteBuoy(newBuoy: buoy)
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            if self.buoy?.latestData?.waveSummary != nil {
                return 1
            } else {
                return 0
            }
        case 1:
            return self.weatherData.count
        case 2:
            if self.buoy?.latestData?.directionalSpectraPlotURL != nil {
                return 1
            } else {
                return 0
            }
        case 3:
            if self.buoy?.latestData?.spectralDistributionPlotURL != nil {
                return 1
            } else {
                return 0
            }
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
        
        switch indexPath.section {
        case 0:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveStatusCell", for: indexPath)
            guard let waveSummaryView = cell.viewWithTag(41) as? UILabel,
                let primaryComponentView = cell.viewWithTag(42) as? UILabel,
                let secondaryComponentView = cell.viewWithTag(43) as? UILabel else { return cell }

            if let waveSummary = self.buoy?.latestData?.waveSummary {
                waveSummaryView.text = waveSummary.simpleDescription()
            }
            if let primaryComponent = self.buoy?.latestData?.swellComponents?[0] {
                primaryComponentView.text = primaryComponent.detailedDescription()
            } else {
                primaryComponentView.text = "No Component Information Available"
            }
            if let secondaryComponent = self.buoy?.latestData?.swellComponents?[1] {
                secondaryComponentView.text = secondaryComponent.detailedDescription()
            }
        case 1:
            cell = tableView.dequeueReusableCell(withIdentifier: "weatherInfoCell", for: indexPath)
            let key = self.weatherKeys[indexPath.row]
            cell.textLabel?.text = key
            cell.detailTextLabel?.text = self.weatherData[key]
        case 2:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveDirectionalSpectraCell", for: indexPath)
            guard let plotView = cell.viewWithTag(51) as? AsyncImageView else { return cell }
            if let plotURL = self.buoy?.latestData?.directionalSpectraPlotURL {
                plotView.imageURL = URL.init(string: plotURL)
            }
        case 3:
            cell = tableView.dequeueReusableCell(withIdentifier: "waveEnergyDistributionCell", for: indexPath)
            guard let plotView = cell.viewWithTag(51) as? AsyncImageView else { return cell }
            if let plotURL = self.buoy?.latestData?.spectralDistributionPlotURL {
                plotView.imageURL = URL.init(string: plotURL)
            }
        default:
            // Do Nothing and give back an empty cell
            cell = UITableViewCell()
        }
     
        return cell
    }
}
