//
//  MKMapViewExtension.swift
//  Laavut
//
//  Created by Mathias Lindholm on 25.07.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import MapKit

extension MKMapView {
    func centerOnLocation(location: CLLocationCoordinate2D, animated: Bool, multiplier: Double) {
        let regionRadius: CLLocationDistance = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location, regionRadius * multiplier, regionRadius * multiplier)
        self.setRegion(coordinateRegion, animated: animated)
    }
}