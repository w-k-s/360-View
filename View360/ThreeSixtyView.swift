//
//  EquitorialPlane.swift
//  View360
//
//  Created by Waqqas Sheikh on 8/27/16.
//  Copyright © 2016 asfour. All rights reserved.
//
import UIKit
import Foundation
import CoreLocation
import CoreMotion

// MARK: - String Extension

extension String{
    func drawAtPoint(point: CGPoint){
        let font = UIFont(name: "Arial", size: 12)
        let attributes : [String:AnyObject] = [
            NSFontAttributeName: font!,
            NSForegroundColorAttributeName: UIColor.whiteColor()
        ]
        self.drawAtPoint(point,withAttributes: attributes)
    }
    
    func drawAtPoint(point: CGPoint, withAttributes attributes: [String:AnyObject]){
        let text = self as NSString
        text.drawAtPoint(point, withAttributes: attributes)
    }
}


// MARK: - Radians

typealias Radians = Double

extension Radians{
    static func fromDegrees(degrees: Double)->Radians{
        return degrees * M_PI / 180
    }
    
    init(radians : Double){
        self = radians
    }
    
    var degrees : Double {
        return self * 180 / M_PI
    }
}

// MARK: - ThreeSixtyView

class ThreeSixtyView: UIView, CLLocationManagerDelegate{

    //MARK: - Component 
    
    struct Component{
        let name: String
        let angle: Radians
        let color: UIColor
        let size : CGSize
        private var bounds : CGRect?
        
        init(name: String,angle: Radians,size: CGSize, color: UIColor){
            self.name = name
            self.angle = angle
            self.color = color
            self.size = size
        }
    }
    
    var radius : Double{
        return 1000//Double(self.bounds.width/2)
    }
    var circumference : Double{
        return 2 * M_PI * radius;
    }
    
    private var components : [Component] = []
    
    private var locationManager = CLLocationManager()
    
    var heading: CLHeading?{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    private var motionManager = CMMotionManager()
    private var motionQueue = NSOperationQueue()
    private var accelerationQueue = NSOperationQueue()
    
    var attitude : CMAttitude?{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var acceleration : CMAcceleration?{
        didSet{
            if (self.acceleration?.x >= 0.75) {
                self.locationManager.headingOrientation = CLDeviceOrientation.LandscapeLeft
            }
            else if (self.acceleration?.x <= -0.75) {
                self.locationManager.headingOrientation = CLDeviceOrientation.LandscapeRight
            }
            else if (self.acceleration?.y <= -0.75) {
                self.locationManager.headingOrientation = CLDeviceOrientation.Portrait
            }
            else if (self.acceleration?.y >= 0.75) {
                self.locationManager.headingOrientation = CLDeviceOrientation.PortraitUpsideDown
            }
            setNeedsDisplay()
        }
    }
    
    var drawingRect : Bool = false
    
    var displayRect: CGRect{
        let degrees = self.heading?.magneticHeading ?? 0
        let x = CGFloat(Radians.fromDegrees(degrees) * self.radius)
        return CGRect(x: x, y: 0, width: self.bounds.width, height: self.bounds.height)
    }
    
    override func awakeFromNib() {
        self.setupView()
    }
    
    func setupView(){
        
        self.locationManager.delegate = self
        self.locationManager.headingOrientation = CLDeviceOrientation.init(rawValue: Int32(UIDevice.currentDevice().orientation.rawValue))!
        self.locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        self.locationManager.headingFilter = 1
        self.locationManager.startUpdatingHeading()
        
        self.motionManager.deviceMotionUpdateInterval = 0.1
        self.motionManager.startDeviceMotionUpdatesUsingReferenceFrame(
        CMAttitudeReferenceFrame.XArbitraryZVertical
        , toQueue: self.motionQueue){
            [unowned self] (motion,error) in
            self.attitude = motion?.attitude
        }
        
        self.motionManager.accelerometerUpdateInterval = 0.1
        self.motionManager.startAccelerometerUpdatesToQueue(self.accelerationQueue){
            [unowned self] (accelerometer,error) in
            self.acceleration = accelerometer?.acceleration
        }
    }
    
    deinit{
        self.locationManager.stopUpdatingHeading()
        self.motionManager.stopDeviceMotionUpdates()
        self.motionManager.stopAccelerometerUpdates()
    }

    func append(component : Component){
        self.components.append(component)
        self.calculateComponentBounds()
        self.setNeedsDisplay()
    }
    
    private func calculateComponentBounds(){
        
        for (i,_) in self.components.enumerate(){
            let x = self.bounds.width/2 + CGFloat(self.components[i].angle * self.radius)
            let y = CGFloat(self.bounds.height/2 - self.components[i].size.height/2)
            self.components[i].bounds = CGRect(
                x: x,
                y: y,
                width: self.components[i].size.width,
                height: self.components[i].size.height
            )
        }
    }
    
    // MARK: - Drawing
    
    override func drawRect(rect: CGRect) {
        if drawingRect { return }
        
        drawingRect = true
        
        self.drawInfo(CGPoint(x: 0,y: 50))
        for component in self.components{
            guard component.bounds != nil else{ continue }
            self.layer.sublayers?.removeAll()
            if component.bounds!.intersects(displayRect){
                self.drawComponent(component)
            }
        }
        
        drawingRect = false
    }
    
    func drawInfo(point: CGPoint){
        
        let heading = String(format: "%.0f",(self.heading?.magneticHeading ?? 0))
        let display = self.displayRect
        let startX = String(format: "%.0f", display.origin.x)
        let endX = String(format: "%0.f", display.origin.x + display.width)
        
        let pitchRadians = Radians(self.attitude?.pitch ?? 0)
        let pitch = String(format: "%.0f", pitchRadians.degrees )
        
        "Angle:\(heading), Start X: \(startX), End X: \(endX), Pitch: \(pitch))".drawAtPoint(point)
    }
    
    func drawComponent(component: Component){
        
        let circleLayer = CAShapeLayer()
        let relativeComponentBounds = CGRect(
            x: component.bounds!.origin.x - (displayRect.origin.x),
            y: component.bounds!.origin.y,
            width:  component.bounds!.width,
            height: component.bounds!.height
        )
        circleLayer.fillColor = component.color.CGColor
        circleLayer.strokeColor = component.color.CGColor
        circleLayer.path = UIBezierPath(ovalInRect: relativeComponentBounds).CGPath
        self.layer.addSublayer(circleLayer)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let firstHeading = self.heading == nil
        self.heading = newHeading
        if firstHeading {
            self.calculateComponentBounds()
        }
    }
}