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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
    }
    
    @IBAction func boekEenRitBtnWasPressed(_ sender: Any) {
        boekEenRitBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
    
}

