//
//  SettingsViewController.swift
//  BuoyFinder
//
//  Created by Matthew Iannucci on 2/17/17.
//  Copyright © 2017 Matthew Iannucci. All rights reserved.
//

import UIKit
import GoogleSignIn
import Firebase
import BuoyFinderDataKit

class SettingsViewController: UITableViewController, GIDSignInUIDelegate {

    private var userRef: DatabaseReference? = nil
    private var latestSnapshot: DataSnapshot? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.reloadSettingsTable), name: SyncManager.syncDataUpdatedNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func done(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func reloadSettingsTable() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func  tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return "User Interface"
        case 1:
            return "Account"
        case 2:
            return "About"
        default:
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            if let _ = Auth.auth().currentUser {
                return 2
            } else {
                return 1
            }
        case 2:
            return 3
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var reuseIdentifier = "subtitleCell"
        if indexPath.section == 2 {
            reuseIdentifier = "basicCell"
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)

        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Units"
                cell.detailTextLabel?.text = SyncManager.instance.units.rawValue.capitalized
            case 1:
                cell.textLabel?.text = "Initial View"
                cell.detailTextLabel?.text = SyncManager.instance.initialView.rawValue.capitalized
                
            case 2:
                cell.textLabel?.text = "Default Buoy"
                if let defaultBuoy = SyncManager.instance.defaultbuoy {
                    cell.detailTextLabel?.text =  defaultBuoy.name
                } else if SyncManager.instance.favoriteBuoys.count > 0 {
                    cell.detailTextLabel?.text = "Click to choose a default buoy"
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.detailTextLabel?.text = "Save a favorite buoy to enable"
                    cell.isUserInteractionEnabled = false
                }
            case 3:
                cell.textLabel?.text = "Today Widget Variable"
                cell.detailTextLabel?.text = SyncManager.instance.todayVariable.rawValue.capitalized
                if SyncManager.instance.favoriteBuoys.count > 0  {
                    cell.isUserInteractionEnabled = true
                } else {
                    cell.detailTextLabel?.text = "Save a favorite buoy to enable"
                    cell.isUserInteractionEnabled = false
                }
            default:
                break
            }
            break
        case 1:
            switch indexPath.row {
            case 0:
                if let user = Auth.auth().currentUser {
                    cell.textLabel?.text = "Logged in as \(user.email ?? "")"
                    cell.detailTextLabel?.text = "Click to log out"
                } else {
                    cell.textLabel?.text = "Not Logged In"
                    cell.detailTextLabel?.text = "Click to log in and sync your favorites"
                }
            case 1:
                cell.textLabel?.text = "Delete Account"
            default:
                break
            }
            break
        case 2:
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Contact Developer"
            case 1:
                cell.textLabel?.text = "Rate On The App Store"
            case 2:
                cell.textLabel?.text = "Copyright 2017 Matthew Iannucci"
            default:
                break
            }
        default:
            break
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                let unitPicker = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: { (_) in
                    unitPicker.dismiss(animated: true, completion: nil)
                })
                unitPicker.addAction(cancelAction)
            
                let metricAction = UIAlertAction(title: Units.metric.rawValue.capitalized, style: .default, handler: {
                    (_) in
                    SyncManager.instance.changeUnits(newUnits: Units.metric)
                    unitPicker.dismiss(animated: true, completion: nil)
                })
                unitPicker.addAction(metricAction)
            
                let englishAction = UIAlertAction(title: Units.english.rawValue.capitalized, style: .default, handler: {
                    (_) in
                    SyncManager.instance.changeUnits(newUnits: Units.english)
                    unitPicker.dismiss(animated: true, completion: nil)
                })
                unitPicker.addAction(englishAction)
            
                self.present(unitPicker, animated: true, completion: nil)
            case 1:
                let initialViewPicker = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    initialViewPicker.dismiss(animated: true, completion: nil)
                })
                initialViewPicker.addAction(cancelAction)
                
                let exploreAction = UIAlertAction(title: SyncManager.InitialView.explore.rawValue.capitalized, style: .default, handler: {(_) in
                    SyncManager.instance.changeInitialView(newInitialView: SyncManager.InitialView.explore)
                    initialViewPicker.dismiss(animated: true, completion: nil)
                })
                initialViewPicker.addAction(exploreAction)
                
                let favoritesAction = UIAlertAction(title: SyncManager.InitialView.favorites.rawValue.capitalized, style: .default, handler: { (_) in
                    SyncManager.instance.changeInitialView(newInitialView: SyncManager.InitialView.favorites)
                    initialViewPicker.dismiss(animated: true, completion: nil)
                })
                initialViewPicker.addAction(favoritesAction)
                
                if SyncManager.instance.favoriteBuoys.count > 0 {
                    let defaultBuoyAction = UIAlertAction(title: SyncManager.InitialView.defaultBuoy.rawValue.capitalized, style: .default, handler: { (_) in
                        SyncManager.instance.changeInitialView(newInitialView: SyncManager.InitialView.defaultBuoy)
                        initialViewPicker.dismiss(animated: true, completion: nil)
                    })
                    initialViewPicker.addAction(defaultBuoyAction)
                }
                
                self.present(initialViewPicker, animated: true, completion: nil)
            case 2:
                let favoriteBuoys = SyncManager.instance.favoriteBuoys
                if favoriteBuoys.count < 1 {
                    break
                }
                
                let defaultBuoyPicker = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    defaultBuoyPicker.dismiss(animated: true, completion: nil)
                })
                defaultBuoyPicker.addAction(cancelAction)
                
                favoriteBuoys.forEach({ (buoy) in
                    let buoyAction = UIAlertAction(title: buoy.name, style: .default, handler: { (_) in
                        SyncManager.instance.changeDefaultBuoy(buoyID: buoy.stationID)
                        defaultBuoyPicker.dismiss(animated: true, completion: nil)
                    })
                    defaultBuoyPicker.addAction(buoyAction)
                })
                
                self.present(defaultBuoyPicker, animated: true, completion: nil)
            case 3:
                let todayVariablePicker = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    todayVariablePicker.dismiss(animated: true, completion: nil)
                })
                todayVariablePicker.addAction(cancelAction)
                
                BuoyDataItem.dataVariables.forEach({ (variable) in
                    let todayVariableAction = UIAlertAction(title: variable.rawValue.capitalized, style: .default, handler: { (_) in
                        SyncManager.instance.changeTodayVariable(newVariable: variable)
                        todayVariablePicker.dismiss(animated: true, completion: nil)
                    })
                    todayVariablePicker.addAction(todayVariableAction)
                })
                
                self.present(todayVariablePicker, animated: true, completion: nil)
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                if let _ = Auth.auth().currentUser {
                    let confirmationController = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
                    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                        confirmationController.dismiss(animated: true, completion: nil)
                    })
                    confirmationController.addAction(cancelAction)
                    let logOutAction = UIAlertAction(title: "Yes, Log out now", style: .default, handler: { (_) in
                        do {
                            try Auth.auth().signOut()
                            GIDSignIn.sharedInstance().signOut()
                        } catch let signOutError as NSError {
                            print ("Error signing out: %@", signOutError)
                        }
                        confirmationController.dismiss(animated: true, completion: nil)
                    })
                    confirmationController.addAction(logOutAction)
                    
                    self.present(confirmationController, animated: true, completion: nil)
                } else {
                    GIDSignIn.sharedInstance().signIn()
                }
            case 1:
                if Auth.auth().currentUser == nil {
                    break
                }
                
                let confirmationController = UIAlertController(title: "Delete Account", message: "Are you sure you want to delete your account? You will be logged out and all saved settings will be permanently deleted!", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
                    confirmationController.dismiss(animated: true, completion: nil)
                })
                confirmationController.addAction(cancelAction)
                let deleteAction = UIAlertAction(title: "Yes, delete now", style: .default, handler: { (_) in
                    SyncManager.instance.deleteUser()
                    do {
                        try Auth.auth().signOut()
                        GIDSignIn.sharedInstance().signOut()
                    } catch let signOutError as NSError {
                        print ("Error signing out: %@", signOutError)
                    }
                    confirmationController.dismiss(animated: true, completion: nil)
                })
                confirmationController.addAction(deleteAction)
                
                self.present(confirmationController, animated: true, completion: nil)
            default:
                break
            }
            break
        case 2:
            switch indexPath.row {
            case 0:
                let email = "rhodysurf13@gmail.com"
                let url = URL(string: "mailto:\(email)?subject=BuoyFinder for iOS")
                self.openURL(url)
            case 1:
                let url = URL(string: "itms-apps://itunes.apple.com/app/id945847570")
                self.openURL(url)
            case 2:
                let url = URL(string: "https://mpiannucci.appspot.com")
                self.openURL(url)
            default:
                break
            }
        default:
            break
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }

    fileprivate func openURL(_ url: URL?) {
        guard let url = url else { return }
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }

}
