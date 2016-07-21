//
//  Network.swift
//  Laavut
//
//  Created by Mathias Lindholm on 21.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation

class Downloader {
    class func load(url: String) {
        guard let urlString = NSURL(string: url) else { return }
        let request = NSURLRequest(URL: urlString)

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            guard let gpx = data else { return }
            let statusCode = (response as? NSHTTPURLResponse)?.statusCode
            xml = try! XML.parse(data) // -> XML.Accessor
            print(xml)
        })
        
        // do whatever you need with the task e.g. run
        task.resume()
    }
}