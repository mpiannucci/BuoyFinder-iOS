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
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        self.tableView.contentInset = UIEdgeInsetsMake(64, 0, 0, 0)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.parent?.navigationItem.rightBarButtonItem = self.editButtonItem

        self.tableView.reloadData()
        
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
            if self.initialLoad && SyncManager.instance.favoriteBuoys.count > 0 {
                if SyncManager.instance.initialView == SyncManager.InitialView.defaultBuoy {
                    if let buoyIndex = SyncManager.instance.favoriteBuoyIDs.index(of: SyncManager.instance.defaultBuoyID) {
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
        // #warning Incomplete implementation, return the number of rows
        return SyncManager.instance.favoriteBuoys.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "favoriteBuoyCell", for: indexPath)

        let buoy = SyncManager.instance.favoriteBuoys[indexPath.row]
        cell.textLabel?.text = buoy.name
        cell.detailTextLabel?.text = "Station: " + buoy.stationID + " " + (buoy.program ?? "")

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
            SyncManager.instance.removeFavoriteBuoy(buoy: SyncManager.instance.favoriteBuoys[indexPath.row])
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
            buoyView.buoy = SyncManager.instance.favoriteBuoys[index.row]
            buoyView.buoy?.fetchAllDataIfNeeded()
        }
    }

}
