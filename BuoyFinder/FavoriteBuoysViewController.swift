//
//  FavoriteBuoysViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 11/28/16.
//  Copyright © 2016 Matthew Iannucci. All rights reserved.
//

import UIKit
import BuoyFinderDataKit


class FavoriteBuoysViewController: UITableViewController {
    
    private var initialLoad: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem?.title = ""
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.parent?.navigationItem.rightBarButtonItem = self.editButtonItem

        self.tableView.reloadData()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTableData), name: BuoyModel.buoyStationsUpdatedNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTableData), name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.parent?.navigationItem.rightBarButtonItem = nil
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func updateTableData() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            
            // Check to see if we should navigate to the users default buoy
            if self.initialLoad && SyncManager.instance.favoriteBuoyIds.count > 0 {
                if SyncManager.instance.initialView == SyncManager.InitialView.defaultBuoy {
                    if let buoyIndex = SyncManager.instance.favoriteBuoyIds.index(of: SyncManager.instance.defaultBuoyId) {
                        let indexPath = IndexPath(row: buoyIndex, section: 0)
                        self.tableView.selectRow(at: indexPath, animated: false, scrollPosition: UITableViewScrollPosition.none)
                        self.performSegue(withIdentifier: "favoriteBuoySegue", sender: self)
                    }
                }
                
                self.initialLoad = false
            }
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if BuoyModel.sharedModel.buoys.count < 1 {
            return 0
        }
        
        return SyncManager.instance.favoriteBuoyIds.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteBuoyCell", for: indexPath)

        if let buoy = BuoyModel.sharedModel.buoys[SyncManager.instance.favoriteBuoyIds[indexPath.row]] {
            cell.textLabel?.text = buoy.name!
            cell.detailTextLabel?.text = "Station: " + buoy.stationId! + " " + (buoy.program ?? "")
        }

        return cell
    }
    
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        SyncManager.instance.moveFavoriteBuoy(currentIndex: fromIndexPath.row, newIndex: to.row)
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            //tableView.deleteRows(at: [indexPath], with: .fade)
            SyncManager.instance.removeFavoriteBuoy(buoyId: SyncManager.instance.favoriteBuoyIds[indexPath.row])
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath) -> String? {
        return "Remove"
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier != "favoriteBuoySegue" {
            return
        }
        
        // Get the buoy view
        if let buoyView = segue.destination as? BuoyViewController, let index = self.tableView.indexPathForSelectedRow {
            buoyView.buoyId = SyncManager.instance.favoriteBuoyIds[index.row]
            BuoyModel.sharedModel.fetchAllLatestBuoyData(stationId: SyncManager.instance.favoriteBuoyIds[index.row], units: SyncManager.instance.units)
        }
    }

}
