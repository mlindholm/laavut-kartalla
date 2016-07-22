//
//  StringExtension.swift
//  Laavut
//
//  Created by Mathias Lindholm on 22.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

extension String {
    func stringToDate(format: String = "yyyy-MM-dd'T'HH:mm:ssZ") -> NSDate {
        let formatter = NSDateFormatter()
        formatter.dateFormat = format
        return formatter.dateFromString(self)!
    }
}