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

class DetailViewController: UIViewController, MKMapViewDelegate {
    let regionRadius: CLLocationDistance = 1000
    var location: Location?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var commentLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let location = location else { return }

        mapView.delegate = self
        mapView.centerOnLocation(location.coordinate, animated: false, multiplier: 10.0)

        let pin = MKPointAnnotation()
        pin.coordinate = location.coordinate
        mapView.addAnnotation(pin)

        titleLabel.text = location.title
        subtitleLabel.text = location.subtitle
        timeLabel.text = location.time?.dateToString()

        if let comment = location.comment {
            commentLabel.hidden = false
            commentLabel.text = comment
        } else {
            commentLabel.hidden = true
        }
    }

    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "pin")
        pinView.pinTintColor = Colors.Green
        return pinView
    }

    func openInAppleMaps(location: Location) {
        let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = location.title
        mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }

    @IBAction func directionsButtonPressed(sender: AnyObject) {
        if let location = location {
            openInAppleMaps(location)
        }
    }
}