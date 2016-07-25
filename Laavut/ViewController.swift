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

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    let locationManager = CLLocationManager()
    let defaults = NSUserDefaults.standardUserDefaults()
    let initialLocation = CLLocation(latitude: 60.1699, longitude: 24.9384)
    let regionRadius: CLLocationDistance = 1000
    var mapChangedFromUserInteraction = false
    var fetchAllLaavuTask: NSURLSessionTask?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var locateButton: UIBarButtonItem!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let coordinateRegion = MKCoordinateRegionMakeWithDistance(initialLocation.coordinate, regionRadius * 100.0, regionRadius * 100.0)
        mapView.setRegion(coordinateRegion, animated: false)

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

    //MARK: - Map

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Location"
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView

        if annotation is MKUserLocation {
            return nil
        }

        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView!.canShowCallout = true
            let btn = UIButton(type: .DetailDisclosure)
            annotationView!.rightCalloutAccessoryView = btn
        } else {
            annotationView!.annotation = annotation
        }

        return annotationView
    }

    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        self.performSegueWithIdentifier("showDetail", sender: view)
    }

    func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        locationManager.stopUpdatingLocation()
    }

    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.75, longitudeDelta: 0.75))
            self.mapView.setRegion(region, animated: false)
        }
    }

    //MARK: - Actions

    @IBAction func locateButtonPressed(sender: AnyObject) {
        locationManager.requestAlwaysAuthorization()
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
        case _ where daysAgo == 0:
            if let locations = retrieveLocations() {
                addAnnotationsToMap(locations)
            }
        default:
            fatalError()
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
            fetchAllLaavuTask = Network.load() { [weak self] locations in
                self?.saveLocations(locations)
                self?.addAnnotationsToMap(locations)
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

    func addAnnotationsToMap(locations: [Location]) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.mapView.addAnnotations(locations)
        })
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