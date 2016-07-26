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
import Fabric
import Crashlytics

class DetailViewController: UIViewController, MKMapViewDelegate {
    let regionRadius: CLLocationDistance = 1000
    let pin = MKPointAnnotation()
    var orginalMapHeigh = CGFloat()
    var fullScreen = false
    var location: Location?

    @IBOutlet var mapView: MKMapView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var commentLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var timeLabel: UILabel!
    @IBOutlet var mapHeight: NSLayoutConstraint!
    @IBOutlet var fullscreenButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let location = location else { return }

        orginalMapHeigh = mapHeight.multiplier

        mapView.delegate = self
        mapView.centerOnLocation(location.coordinate, animated: false, multiplier: 10.0)

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
        pinView.pinTintColor = UIColor.green()
        return pinView
    }

    func openInAppleMaps(location: Location) {
        let coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = location.title
        mapItem.openInMapsWithLaunchOptions([MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
    }

    func animateMapHeight() {
        UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseInOut, animations: {
            self.view.layoutIfNeeded()
            }, completion: nil)
    }

    @IBAction func directionsButtonPressed(sender: AnyObject) {
        if let location = location {
            openInAppleMaps(location)
            Answers.logCustomEventWithName("Button Pressed", customAttributes: ["Button": "Directions button"])
        }
    }

    @IBAction func fullscreenButtonPressed(sender: AnyObject) {
        if fullScreen == false {
            fullScreen = true
            fullscreenButton.image = UIImage.init(named: "ic_fullscreen_exit")
            mapHeight = mapHeight.setMultiplier(1.0)
            animateMapHeight()
            Answers.logCustomEventWithName("Button Pressed", customAttributes: ["Button": "Fullscreen button"])
        } else {
            fullScreen = false
            fullscreenButton.image = UIImage.init(named: "ic_fullscreen")
            mapHeight = mapHeight.setMultiplier(orginalMapHeigh)
            animateMapHeight()
        }
    }
}