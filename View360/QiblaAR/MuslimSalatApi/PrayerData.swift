//
//  PrayerData.swift
//  View360
//
//  Created by Waqqas Sheikh on 9/5/16.
//  Copyright © 2016 asfour. All rights reserved.
//

import Foundation
import ObjectMapper

class PrayerData : Mappable, CustomStringConvertible{
    
    var latitude : Double = 0
    var longitude : Double = 0
    var state: String?
    var country: String?
    var countryCode: String?
    var qiblaDirectionDegrees: Double = 0
    
    var description: String{
        return
            "Latitude: \(self.latitude),"
                + "Longitude: \(self.longitude),"
                + " Country: \(self.country),"
                + "Qibla: \(self.qiblaDirectionDegrees)"
    }
    
    required init?(_ map: Map){
        if map.JSONDictionary["latitude"] == nil {
            return nil
        }
        if map.JSONDictionary["longitude"] == nil{
            return nil
        }
        if map.JSONDictionary["qibla_direction"] == nil{
            return nil
        }
    }
    
    func mapping(map: Map) {
        let transform = TransformOf<Double, String>(
            fromJSON: { (value: String?) -> Double? in
                return Double(value!)
            },
            toJSON: { (value: Double?) -> String? in
                return value == nil ? nil : String(value)
            }
        )

        
        latitude <- (map["latitude"],transform)
        longitude <- (map["longitude"],transform)
        state <- map["state"]
        country <- map["country"]
        countryCode <- map["country_code"]
        qiblaDirectionDegrees <- (map["qibla_direction"],transform)
    }
}