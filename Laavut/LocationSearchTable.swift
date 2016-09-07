//
//  LocationSearchTable.swift
//  Laavut
//
//  Created by Mathias Lindholm on 29.08.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import MapKit

class LocationSearchTable: UITableViewController, UISearchResultsUpdating {
    var currentLocation = CLLocation()
    var filteredLocations = [Location]()

    @IBOutlet var emptyState: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        emptyState.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLocations.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("locationCell", forIndexPath: indexPath)
        let location = filteredLocations[indexPath.row]
        let toLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distance = currentLocation.distanceFromLocation(toLocation)
        let distanceKm = (distance/1000).roundToPlaces(1)

        cell.textLabel?.text = location.title
        cell.detailTextLabel?.text = "\(distanceKm) km"

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSearchDetail" {
            if let vc = segue.destinationViewController as? MapViewController {
                guard let indexPath = self.tableView?.indexPathForSelectedRow else { return }
                vc.selectedSearchLocation = filteredLocations[indexPath.row]
            }
        }
    }

    // MARK: - Search

    func filterContentForSearchText(searchText: String) {
        guard let locationsArray = retrieveLocations() else { return }

        let searchTextArray = searchText.lowercaseString.componentsSeparatedByString(" ")
        var searchResults: [Set<Location>] = []

        for item in searchTextArray where !item.isEmpty {
            let searchResult = locationsArray.filter { location in
                let title = location.title!.lowercaseString.containsString(item)
                return title
            }
            searchResults.append(Set(searchResult))
        }

        if let first = searchResults.first {
            var result = first
            for item in searchResults[1..<searchResults.count] {
                result = result.intersect(item)
            }
            let sortedResult = result.sort({ $0.title < $1.title })
            filteredLocations = Array(sortedResult)
        } else {
            filteredLocations = []
        }

        if !searchText.isEmpty && filteredLocations.isEmpty {
            emptyState.hidden = false
            emptyState.text = "Ei tuloksia haulla '\(searchText)'"
        } else {
            emptyState.hidden = true
        }

        tableView.reloadData()
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}