//
//  Location.swift
//  Laavut
//
//  Created by Mathias Lindholm on 29.08.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import UIKit
import MapKit
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

func archiveLocations(locations:[Location]) -> NSData {
    let archivedObject = NSKeyedArchiver.archivedDataWithRootObject(locations as NSArray)
    return archivedObject
}

func saveLocations(locations: [Location]) {
    let archivedObject = archiveLocations(locations)
    let defaults = NSUserDefaults.standardUserDefaults()
    defaults.setObject(archivedObject, forKey: "annotations")
    defaults.setObject(NSDate(), forKey: "saveLocationsDate")
}

func retrieveLocations() -> [Location]? {
    if let unarchivedObject = NSUserDefaults.standardUserDefaults().objectForKey("annotations") as? NSData {
        return NSKeyedUnarchiver.unarchiveObjectWithData(unarchivedObject) as? [Location]
    }
    return nil
}