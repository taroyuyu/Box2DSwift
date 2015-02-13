/**
Copyright (c) 2006-2014 Erin Catto http://www.box2d.org
Copyright (c) 2015 - Yohei Yoshihara

This software is provided 'as-is', without any express or implied
warranty.  In no event will the authors be held liable for any damages
arising from the use of this software.

Permission is granted to anyone to use this software for any purpose,
including commercial applications, and to alter it and redistribute it
freely, subject to the following restrictions:

1. The origin of this software must not be misrepresented; you must not
claim that you wrote the original software. If you use this software
in a product, an acknowledgment in the product documentation would be
appreciated but is not required.

2. Altered source versions must be plainly marked as such, and must not be
misrepresented as being the original software.

3. This notice may not be removed or altered from any source distribution.

This version of box2d was developed by Yohei Yoshihara. It is based upon
the original C++ code written by Erin Catto.
*/

import UIKit
import Box2D

class TheoJansenViewController: BaseViewController {
  var m_offset = b2Vec2()
  var m_chassis: b2Body!
  var m_wheel: b2Body!
  var m_motorJoint: b2RevoluteJoint!
  var m_motorOn = false
  var m_motorSpeed: b2Float = 0

  override func viewDidLoad() {
    super.viewDidLoad()
    
    let left = UIBarButtonItem(title: "Left", style: UIBarButtonItemStyle.Plain, target: self, action: "onLeft:")
    let brake = UIBarButtonItem(title: "Brake", style: UIBarButtonItemStyle.Plain, target: self, action: "onBrake:")
    let right = UIBarButtonItem(title: "Right", style: UIBarButtonItemStyle.Plain, target: self, action: "onRight:")
    let motor = UIBarButtonItem(title: "Motor", style: UIBarButtonItemStyle.Plain, target: self, action: "onMotor:")
    let flexible = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
    self.addToolbarItems([
      left, flexible,
      brake, flexible,
      right, flexible,
      motor, flexible,
      ])
  }
  
  func onLeft(sender: UIBarButtonItem) {
    m_motorJoint.setMotorSpeed(-m_motorSpeed)
  }

  func onBrake(sender: UIBarButtonItem) {
    m_motorJoint.setMotorSpeed(0.0)
  }

  func onRight(sender: UIBarButtonItem) {
    m_motorJoint.setMotorSpeed(m_motorSpeed)
  }

  func onMotor(sender: UIBarButtonItem) {
    m_motorJoint.enableMotor(!m_motorJoint.isMotorEnabled)
  }

  func createLeg(s: b2Float, wheelAnchor: b2Vec2) {
		let p1 = b2Vec2(5.4 * s, -6.1)
		let p2 = b2Vec2(7.2 * s, -1.2)
		let p3 = b2Vec2(4.3 * s, -1.9)
		let p4 = b2Vec2(3.1 * s, 0.8)
		let p5 = b2Vec2(6.0 * s, 1.5)
		let p6 = b2Vec2(2.5 * s, 3.7)
  
		let fd1 = b2FixtureDef(), fd2 = b2FixtureDef()
		fd1.filter.groupIndex = -1
		fd2.filter.groupIndex = -1
		fd1.density = 1.0
		fd2.density = 1.0
  
		let poly1 = b2PolygonShape(), poly2 = b2PolygonShape()
  
		if s > 0.0 {
      var vertices = [b2Vec2]()
      vertices.append(p1)
      vertices.append(p2)
      vertices.append(p3)
      poly1.set(vertices: vertices)
  
      vertices.removeAll()
      vertices.append(b2Vec2_zero)
      vertices.append(p5 - p4)
      vertices.append(p6 - p4)
      poly2.set(vertices: vertices)
		}
		else {
      var vertices = [b2Vec2]()
      vertices.append(p1)
      vertices.append(p3)
      vertices.append(p2)
      poly1.set(vertices: vertices)
  
      vertices.removeAll()
      vertices.append(b2Vec2_zero)
      vertices.append(p6 - p4)
      vertices.append(p5 - p4)
      poly2.set(vertices: vertices)
		}
  
		fd1.shape = poly1
		fd2.shape = poly2
  
		let bd1 = b2BodyDef(), bd2 = b2BodyDef()
		bd1.type = b2BodyType.dynamicBody
		bd2.type = b2BodyType.dynamicBody
		bd1.position = m_offset
		bd2.position = p4 + m_offset
  
		bd1.angularDamping = 10.0
		bd2.angularDamping = 10.0
  
		let body1 = world.createBody(bd1)
		let body2 = world.createBody(bd2)
  
		body1.createFixture(fd1)
		body2.createFixture(fd2)
  
		let djd = b2DistanceJointDef()
  
		// Using a soft distance constraint can reduce some jitter.
		// It also makes the structure seem a bit more fluid by
		// acting like a suspension system.
		djd.dampingRatio = 0.5
		djd.frequencyHz = 10.0
  
    djd.initialize(body1, bodyB: body2, anchorA: p2 + m_offset, anchorB: p5 + m_offset)
		world.createJoint(djd)
  
    djd.initialize(body1, bodyB: body2, anchorA: p3 + m_offset, anchorB: p4 + m_offset)
		world.createJoint(djd)
  
    djd.initialize(body1, bodyB: m_wheel, anchorA: p3 + m_offset, anchorB: wheelAnchor + m_offset)
		world.createJoint(djd)
  
    djd.initialize(body2, bodyB: m_wheel, anchorA: p6 + m_offset, anchorB: wheelAnchor + m_offset)
		world.createJoint(djd)
  
		let rjd = b2RevoluteJointDef()
    rjd.initialize(body2, bodyB: m_chassis, anchor: p4 + m_offset)
		world.createJoint(rjd)
  }

  override func prepare() {
    m_offset.set(0.0, 8.0)
    m_motorSpeed = 2.0
    m_motorOn = true
    let pivot = b2Vec2(0.0, 0.8)
    
    // Ground
    b2Locally {
      let bd = b2BodyDef()
      let ground = world.createBody(bd)
      
      let shape = b2EdgeShape()
      shape.set(vertex1: b2Vec2(-50.0, 0.0), vertex2: b2Vec2(50.0, 0.0))
      ground.createFixture(shape: shape, density: 0.0)
      
      shape.set(vertex1: b2Vec2(-50.0, 0.0), vertex2: b2Vec2(-50.0, 10.0))
      ground.createFixture(shape: shape, density: 0.0)
      
      shape.set(vertex1: b2Vec2(50.0, 0.0), vertex2: b2Vec2(50.0, 10.0))
      ground.createFixture(shape: shape, density: 0.0)
    }
    
    // Balls
    for i in 0 ..< 40 {
      let shape = b2CircleShape()
      shape.radius = 0.25
      
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position.set(-40.0 + 2.0 * b2Float(i), 0.5)
      
      let body = world.createBody(bd);
      body.createFixture(shape: shape, density: 1.0)
    }
    
    // Chassis
    b2Locally {
      let shape = b2PolygonShape()
      shape.setAsBox(halfWidth: 2.5, halfHeight: 1.0)
      
      let sd = b2FixtureDef()
      sd.density = 1.0
      sd.shape = shape
      sd.filter.groupIndex = -1
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position = pivot + self.m_offset
      self.m_chassis = self.world.createBody(bd)
      self.m_chassis.createFixture(sd)
    }
    
    b2Locally {
      let shape = b2CircleShape()
      shape.radius = 1.6
      
      let sd = b2FixtureDef()
      sd.density = 1.0
      sd.shape = shape
      sd.filter.groupIndex = -1
      let bd = b2BodyDef()
      bd.type = b2BodyType.dynamicBody
      bd.position = pivot + self.m_offset
      self.m_wheel = self.world.createBody(bd)
      self.m_wheel.createFixture(sd)
    }
    
    b2Locally {
      let jd = b2RevoluteJointDef()
      jd.initialize(self.m_wheel, bodyB: self.m_chassis, anchor: pivot + self.m_offset)
      jd.collideConnected = false
      jd.motorSpeed = self.m_motorSpeed
      jd.maxMotorTorque = 400.0
      jd.enableMotor = self.m_motorOn
      self.m_motorJoint = self.world.createJoint(jd) as! b2RevoluteJoint
    }
    
    var wheelAnchor = b2Vec2()
    
    wheelAnchor = pivot + b2Vec2(0.0, -0.8)
    
    createLeg(-1.0, wheelAnchor: wheelAnchor)
    createLeg(1.0, wheelAnchor: wheelAnchor)
    
    m_wheel.setTransform(position: self.m_wheel.position, angle: 120.0 * b2_pi / 180.0)
    createLeg(-1.0, wheelAnchor: wheelAnchor)
    createLeg(1.0, wheelAnchor: wheelAnchor)
    
    m_wheel.setTransform(position: self.m_wheel.position, angle: -120.0 * b2_pi / 180.0)
    createLeg(-1.0, wheelAnchor: wheelAnchor)
    createLeg(1.0, wheelAnchor: wheelAnchor)
  }
  
}