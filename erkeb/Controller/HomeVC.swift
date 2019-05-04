//
//  HomeVC.swift
//  erkeb
//
//  Created by Ismail on 25/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import RevealingSplashView

class HomeVC: UIViewController{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var boekEenRitBtn: RoundedBoekEenRitButton!
    
    var delegate: CenterVCDelegate?
    
    var manager : CLLocationManager?
    
    var regionRadius: CLLocationDistance = 1000
    
    //Load image for launchscreen
    
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "LaunchScreenIcon")!, iconInitialSize: CGSize(width: 212, height: 254), backgroundImage: UIImage(named: "LaunchScreenBG")!)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocationAuthStatus()
        
        mapView.delegate = self
        
        centerMapOnUserLocation()
        
        //Set the launchscreen animation
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.squeezeAndZoomOut
        revealingSplashView.startAnimation()
        
        //Call to stop the animation
        revealingSplashView.heartAttack = true
    }
    
    //hier kijk ik als er al authorisatie zo niet dan vraag ik het terug
    func checkLocationAuthStatus(){
        if CLLocationManager.authorizationStatus() == .authorizedAlways{
            manager?.startUpdatingLocation()
        } else{
            manager?.requestAlwaysAuthorization()
        }
    }
    
    //Kaart centereren op de location van de gebruiker
    func centerMapOnUserLocation(){
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    
    @IBAction func boekEenRitBtnWasPressed(_ sender: Any) {
        boekEenRitBtn.animateButton(shouldLoad: true, withMessage: nil)
    }
   
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
        centerMapOnUserLocation()
    }
    
    @IBAction func menuBtnWasPressed(_ sender: Any) {
        delegate?.toggleMenuLeftPanel()
    }
}

extension HomeVC: CLLocationManagerDelegate{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthStatus()
        if status == .authorizedAlways {
            mapView.showsUserLocation = true
            // als de gerbuiker beweegt dan gaat de pin in het midden van de scherm blijven en kaart zal dan volgen
            mapView.userTrackingMode =  .follow
        }
    }
}

extension HomeVC: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage.init(named: "DriverAnnotation")
            return view
        }
        return nil
    }
}


