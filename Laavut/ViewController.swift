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

class Item: NSObject, MKAnnotation {
    let title: String?
    let subtitle: String?
    let latitude: Double
    let longitude: Double
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    init?(xml: XML.Accessor) {
        guard let lat = xml.attributes["lat"],
            let lon = xml.attributes["lon"],
            let name = xml["name"].text else {
                return nil
        }

        self.latitude = Double(lat)!
        self.longitude = Double(lon)!
        self.title = name
        self.subtitle = xml["cmt"].text
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    var itemsArray = [Item]()
    let locationManager = CLLocationManager()
    var mapChangedFromUserInteraction = false
    var fetchAllLaavuTask: NSURLSessionTask?

    @IBOutlet var mapView: MKMapView!

    //MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

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

        fetchAllLaavuTask = Network.load() { [weak self] items in
            self?.itemsArray = items
            self?.mapView.addAnnotations(items)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        mapView.showsUserLocation = true
    }

    override func viewWillDisappear(animated: Bool) {
        mapView.showsUserLocation = false
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

    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0))
            self.mapView.setRegion(region, animated: false)
        }
    }
}