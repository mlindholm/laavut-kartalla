//
//  DetailViewController.swift
//  Laavut
//
//  Created by Mathias Lindholm on 22.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import MapKit

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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
