//
//  Network.swift
//  Laavut
//
//  Created by Mathias Lindholm on 21.7.2016.
//  Copyright © 2016 Mathias Lindholm. All rights reserved.
//

import Foundation
import SwiftyXMLParser

struct Network {

    static func load(completion: ([Item]) -> Void) -> NSURLSessionTask? {
        let urlString = NSURL(string: "http://laavu.org/lataa.php?paikkakunta=kaikki")
        let request = NSURLRequest(URL: urlString!)

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {(data, response, error) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                let statusCode = (response as? NSHTTPURLResponse)?.statusCode
                print(statusCode)

                if let err = error {
                    print(err.localizedDescription)
                    completion([])
                    return
                }

                guard let data = data where error == nil else {
                    completion([])
                    return
                }

                let optionalLaavu = asd(data)
                completion(optionalLaavu)
            })
        })
        
        task.resume()
        return task
    }

    static func asd(data: NSData) -> [Item] {
        var itemsArray = [Item]()
        do {
            let xmlObject = try! XML.parse(data)
            for element in xmlObject["gpx", "wpt"] {
                guard let item = Item(xml: element) else { continue }
                itemsArray.append(item)
            }
        } catch {
            debugPrint("Error parsing tags JSON")
        }
        return itemsArray

    }
}