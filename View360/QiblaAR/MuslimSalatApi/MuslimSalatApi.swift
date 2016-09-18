//
//  MuslimSalatApi.swift
//  View360
//
//  Created by Waqqas Sheikh on 9/5/16.
//  Copyright © 2016 asfour. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper

class MuslimSalatApi{
    
    
    private static let ApiHost = "http://muslimsalat.com"
    
    private static let EndpointDaily = "daily.json"
    
    private static let ApiKey = "dbbca8c7c65a2e6f14ba9224b427e67e"
    
    static func dailyPrayerData(completion : ((Response<PrayerData,NSError>)->Void)){
        let url = NSURL(string: "\(ApiHost)/\(EndpointDaily)?key=\(ApiKey)")!
        Alamofire.request(.GET, url).responseObject(completionHandler: completion)
    }
}