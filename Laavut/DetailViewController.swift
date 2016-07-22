//
//  DetailViewController.swift
//  Laavut
//
//  Created by Mathias Lindholm on 22.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import MapKit
import AddressBook

class DetailViewController: UIViewController {
    let regionRadius: CLLocationDistance = 1000
    var location: Location?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var typeLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let location = location else { return }

        mapView.mapType = .Standard
        mapView.zoomEnabled = true
        mapView.scrollEnabled = true
        centerMapOnLocation(location)

        titleLabel.text = location.title
        typeLabel.text = location.type
        timeLabel.text = location.time?.dateToString()

        subtitleLabel.hidden = true

        if let subtitle = location.subtitle {
            subtitleLabel.hidden = false
            subtitleLabel.text = subtitle
        }
    }

    func centerMapOnLocation(location: Location) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius * 10.0, regionRadius * 10.0)
        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        mapView.addAnnotation(pin)
        mapView.setRegion(coordinateRegion, animated: false)
    }

    func openInAppleMaps(location: Location) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
            mapItem.name = location.title
            mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
        })
    }

    @IBAction func directionsButtonPressed(sender: AnyObject) {
        if let location = location {
            openInAppleMaps(location)
        }
    }
}