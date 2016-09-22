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
import GLKit

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
    
    var attitude : CMAttitude?{
        didSet{
            self.setNeedsDisplay()
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
        CMAttitudeReferenceFrame.XTrueNorthZVertical
        , toQueue: self.motionQueue){
            [unowned self] (motion,error) in
            self.attitude = motion?.attitude
        }
    }
    
    deinit{
        self.locationManager.stopUpdatingHeading()
        self.motionManager.stopDeviceMotionUpdates()
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

        let elevation = String(format: "%.0f", self.elevationDegrees() ?? 0 )
        let pitchDegrees = Radians(self.motionManager.deviceMotion?.attitude.pitch ?? 0).degrees
        let pitch = String(format: "%.0f", pitchDegrees)
        let whatever = String(format: "%.0f,",self.headingCorrectedForTilt() ?? 0)
        
        "Angle:\(heading), Start X: \(startX), End X: \(endX), Elevation: \(elevation), Pitch: \(pitch))".drawAtPoint(point)
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
    
    // MARK: - GLKit
    
    func elevationDegrees() -> Double?{
        guard let attitude = self.attitude else{
            return nil
        }
        
        let quaternion = attitude.quaternion
        let pitch = Radians(atan2(2 * (quaternion.x * quaternion.w + quaternion.y * quaternion.z), 1 - 2 * quaternion.x * quaternion.x - 2 * quaternion.z*quaternion.z)).degrees
        var elevation = (90 - pitch)
        
        if abs(elevation) > 180{
            elevation = elevation % 180
        }
        
        return elevation * -1
    }
    
    
    enum HeadingMethod : Int{
        case None = 0
        case GLKit = 1
        case Quaternion = 2
        case WeirdHack = 3
        case Yaw = 4
        case Experiment = 5
    }
    
    var headingMethod : HeadingMethod = .None{
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    func headingCorrectedForTilt()->Double?{
        
        guard let motion = self.motionManager.deviceMotion else{
            return nil
        }
        
        guard let heading = self.heading else{
            return nil
        }
        
        let yawDegrees = Radians(motion.attitude.yaw).degrees;
        let rollDegrees = Radians(motion.attitude.roll).degrees;
        
        switch(self.headingMethod){
        case .None:
            return heading.magneticHeading
            
        case .GLKit:
            let aspect = fabsf(Float(self.bounds.width / self.bounds.height))
            let projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(45.0), aspect, 0.1, 100)
            
            
            let r = motion.attitude.rotationMatrix
            let camFromIMU = GLKMatrix4Make(Float(r.m11), Float(r.m12), Float(r.m13), 0,
                                            Float(r.m21), Float(r.m22), Float(r.m23), 0,
                                            Float(r.m31), Float(r.m32), Float(r.m33), 0,
                                            0,     0,     0,     1)
            
            let viewFromCam = GLKMatrix4Translate(GLKMatrix4Identity, 0, 0, 0);
            let imuFromModel = GLKMatrix4Identity
            let viewModel = GLKMatrix4Multiply(imuFromModel, GLKMatrix4Multiply(camFromIMU, viewFromCam))
            var isInvertible : Bool = false
            let modelView = GLKMatrix4Invert(viewModel, &isInvertible);
            var viewport = [Int32](count:4,repeatedValue: 0)
            
            viewport[0] = 0;
            viewport[1] = 0;
            viewport[2] = Int32(self.frame.size.width);
            viewport[3] = Int32(self.frame.size.height);
            
            var success: Bool = false
            let vector3 = GLKVector3Make(Float(self.frame.size.width)/2, Float(self.frame.size.height)/2, 1.0)
            let calculatedPoint = GLKMathUnproject(vector3, modelView, projectionMatrix, &viewport, &success)
            
            return success ? Double(GLKMathRadiansToDegrees(atan2f(-calculatedPoint.y, calculatedPoint.x))) : nil
            
        case .WeirdHack:
            
            var rotationDegrees = 0.0
            if(rollDegrees < 0 && yawDegrees < 0) // This is the condition where simply
                // summing yawDegrees with rollDegrees
                // wouldn't work.
                // Suppose yaw = -177 and pitch = -165.
                // rotationDegrees would then be -342,
                // making your rotation angle jump all
                // the way around the circle.
            {
                rotationDegrees = 360 - (-1 * (yawDegrees + rollDegrees));
            }
            else
            {
                rotationDegrees = yawDegrees + rollDegrees;
            }
            return rotationDegrees;
            
        case .Quaternion:
            
            let quaternion = motion.attitude.quaternion
            let tiltCompensation = Radians(asin(2*(quaternion.x*quaternion.z - quaternion.w*quaternion.y))).degrees;
            
            // 2.2 I transform magneticHeading with this tilt compensation
            return heading.magneticHeading + tiltCompensation
            
        case .Yaw:
            // Convert the radians yaw value to degrees then round up/down
            let yaw = roundf(Float(yawDegrees))
            
            // Convert the yaw value to a value in the range of 0 to 360
            var heading = yaw;
            if (heading < 0) {
                heading += 360;
            }
            
            return Double(heading)
            
        case .Experiment:
            guard let elevation = self.elevationDegrees() else{
                return nil
            }
            let angle = Radians(motion.attitude.pitch).degrees
            if elevation >= 45{
                return 180 + heading.magneticHeading
            }
            return heading.magneticHeading
            
        
        }
       
    }
}