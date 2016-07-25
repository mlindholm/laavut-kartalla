//
//  ViewController.swift
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

class Location: NSObject, MKAnnotation {
    let latitude: Double
    let longitude: Double
    let title: String?
    let subtitle: String?
    let time: NSDate?
    let comment: String?
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init?(xml: XML.Accessor) {
        guard let latitude = xml.attributes["lat"],
            let longitude = xml.attributes["lon"],
            let title = xml["name"].text,
            let time = xml["time"].text?.stringToDate(),
            let subtitle = xml["sym"].text else {
                return nil
        }

        switch subtitle {
        case "Campground":
            self.subtitle = "Kota tien varressa"
        case "Lodge":
            self.subtitle = "Laavu maastossa"
        case "Picnic Area":
            self.subtitle = "Laavu tien varressa"
        default:
            self.subtitle = nil
        }

        self.latitude = Double(latitude)!
        self.longitude = Double(longitude)!
        self.title = title
        self.comment = xml["cmt"].text
        self.time = time
    }

    required init(coder aDecoder: NSCoder) {
        latitude = aDecoder.decodeObjectForKey("latitude") as! Double
        longitude = aDecoder.decodeObjectForKey("longitude") as! Double
        title = aDecoder.decodeObjectForKey("title") as? String
        subtitle = aDecoder.decodeObjectForKey("subtitle") as? String
        time = aDecoder.decodeObjectForKey("time") as? NSDate
        comment = aDecoder.decodeObjectForKey("comment") as? String
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(latitude, forKey: "latitude")
        aCoder.encodeObject(longitude, forKey: "longitude")
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(subtitle, forKey: "subtitle")
        aCoder.encodeObject(time, forKey: "time")
        aCoder.encodeObject(comment, forKey: "comment")
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, ClusterManagerDelegate {
    let locationManager = CLLocationManager()
    let defaults = NSUserDefaults.standardUserDefaults()
    let initialLocation = CLLocationCoordinate2D(latitude: 60.1699, longitude: 24.9384)
    let clusterManager = ClusterManager()
    var mapChangedFromUserInteraction = false
    var fetchAllLocationTask: NSURLSessionTask?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var locateButton: UIBarButtonItem!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        checkForUpdates()

        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }

        if let locations = retrieveLocations() {
            clusterManager.addAnnotations(locations)
        }
        clusterManager.delegate = self
        clusterManager.maxZoomLevel = 10

        mapView.delegate = self
        mapView.showsScale = true
        mapView.centerOnLocation(initialLocation, animated: false, multiplier: 100.0)


        if let coordinate = mapView.userLocation.location?.coordinate{
            mapView.setCenterCoordinate(coordinate, animated: false)
        }
    }

    override func viewWillDisappear(animated: Bool) {
        mapView.showsUserLocation = false
        fetchAllLocationTask?.cancel()
    }

    //MARK: - Map

    func cellSizeFactorForManager(manager: ClusterManager) -> CGFloat {
        return 1.0
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
                let clusterView = AnnotationClusterView(annotation: cluster, reuseIdentifier: reuseId, options: nil)
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
                pinView.pinTintColor = Colors.Green
                let btn = UIButton(type: .DetailDisclosure)
                pinView.rightCalloutAccessoryView = btn
                return pinView
            }
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
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75))
            self.mapView.setRegion(region, animated: false)
            locationManager.stopUpdatingLocation()
        }
    }

    //MARK: - Actions

    @IBAction func locateButtonPressed(sender: AnyObject) {
        locationManager.startUpdatingLocation()
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
                self?.saveLocations(locations)
                self?.clusterManager.addAnnotations(locations)
            }
        }
    }

    func archiveLocations(locations:[Location]) -> NSData {
        let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(locations as NSArray)
        return archivedObject
    }

    func saveLocations(locations: [Location]) {
        let archivedObject = archiveLocations(locations)
        defaults.setObject(archivedObject, forKey: "annotations")
        defaults.setObject(NSDate(), forKey: "saveLocationsDate")
    }

    func retrieveLocations() -> [Location]? {
        if let unarchivedObject = NSUserDefaults.standardUserDefaults().objectForKey("annotations") as? NSData {
            return NSKeyedUnarchiver.unarchiveObjectWithData(unarchivedObject) as? [Location]
        }
        return nil
    }

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showDetail" {

            if let vc = segue.destinationViewController as? DetailViewController {
                let locationToPass = sender?.annotation as? Location
                vc.location = locationToPass
            }
        }
    }
}