//
//  LocationsTableViewController.swift
//  Locationer
//
//  Created by CSSE Department on 7/21/15.
//  Copyright (c) 2015 Rose-Hulman. All rights reserved.
//

import UIKit
import CoreData
import GoogleMaps

class LocationsTableViewController: UITableViewController, NSFetchedResultsControllerDelegate {

    var locationDetailViewController: LocationDetailViewController? = nil
    var managedObjectContext: NSManagedObjectContext? = nil
    var markers : [GMSMarker]?
    let klocationCellIdentifier = "LocationCellIdentifier"

    override func viewDidAppear(animated: Bool) {
//        let loc1 : Location = NSEntityDescription.insertNewObjectForEntityForName("Location", inManagedObjectContext: CoreDataUtils.managedObjectContext()) as! Location
//        loc1.name = "Parking Spot"
//        loc1.desc = "At Work"
//        loc1.isFavorite = true
//        loc1.lat = 1
//        loc1.lon = 1
//        loc1.dateAdded = NSDate()
        self._saveContext()
    }


    override func awakeFromNib() {
        super.awakeFromNib()
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            self.clearsSelectionOnViewWillAppear = false
            self.preferredContentSize = CGSize(width: 320.0, height: 600.0)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        self.navigationItem.leftBarButtonItem = self.editButtonItem()

//        let addButton = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: "insertNewObject:")
//        self.navigationItem.rightBarButtonItem = addButton
        if let split = self.splitViewController {
            let controllers = split.viewControllers
            self.locationDetailViewController = controllers[controllers.count-1].topViewController as? LocationDetailViewController
        }
        self.navigationController?.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Edit, target: self, action: "toggleEdit")
    }
    func toggleEdit(){
        self.tableView.endEditing(!self.tableView.editing)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func _saveContext(){
        // Save the context.
        var error: NSError? = nil
        if self.fetchedResultsController.managedObjectContext.hasChanges && !self.fetchedResultsController.managedObjectContext.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }

    // MARK: - Segues

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let indexPath = self.tableView.indexPathForSelectedRow() {
                let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Location
                let destination = segue.destinationViewController as! LocationDetailViewController
                destination.location = location
            }
        }
    }

    // MARK: - Table View

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return self.fetchedResultsController.sections?.count ?? 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionInfo = self.fetchedResultsController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(klocationCellIdentifier, forIndexPath: indexPath) as! LocationTableViewCell
        self._configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }

    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let context = self.fetchedResultsController.managedObjectContext
            let location = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Location
            let count = self.markers?.count
            if let markerArray = self.markers{
                for marker in markerArray{
                    println("location \(location.name) with lat \(location.lat.doubleValue) and marker lat of \(marker.position.latitude)")
                    if (location.lat.doubleValue == marker.position.latitude) && (location.lon.doubleValue == marker.position.longitude){
                        marker.map = nil
                    }
                }
            }
            context.deleteObject(self.fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
                
            var error: NSError? = nil
            if !context.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(error), \(error.userInfo)")
                abort()
            }
        }
    }
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 60
    }

    func _configureCell(cell: LocationTableViewCell, atIndexPath indexPath: NSIndexPath) {
        let cellLocation = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Location
        cell.configureCellForLocation(cellLocation)
    }

    // MARK: - Fetched results controller

    var fetchedResultsController: NSFetchedResultsController {
        if _fetchedResultsController != nil {
            return _fetchedResultsController!
        }
        
        let fetchRequest = NSFetchRequest()
        // Edit the entity name as appropriate.
        let entity = NSEntityDescription.entityForName("Location", inManagedObjectContext: CoreDataUtils.managedObjectContext())
        fetchRequest.entity = entity
        
        // Set the batch size to a suitable number.
        fetchRequest.fetchBatchSize = 20
        
        // Edit the sort key as appropriate.
        let sortDescriptor = NSSortDescriptor(key: "isFavorite", ascending: false)
        let sortDescriptor2 = NSSortDescriptor(key: "tag.name", ascending: true)
        let sortDescriptor3 = NSSortDescriptor(key: "name", ascending: true)
        let sortDescriptors = [sortDescriptor, sortDescriptor2, sortDescriptor3]
        
        fetchRequest.sortDescriptors = sortDescriptors
        
        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
        let aFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataUtils.managedObjectContext(), sectionNameKeyPath: nil, cacheName: nil)
        aFetchedResultsController.delegate = self
        _fetchedResultsController = aFetchedResultsController
        
    	var error: NSError? = nil
    	if !_fetchedResultsController!.performFetch(&error) {
    	     // Replace this implementation with code to handle the error appropriately.
    	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
             //println("Unresolved error \(error), \(error.userInfo)")
    	     abort()
    	}
        
        return _fetchedResultsController!
    }    

    var _fetchedResultsController: NSFetchedResultsController? = nil

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }

    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        switch type {
            case .Insert:
                self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            case .Delete:
                self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
            case .Insert:
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            case .Delete:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
            case .Update:
                let locationCell = tableView.cellForRowAtIndexPath(indexPath!)! as! LocationTableViewCell
                self._configureCell(locationCell, atIndexPath: indexPath!)
            case .Move:
                tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Fade)
                tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Fade)
            default:
                return
        }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }

    /*
     // Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed.
     
     func controllerDidChangeContent(controller: NSFetchedResultsController) {
         // In the simplest, most efficient, case, reload the table view.
         self.tableView.reloadData()
     }
     */

}

