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
import Firebase
import RevealingSplashView

class HomeVC: UIViewController{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var boekEenRitBtn: RoundedBoekEenRitButton!
    @IBOutlet weak var centerMapBtn: CenterMapButton!
    @IBOutlet weak var bestemmingTextField: UITextField!
    
    var delegate: CenterVCDelegate?
    
    var manager : CLLocationManager?
    
    var regionRadius: CLLocationDistance = 1000
    
    //Load image for launchscreen
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "LaunchScreenIcon")!, iconInitialSize: CGSize(width: 212, height: 254), backgroundImage: UIImage(named: "LaunchScreenBG")!)

    var tableView = UITableView()
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        manager = CLLocationManager()
        manager?.delegate = self
        manager?.desiredAccuracy = kCLLocationAccuracyBest
        
        checkLocationAuthStatus()
        
        mapView.delegate = self
        bestemmingTextField.delegate = self
        
        centerMapOnUserLocation()
        
        DataService.instance.REF_DRIVERS.observe(.value, with:  { (snapshot) in
            self.loadDriverAnnotationFromFB()
        })
        
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
    
    func loadDriverAnnotationFromFB(){
        //coordinaten uploaden van de huidige driver positie
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot{
                    if driver.hasChild("userIsDriver"){
                        if driver.hasChild("coordinate"){
                            if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true{
                                if let driverDict = driver.value as? Dictionary <String, AnyObject>{
                                    let coordinateArray = driverDict["coordinate"] as! NSArray
                                    let driverCoordinate = CLLocationCoordinate2D(latitude: coordinateArray[0] as! CLLocationDegrees, longitude: coordinateArray[1] as! CLLocationDegrees)
                                    
                                    //annotation aanmaken op kaart
                                    let annotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driver.key)
                                    
                                    //hier check ik als er een bestuurder op de kaart en de locaties update
                                    var driverIsVisible: Bool{
                                        return self.mapView.annotations.contains(where: { (annotation) -> Bool in
                                            if let driverAnnotation = annotation as? DriverAnnotation{
                                                if driverAnnotation.key == driver.key{
                                                    driverAnnotation.update(annotationPostition: driverAnnotation, withCoordinate: driverCoordinate)
                                                    return true
                                                }
                                            }
                                            return false
                                        })
                                    }
                                    if !driverIsVisible{
                                        self.mapView.addAnnotation(annotation)
                                    }
                                }
                            } else {
                                for annotation in self.mapView.annotations{
                                    if annotation.isKind(of: DriverAnnotation.self){
                                        if let annotation = annotation as? DriverAnnotation{
                                            if annotation.key == driver.key{
                                                self.mapView.removeAnnotation(annotation)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
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
        centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
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
    
    //waneer ik door de kaart swipe blijft te knop zichtbaar en als ik erop klik en de locatie centreer dan verdwijnt de knop
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    //zoek functie voor locaties
    func performSearch(){
        matchingItems.removeAll()
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = bestemmingTextField.text
        request.region = mapView.region
        
        let search = MKLocalSearch(request: request)
        
        search.start { (response, error) in
            if error != nil {
                print(error.debugDescription)
            }else if response!.mapItems.count == 0 {
                print("Geen resultaten")
            } else {
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                }
            }
        }
    }
}

extension HomeVC: UITextFieldDelegate{
    //hier onder wordt de coden gebruikt wanneer je de textfield selecteer
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        if textField == bestemmingTextField{
            tableView.frame = CGRect(x: 20, y: view.frame.height, width: view.frame.width - 40, height: view.frame.height - 210)
            tableView.layer.cornerRadius = 5.0
            tableView.layer.shadowOpacity = 0.1
            tableView.layer.shadowColor = UIColor.black.cgColor
            tableView.layer.shadowRadius = 5.0
            tableView.layer.shadowOffset = CGSize(width: 0, height: 3)
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "locationCell")
            
            tableView.delegate = self
            tableView.dataSource = self
            
            tableView.tag = 94
            tableView.rowHeight = 60
            
            view.addSubview(tableView)
            animateTableView(shouldShow: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == bestemmingTextField{
            performSearch()
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        matchingItems = []
        tableView.reloadData()
        //animateTableView(shouldShow: false)
        centerMapOnUserLocation()
        return true
    }
    
    func animateTableView(shouldShow: Bool){
        if shouldShow{
            UIView.animate(withDuration: 0.2, animations: {
                self.tableView.frame = CGRect(x: 20, y: 210, width: self.view.frame.width - 40, height: self.view.frame.height - 210)
            })
        } else {
            UIView.animate(withDuration: 0.2, animations: {
               self.tableView.frame = CGRect(x: 20, y: self.view.frame.height, width: self.view.frame.width - 40, height: self.view.frame.height - 210)
            }, completion:  { (finished) in
                for subview in self.view.subviews {
                    if subview.tag == 94 {
                        subview.removeFromSuperview()
                    }
                }
            })
        }
    }
}

extension HomeVC: UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "locationCell")
        let mapItem = matchingItems[indexPath.row]
        cell.textLabel?.text = mapItem.name
        cell.detailTextLabel?.text = mapItem.placemark.title
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        animateTableView(shouldShow: false)
        print("Geselecteerd!")
    }
    
    //Voor een betere ervaring als ik scroll in de lijst dan verdwijnt de keyboard
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        view.endEditing(true)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if bestemmingTextField.text == ""{
            animateTableView(shouldShow: false)
        }
    }
}
