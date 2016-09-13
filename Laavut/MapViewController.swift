//
//  MapViewController.swift
//  Laavut
//
//  Created by Mathias Lindholm on 20.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import SwiftyXMLParser
import AnnotationClustering
import Fabric
import Crashlytics

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ClusterManagerDelegate, UISearchBarDelegate {
    let locationManager = CLLocationManager()
    let defaults = NSUserDefaults.standardUserDefaults()
    let initialLocation = CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384)
    let clusterManager = ClusterManager()
    var searchController: UISearchController?
    var fetchAllLocationTask: NSURLSessionTask?
    var selectedSearchLocation: Location?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var locateButton: UIBarButtonItem!
    @IBOutlet var searchButton: UIBarButtonItem!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationController?.navigationBar.translucent = false

        checkForUpdates()

        locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.startUpdatingLocation()
        }

        if let locations = retrieveLocations() {
            self.clusterManager.addAnnotations(locations)
        }
        clusterManager.delegate = self
        clusterManager.maxZoomLevel = 10

        mapView.delegate = self
        mapView.showsScale = true
        mapView.centerOnLocation(initialLocation, animated: false, multiplier: 100.0)
    }

    override func viewDidAppear(animated: Bool) {
        mapView.showsUserLocation = true
    }

    override func viewWillDisappear(animated: Bool) {
        mapView.showsUserLocation = false
        fetchAllLocationTask?.cancel()
    }

    //MARK: - Map

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let region = MKCoordinateRegion(center: location.coordinate, span: MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75))
            self.mapView.setRegion(region, animated: false)
            locationManager.stopUpdatingLocation()
        }
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool){
        NSOperationQueue().addOperationWithBlock { [unowned self] in
            let mapBoundsWidth = Double(mapView.bounds.size.width)
            let mapRectWidth: Double = mapView.visibleMapRect.size.width
            let scale: Double = mapBoundsWidth / mapRectWidth
            let annotationArray = self.clusterManager.clusteredAnnotationsWithinMapRect(self.mapView.visibleMapRect, withZoomScale:scale)
            self.clusterManager.displayAnnotations(annotationArray, mapView: mapView)
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        var reuseId = ""

        switch annotation {
        case is MKUserLocation:
            return nil // show Apple's default user location pin

        case let cluster as AnnotationCluster:
            reuseId = "Cluster"
            if let clusterView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? AnnotationClusterView {
                clusterView.reuseWithAnnotation(cluster)
                return clusterView
            } else {
                let options = AnnotationClusterViewOptions(smallClusterImage: "cluster_small", mediumClusterImage: "cluster_medium", largeClusterImage: "cluster_large")
                let clusterView = AnnotationClusterView(annotation: cluster, reuseIdentifier: reuseId, options: options)
                return clusterView
            }

        default:
            reuseId = "Pin"
            if let pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView {
                pinView.annotation = annotation
                return pinView
            } else {
                let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
                pinView.canShowCallout = true
                pinView.pinTintColor = UIColor.green()
                let btn = UIButton(type: .DetailDisclosure)
                pinView.rightCalloutAccessoryView = btn
                return pinView
            }
        }
    }

    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let view = view as? AnnotationClusterView {
            guard let coordinate = view.annotation?.coordinate else { return }
            if view.count > 100 {
                mapView.centerOnLocation(coordinate, animated: true, multiplier: 50.0)
            } else {
                mapView.centerOnLocation(coordinate, animated: true, multiplier: 25.0)
            }
        }
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.performSegueWithIdentifier("showDetail", sender: view)
        Answers.logCustomEventWithName("Button Pressed", customAttributes: ["Button": "Pin callout accessory"])
    }

    func cellSizeFactorForManager(manager: ClusterManager) -> CGFloat {
        return 1.0
    }

    //MARK: - Actions

    @IBAction func locateButtonPressed(sender: AnyObject) {
        locationManager.startUpdatingLocation()
        Answers.logCustomEventWithName("Button Pressed", customAttributes: ["Button": "Locate me button"])
    }

    @IBAction func searchButtonPressed(sender: AnyObject) {
        configureSearchBar()
        showSearchBar()
    }

    @IBAction func showSearchDetail(segue: UIStoryboardSegue) {
        self.hideSearchBar()
        self.performSegueWithIdentifier("showSearchDetail", sender: view)
    }


    //MARK: - Locations

    func checkForUpdates() {
        let saveLocationsDate = defaults.objectForKey("saveLocationsDate") as? NSDate
        let daysAgo = saveLocationsDate?.daysAgo

        switch daysAgo {
        case nil:
            fetchAllLocations()
        case _ where daysAgo >= 1:
            fetchAllLocations()
        default:
            return
        }
    }

    func fetchAllLocations() {
        let reachability: Reachability

        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }

        if reachability.isReachable() {
            fetchAllLocationTask = Network.load() { [weak self] locations in
                saveLocations(locations)
                self?.clusterManager.addAnnotations(locations)
            }
        }
    }

    // MARK: - Search

    func configureSearchBar() {
        let locationSearchTable = storyboard!.instantiateViewControllerWithIdentifier("LocationSearchTable") as! LocationSearchTable
        if let current = locationManager.location {
            locationSearchTable.currentLocation = current
        }
        searchController = UISearchController(searchResultsController: locationSearchTable)
        searchController?.searchResultsUpdater = locationSearchTable
        searchController?.hidesNavigationBarDuringPresentation = false
        searchController?.dimsBackgroundDuringPresentation = true
        searchController?.searchBar.delegate = self
        searchController?.searchBar.autocapitalizationType = .None
        searchController?.searchBar.spellCheckingType = .No
        searchController?.searchBar.tintColor = UIColor.blue()
        searchController?.searchBar.setBackgroundImage(UIImage(), forBarPosition: .Any, barMetrics: .Default)
        searchController?.searchBar.setShowsCancelButton(true, animated: true)
        definesPresentationContext = true
        UIBarButtonItem.appearanceWhenContainedInInstancesOfClasses([UISearchBar.self]).tintColor = UIColor.whiteColor()
    }

    func showSearchBar() {
        guard let searchBar = searchController?.searchBar else { return }
        let viewForSearchBar = UIView.init(frame: searchBar.bounds)
        viewForSearchBar.addSubview(searchBar)
        navigationItem.titleView = viewForSearchBar
        navigationItem.leftBarButtonItem = nil
        navigationItem.rightBarButtonItem = nil
        searchController?.searchBar.becomeFirstResponder()
    }

    func hideSearchBar() {
        navigationItem.titleView = nil
        navigationItem.leftBarButtonItem = self.searchButton
        navigationItem.rightBarButtonItem = self.locateButton
        searchController?.searchBar.resignFirstResponder()
    }

    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarTextDidEndEditing(searchBar: UISearchBar) {
        hideSearchBar()
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {
            if let vc = segue.destinationViewController as? DetailViewController {
                let locationToPass = sender?.annotation as? Location
                vc.location = locationToPass
            }
        } else if segue.identifier == "showSearchDetail", let location = selectedSearchLocation {
            if let vc = segue.destinationViewController as? DetailViewController {
                vc.location = location
            }
        }
    }
}