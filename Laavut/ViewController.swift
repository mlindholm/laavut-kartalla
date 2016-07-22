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

class Location: NSObject, MKAnnotation {
    let latitude: Double
    let longitude: Double
    let title: String?
    let subtitle: String?
    let time: NSDate?
    let type: String?
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init?(xml: XML.Accessor) {
        guard let lat = xml.attributes["lat"],
            let lon = xml.attributes["lon"],
            let name = xml["name"].text,
            let time = xml["time"].text?.stringToDate(),
            let type = xml["sym"].text else {
                return nil
        }

        self.latitude = Double(lat)!
        self.longitude = Double(lon)!
        self.title = name
        self.subtitle = xml["cmt"].text
        self.time = time
        self.type = type
    }

    //MARK: - NSCoding -
    required init(coder aDecoder: NSCoder) {
        latitude = aDecoder.decodeObjectForKey("latitude") as! Double
        longitude = aDecoder.decodeObjectForKey("longitude") as! Double
        title = aDecoder.decodeObjectForKey("title") as? String
        subtitle = aDecoder.decodeObjectForKey("subtitle") as? String
        time = aDecoder.decodeObjectForKey("time") as? NSDate
        type = aDecoder.decodeObjectForKey("type") as? String
    }

    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(latitude, forKey: "latitude")
        aCoder.encodeObject(longitude, forKey: "longitude")
        aCoder.encodeObject(title, forKey: "title")
        aCoder.encodeObject(subtitle, forKey: "subtitle")
        aCoder.encodeObject(time, forKey: "time")
        aCoder.encodeObject(type, forKey: "type")
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    let locationManager = CLLocationManager()
    let defaults = NSUserDefaults.standardUserDefaults()
    let initialLocation = CLLocation(latitude: 60.1699, longitude: 24.9384)
    let regionRadius: CLLocationDistance = 1000
    var mapChangedFromUserInteraction = false
    var fetchAllLaavuTask: NSURLSessionTask?

    @IBOutlet var mapView: MKMapView!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        centerMapOnLocation(initialLocation)

        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()

        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }

        mapView.delegate = self
        mapView.mapType = .Standard
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true

        if let coor = mapView.userLocation.location?.coordinate{
            mapView.setCenterCoordinate(coor, animated: false)
        }

        checkForUpdates()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        mapView.showsUserLocation = true
    }

    override func viewWillDisappear(animated: Bool) {
        mapView.showsUserLocation = false
    }

    //MARK: - Locations

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

    func fetchAllLocations() {
        let reachability: Reachability

        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            print("Unable to create Reachability")
            return
        }

        if reachability.isReachable() {
            fetchAllLaavuTask = Network.load() { [weak self] locations in
                self?.saveLocations(locations)
                self?.mapView.addAnnotations(locations)
            }
        }
    }

    func checkForUpdates() {
        let saveLocationsDate = defaults.objectForKey("saveLocationsDate") as? NSDate
        let daysAgo = saveLocationsDate?.daysAgo

        switch daysAgo {
        case nil:
            print("no prior fetch, fetching…")
            fetchAllLocations()
        case _ where daysAgo >= 1:
            print("old fetch, fetching…")
            fetchAllLocations()
        case _ where daysAgo == 0:
            if let locations = retrieveLocations() {
                print("printing…")
                self.mapView.addAnnotations(locations)
            }
        default:
            fatalError()
        }
    }


    //MARK: - Map

    func mapViewRegionDidChangeFromUserInteraction() -> Bool {
        let view = self.mapView.subviews[0]
        //  Look through gesture recognizers to determine whether this region change is from user interaction
        if let gestureRecognizers = view.gestureRecognizers {
            for recognizer in gestureRecognizers {
                if( recognizer.state == UIGestureRecognizerState.Began || recognizer.state == UIGestureRecognizerState.Ended ) {
                    return true
                }
            }
        }
        return false
    }

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        mapChangedFromUserInteraction = mapViewRegionDidChangeFromUserInteraction()
        if (mapChangedFromUserInteraction) {
            locationManager.stopUpdatingLocation()
        }
    }

    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 100.0, regionRadius * 100.0)
        mapView.setRegion(coordinateRegion, animated: false)
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75))
            self.mapView.setRegion(region, animated: false)
        }
    }
}