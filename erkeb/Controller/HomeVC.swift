//
//  HomeVC.swift
//  erkeb
//
//  Created by Ismail on 25/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import MapKit

class HomeVC: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var boekEenRitBtn: RoundedBoekEenRitButton!
    
    var delegate: CenterVCDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
       
    }
    
    
    @IBAction func boekEenRitBtnWasPressed(_ sender: Any) {
        boekEenRitBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleMenuLeftPanel()
    }
    
}

