//
//  HomeVC.swift
//  erkeb
//
//  Created by Ismail on 25/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import MapKit
import RevealingSplashView

class HomeVC: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var boekEenRitBtn: RoundedBoekEenRitButton!
    
    var delegate: CenterVCDelegate?
    
    //Load image for launchscreen
    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "LaunchScreenIcon")!, iconInitialSize: CGSize(width: 212, height: 254), backgroundImage: UIImage(named: "LaunchScreenBG")!)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        
        //Set the launchscreen animation
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.squeezeAndZoomOut
        revealingSplashView.startAnimation()
        
        //Call to stop the animation
        revealingSplashView.heartAttack = true
       
    }
    
    
    @IBAction func boekEenRitBtnWasPressed(_ sender: Any) {
        boekEenRitBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleMenuLeftPanel()
    }
    
}

