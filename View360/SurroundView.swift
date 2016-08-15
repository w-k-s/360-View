//
//  SurroundView.swift
//  View360
//
//  Created by Waqqas Sheikh on 8/5/16.
//  Copyright © 2016 asfour. All rights reserved.
//

import UIKit
import CoreMotion

// MARK: - Extensions

extension Double{
    var degrees : Double{
        return self * (180/M_PI)
    }
    
    var clockwiseRotationDegrees : Double{
        var degrees = 360 - self.degrees
        if degrees > 360 {
            degrees %= 360
        }
        return degrees
    }
    
    func roundUpTo(number: Double)->Double{
        return ceil((self / number)) * number
    }
    
    func roundToNearest(number: Double)->Double{
        let roundedToNearest = ((self + (number/2))/number)*number
        return round(roundedToNearest)
    }
}

// MARK: - Body

struct Body{
    let angleDegrees : CGFloat
    let diameter: CGFloat
    
    init(angleDegrees degrees : CGFloat, diameter : CGFloat){
        self.angleDegrees = degrees
        self.diameter = diameter
    }
    
    func boundsWithinCircumference(radius: CGFloat, y: CGFloat)->CGRect{
        let x = ( angleDegrees * radius) - (diameter/2)
        return CGRect(
            x: x,
            y: y,
            width: diameter,
            height: diameter
        )
    }
}

// MARK: - SurroundView

class SurroundView: UIView {
    
    var firstAttitude : CMAttitude?{
        didSet{
            self.attitude = self.firstAttitude
            self.setNeedsDisplay()
        }
    }
    var attitude : CMAttitude?{
        didSet{
            self.setNeedsDisplay()
        }
    }
    var radius : CGFloat{
        return CGFloat(1000/CGFloat(2 * M_PI))
    }
    
    let motionQueue = NSOperationQueue()
    let motionManager = CMMotionManager()
    
    override func awakeFromNib() {
        self.setupView()
    }
    
    func setupView(){
        self.backgroundColor = UIColor.blackColor()
        self.motionManager.deviceMotionUpdateInterval = 20/1000
        self.motionManager.startDeviceMotionUpdatesUsingReferenceFrame(
            CMAttitudeReferenceFrame.XArbitraryZVertical,
            toQueue: motionQueue) {
                (motion, error) in
                
                if motion != nil {
                    NSOperationQueue.mainQueue().addOperationWithBlock{
                        [unowned self] in
                        if self.firstAttitude == nil{
                            self.firstAttitude = motion!.attitude
                        }else{
                            self.attitude = motion!.attitude
                            self.attitude!.multiplyByInverseOfAttitude(self.firstAttitude!)
                        }
                    }
                }
        }
    }
    
    deinit{
        self.motionManager.stopDeviceMotionUpdates()
    }
    
    func resetFirstAttitude(){
        self.firstAttitude = nil
    }
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        
        let perspective = CGRect(
            x: (CGFloat(self.attitude?.roll.clockwiseRotationDegrees ?? 0) * self.radius) ,
            y: 0,
            width: self.bounds.width,
            height: self.bounds.height
        )
        let circleBody = Body(angleDegrees: 45,diameter: 20)
        let circleBodyBounds = circleBody.boundsWithinCircumference(
            self.radius,
            y: (self.bounds.height/2) - (circleBody.diameter/2)
        )
        
        
        if perspective.intersects(circleBodyBounds){
            
            var circleLayer : CAShapeLayer?
            var addedLayer : Bool = false
            
            if self.layer.sublayers != nil{
                for layer in self.layer.sublayers!{
                    if (layer.valueForKey("id" ) as? String) == "circleLayer"{
                        circleLayer = layer as? CAShapeLayer
                        addedLayer = true
                        break
                    }
                }
            }
            
            if circleLayer == nil{
                circleLayer = CAShapeLayer()
                circleLayer!.setValue("circleLayer", forKey: "id")
                circleLayer!.fillColor = UIColor.yellowColor().CGColor
                circleLayer!.strokeColor = UIColor.yellowColor().CGColor
            }
            
            let relativeCircleBodyBounds = CGRect(
                x: circleBodyBounds.origin.x - (perspective.origin.x) ,
                y: circleBodyBounds.origin.y,
                width: circleBodyBounds.width,
                height: circleBodyBounds.height
            )
            
            print("\(relativeCircleBodyBounds.origin.x)")
            
            circleLayer!.path = UIBezierPath(ovalInRect: relativeCircleBodyBounds).CGPath
            if !addedLayer{
                self.layer.addSublayer(circleLayer!)
            }
        }else {
            self.layer.sublayers?.removeAll()
        }
        
        self.printText(
            String(format: "R: %.0f, xP: %.0f - %.0f, xC: %.0f - %.0f, V: %@",
                (self.attitude?.roll.clockwiseRotationDegrees ?? 0),
                perspective.origin.x,
                perspective.origin.x + perspective.width,
                circleBodyBounds.origin.x,
                circleBodyBounds.origin.x + circleBody.diameter,
                (perspective.intersects(circleBodyBounds) ? "Intersects" : "None")
            ),
            point: CGPoint.init(x: 0, y: 30)
        )
        
    }
    
    func printText(text: String,
                   fontSize : CGFloat = 14,
                   point: CGPoint)
    {
        let nsText = text as NSString
        let font = UIFont(name: "Arial", size: fontSize)
        let attrs : [String:AnyObject] = [
            NSFontAttributeName: font!,
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
        
        nsText.drawAtPoint(point, withAttributes: attrs)
    }
    
    
}
