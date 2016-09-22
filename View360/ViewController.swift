//
//  ViewController.swift
//  View360
//
//  Created by Waqqas Sheikh on 8/5/16.
//  Copyright © 2016 asfour. All rights reserved.
//

import UIKit
import Alamofire
import SVProgressHUD

class ViewController: UIViewController {

    @IBOutlet var threeSixtyView : ThreeSixtyView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadQiblaDirection()
    }

    func loadQiblaDirection(){
        SVProgressHUD.show()
        MuslimSalatApi.dailyPrayerData { (response: Response<PrayerData, NSError>) in
            SVProgressHUD.dismiss()
            
            if let prayerData = response.result.value{
                
                print("\(prayerData)")
                
                let component = ThreeSixtyView.Component(
                    name: "Forty",
                    angle: Radians.fromDegrees(prayerData.qiblaDirectionDegrees),
                    size: CGSize(width: 25,height: 25),
                    color: UIColor.yellowColor()
                )
                self.threeSixtyView.append(component)
            }else if let error = response.result.error {
                let alert = UIAlertController(
                    title: "Alert",
                    message: error.localizedDescription,
                    preferredStyle: .Alert
                )
                alert.addAction(UIAlertAction(
                    title: "Ok",
                    style: .Default,
                    handler: nil
                ))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    @IBAction func indexChanged(segmentedControl: UISegmentedControl){
        if let method = ThreeSixtyView.HeadingMethod(rawValue: segmentedControl.selectedSegmentIndex){
            self.threeSixtyView.headingMethod = method
        }
    }
}

