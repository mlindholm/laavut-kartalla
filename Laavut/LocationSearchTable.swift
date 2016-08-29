//
//  LocationSearchTable.swift
//  Laavut
//
//  Created by Mathias Lindholm on 29.08.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit

class LocationSearchTable: UITableViewController, UISearchResultsUpdating {
    var filteredLocations = [Location]()

    override func viewDidLoad() {
        super.viewDidLoad()
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

        cell.textLabel?.text = location.title
        cell.detailTextLabel?.text = location.subtitle

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showSearchDetail" {
            if let vc = segue.destinationViewController as? DetailViewController {
                guard let indexPath = self.tableView?.indexPathForSelectedRow else { return }
                vc.location = filteredLocations[indexPath.row]
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
            filteredLocations = Array(result)
        } else {
            filteredLocations = []
        }

        tableView.reloadData()
    }

    func updateSearchResultsForSearchController(searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}