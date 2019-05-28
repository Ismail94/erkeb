//
//  PickupVCViewController.swift
//  erkeb
//
//  Created by Ismail on 11/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import UIKit
import MapKit
import Firebase

class PickupVC: UIViewController {

    @IBOutlet weak var pickupMapView: RoundedMapView!
    
    var pickupCoordinate: CLLocationCoordinate2D!
    var passengerKey: String!
    
    var regionRadius: CLLocationDistance = 500
    var pin: MKPlacemark? = nil
    
    var locationPlacemark : MKPlacemark!
    
    var currentUserId = Auth.auth().currentUser?.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        pickupMapView.delegate = self

        locationPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        
        dropPinFor(placemark: locationPlacemark)
        centerMapOnLocation(location: locationPlacemark.location!)
        
        //Als een bestuurder een rit aanvaard dan wordt deze bij de andere bestuurders niet meer zichtbaar
        DataService.instance.REF_TRIPS.child(passengerKey).observe(.value, with: { (tripSnapshot) in
            if tripSnapshot.exists(){
                if tripSnapshot.childSnapshot(forPath: RIT_IS_AANVAARD).value as? Bool == true{
                    self.dismiss(animated: true, completion: nil)
                }
            } else {
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    func initData(coordinate: CLLocationCoordinate2D, passengerKey: String){
        self.pickupCoordinate = coordinate
        self.passengerKey = passengerKey
    }
    
    @IBAction func AcceptRitBtnWasPressed(_ sender: Any) {
        UpdateService.instance.driverAcceptTrip(withPassengerKey: passengerKey, forDriverKey: currentUserId!)
        presentingViewController?.shouldShowLoadingView(true)
    }
    
    @IBAction func cancelBtnWasPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension PickupVC: MKMapViewDelegate{
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "pickupPunt"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        } else {
            annotationView?.annotation = annotation
        }
        annotationView?.image = UIImage(named: "PassengerAnnotation")
        
        return annotationView
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegion.init(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
        pickupMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func dropPinFor(placemark: MKPlacemark) {
        pin = placemark
        
        for annotation in pickupMapView.annotations {
            pickupMapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        
        pickupMapView.addAnnotation(annotation)
    }
}
