//
//  NSDateExtension.swift
//  Laavut
//
//  Created by Mathias Lindholm on 21.07.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

extension NSDate {
    var daysAgo: Int {
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Day], fromDate: self, toDate: NSDate(), options: [])
        return components.day
    }
}