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

enum AnnotationType {
    case pickup
    case destination
    case driver
}

class HomeVC: UIViewController, Alertable{

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var boekEenRitBtn: RoundedBoekEenRitButton!
    @IBOutlet weak var centerMapBtn: CenterMapButton!
    @IBOutlet weak var cancelBtn: UIButton!
    @IBOutlet weak var bestemmingTextField: UITextField!
    
    
    var delegate: CenterVCDelegate?
    
    var manager : CLLocationManager?
    
    var regionRadius: CLLocationDistance = 1000
    
    //Load image for launchscreen
    let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "LaunchScreenIcon")!, iconInitialSize: CGSize(width: 212, height: 254), backgroundImage: UIImage(named: "LaunchScreenBG")!)
    
    var tableView = UITableView()
    
    var matchingItems: [MKMapItem] = [MKMapItem]()
    
    var route: MKRoute!
    
    var selectedItemPlaceMark: MKPlacemark? = nil
    
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
            
        let currentUserId = Auth.auth().currentUser?.uid

            DataService.instance.passengerIsOnTrip(passengerKey: currentUserId! , handler: { (isOnTrip, driverKey, tripKey) in
                if isOnTrip == true {
                    self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                }
            })
        })
        
        //Set the launchscreen animation
        self.view.addSubview(revealingSplashView)
        revealingSplashView.animationType = SplashAnimationType.squeezeAndZoomOut
        revealingSplashView.startAnimation()
        
        //Call to stop the animation
        revealingSplashView.heartAttack = true
        
        //hier wordt de oppak plaats van de passagier doorgegeven naar de bestuurder zodat hij die kan oppaken (scherm PickupVC)
        UpdateService.instance.observeTrips { (tripDict) in
            if let tripDict = tripDict {
                let currentUserId = Auth.auth().currentUser?.uid
                let pickupCoordinateArray = tripDict["pickupCoordinate"] as! NSArray
                let tripKey = tripDict["passengerKey"] as! String
                let acceptanceStatus = tripDict["tripIsAccepted"] as! Bool
                
                if acceptanceStatus == false {
                    DataService.instance.driverIsAvailable(key: currentUserId!, handler: { (available) in
                        if let available = available {
                            if available == true {
                                let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
                                let pickupVC = storyboard.instantiateViewController(withIdentifier: "PickupVC") as? PickupVC
                                pickupVC?.initData(coordinate: CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees), passengerKey: tripKey)
                                
                                self.present(pickupVC!, animated: true, completion: nil)
                            }
                        }
                    })
                }
            }
        }
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let currentUserId = Auth.auth().currentUser?.uid

        if currentUserId != nil {
            print("Contains a value")
        } else {
            print("Doesn’t contain a value.")
        }
        
        DataService.instance.REF_TRIPS.observe(.childRemoved, with: { (removedTripSnapshot) in
            let removedTripDict = removedTripSnapshot.value as? [String: AnyObject]
            if removedTripDict?["driverKey"] != nil {
                DataService.instance.REF_DRIVERS.child(removedTripDict?["driverKey"] as! String).updateChildValues(["driverIsOnTrip": false])
            }
            
            DataService.instance.userIsDriver(userKey: currentUserId!, handler: { (isDriver) in
                if isDriver == true {
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                } else {
                    self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.boekEenRitBtn.animateButton(shouldLoad: false, withMessage: "Boek een rit")
                    
                    self.bestemmingTextField.isUserInteractionEnabled = true
                    self.bestemmingTextField.text = ""
                    
                    self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)
                    self.centerMapOnUserLocation()
                }
            })
        })

        DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler:  { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                    if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                        for trip in tripSnapshot {
                            if trip.childSnapshot(forPath: "driverKey").value as? String == currentUserId! {
                                let pickupCoordinateArray = trip.childSnapshot(forPath: "pickupCoordinate").value as! NSArray
                                let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                                let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                                
                                self.dropPinFor(placemark: pickupPlacemark)
                                self.searchResultsWithPolyline(forOriginMapItem: nil, withDestinationMapItem: MKMapItem(placemark: pickupPlacemark))
                                self.setCustomRegion(forAnnotationType: .pickup, withCoordinate: pickupCoordinate)
                            }
                        }
                    }
                })
            }
        })
            connectUserAndDriverForTrip()
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
    
    func connectUserAndDriverForTrip() {
        let currentUserId = Auth.auth().currentUser?.uid

        DataService.instance.userIsDriver(userKey: currentUserId!) { (status) in
            if status == false {
                DataService.instance.REF_TRIPS.child(currentUserId!).observe(.value, with: { (tripSnapshot) in
                    let tripDict = tripSnapshot.value as? Dictionary<String, AnyObject>

                    if tripDict?["tripIsAccepted"] as? Bool == true {
                        self.removeOverlaysAndAnnotations(forDrivers: false, forPassengers: true)

                        let driverId = tripDict?["driverKey"] as! String

                        let pickupCoordinateArray = tripDict?["pickupCoordinate"] as! NSArray
                        let pickupCoordinate = CLLocationCoordinate2D(latitude: pickupCoordinateArray[0] as! CLLocationDegrees, longitude: pickupCoordinateArray[1] as! CLLocationDegrees)
                        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
                        let pickupMapItem = MKMapItem(placemark: pickupPlacemark)

                        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (driverSnapshot) in
                            if let driverSnapshot = driverSnapshot.children.allObjects as? [DataSnapshot] {
                                for driver in driverSnapshot {
                                    if driver.key == driverId {
                                        let driverCoordinateArray = driver.childSnapshot(forPath: "coordinate").value as! NSArray
                                        let driverCoordinate = CLLocationCoordinate2D(latitude: driverCoordinateArray[0] as! CLLocationDegrees, longitude: driverCoordinateArray[1] as! CLLocationDegrees)
                                        let driverPlacemark = MKPlacemark(coordinate: driverCoordinate)
                                        let driverMapItem = MKMapItem(placemark: driverPlacemark)

                                        let passengerAnnotation = PassengerAnnotation(coordinate: pickupCoordinate, key: currentUserId!)
//                                        let driverAnnotation = DriverAnnotation(coordinate: driverCoordinate, withKey: driverId)

                                        self.mapView.addAnnotation(passengerAnnotation)
                                        self.searchResultsWithPolyline(forOriginMapItem: driverMapItem, withDestinationMapItem: pickupMapItem)
                                        self.boekEenRitBtn.animateButton(shouldLoad: false, withMessage: "Bestuurder is onderweg")
                                        self.boekEenRitBtn.isUserInteractionEnabled = false
                                    }
                                }
                            }
                        })
                    }
                })
            }
        }
    }
    
    //Kaart centereren op de location van de gebruiker
    func centerMapOnUserLocation(){
        let coordinateRegion = MKCoordinateRegion(center: mapView.userLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    //Uitzoomen op de verbinding tussen de passagier en bestemming
    func centerZoomOnLinkPassengerDestination(){
        let currentUserId = Auth.auth().currentUser?.uid
        //verbinding weergeven en het centereren
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in userSnapshot{
                    if user.key == currentUserId! {
                        if user.hasChild("tripCoordinate"){
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        } else {
                            self.centerMapOnUserLocation()
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })
    }
    
    ////--------BUTTONS-----------------------------------------------
    @IBAction func cancelBtnWasPressed(_ sender: Any) {
        let currentUserId = Auth.auth().currentUser?.uid
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: tripKey!, forDriverKey: driverKey!)
            }
        }
        
        DataService.instance.passengerIsOnTrip(passengerKey: currentUserId!) { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                UpdateService.instance.cancelTrip(withPassengerKey: currentUserId!, forDriverKey: driverKey!)
            } else {
                UpdateService.instance.cancelTrip(withPassengerKey: currentUserId!, forDriverKey: nil)
            }
        }
        //boek een rit terug activeren
        self.boekEenRitBtn.isUserInteractionEnabled = true
    }
    
    
    @IBAction func boekEenRitBtnWasPressed(_ sender: Any) {
        UpdateService.instance.updateTripsWithCoordinatesUponRequest()
        boekEenRitBtn.animateButton(shouldLoad: true, withMessage: nil)
        
        self.view.endEditing(true)
        bestemmingTextField.isUserInteractionEnabled = false
    }
    
    @IBAction func centerMapBtnWasPressed(_ sender: Any) {
//        centerZoomOnLinkPassengerDestination()
        let currentUserId = Auth.auth().currentUser?.uid
        
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot {
                    if user.key == currentUserId! {
                        if user.hasChild("tripCoordinate") {
                            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        } else {
                            self.centerMapOnUserLocation()
                            self.centerMapBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                        }
                    }
                }
            }
        })
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
    
    //Als we in de pickup zone terecht komen dan krijgt de bestuurder te zien op de knop Begin rit
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        let currentUserId = Auth.auth().currentUser?.uid
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, passengerKey) in
            if isOnTrip == true {
                if region.identifier == "pickup" {
                    self.boekEenRitBtn.setTitle("Begin rit", for: .normal)
                    print("De bestuurder stapt in de pikcup zone")
                } else if region.identifier == "destination" {
                    self.cancelBtn.fadeTo(alphaValue: 0.0, withDuration: 0.2)
                    self.cancelBtn.isHidden = true
                    self.boekEenRitBtn.setTitle("Eind rit", for: .normal)
                }
            }
        })
    }
    
    //De boek een rit knop zal je de routebeschrijving naar de passagier en de bestemming van de passagier geven via de ingebouwde apple gps app
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        let currentUserId = Auth.auth().currentUser?.uid
        DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
            if isOnTrip == true {
                if region.identifier == "pickup" {
                    print("De bestuurder verlaat de pickup zone")
                    self.boekEenRitBtn.setTitle("Routebeschrijving", for: .normal)
                } else if region.identifier == "destination" {
                    self.boekEenRitBtn.setTitle("Routebeschrijving", for: .normal)
                }
            }
        })
    }
}

extension HomeVC: MKMapViewDelegate{
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let currentUserId = Auth.auth().currentUser?.uid
        UpdateService.instance.updateUserLocation(withCoordinate: userLocation.coordinate)
        UpdateService.instance.updateDriverLocation(withCoordinate: userLocation.coordinate)
        
        DataService.instance.userIsDriver(userKey: currentUserId!) { (isDriver) in
            if isDriver == true {
                DataService.instance.driverIsOnTrip(driverKey: currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                })
            } else {
                DataService.instance.passengerIsOnTrip(passengerKey: currentUserId!, handler: { (isOnTrip, driverKey, tripKey) in
                    if isOnTrip == true {
                        self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: true, withKey: driverKey)
                    } else {
                        self.centerMapOnUserLocation()
                    }
                })
            }
        }
    }
    
    //hier worden de annotation afbeeldingen gezet als MKAnnotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let identifier = "driver"
            var view: MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage.init(named: "DriverAnnotation")
            return view
        } else if let annotation = annotation as? PassengerAnnotation{
            let identifier = "passenger"
            var view : MKAnnotationView
            view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.image = UIImage.init(named: "PassengerAnnotation")
            return view
        } else if let annotation = annotation as? MKPointAnnotation{
            let identifier = "destination"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            } else {
                annotationView?.annotation = annotation
            }
            annotationView?.image = UIImage(named: "DestinationAnnotation")
            return annotationView
        }
        return nil
    }
    
    //waneer ik door de kaart swipe blijft te knop zichtbaar en als ik erop klik en de locatie centreer dan verdwijnt de knop
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        centerMapBtn.fadeTo(alphaValue: 1.0, withDuration: 0.2)
    }
    
    //Polyline op het kaart weergeven door gebruik te maken van de render functie
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let lineRenderer = MKPolylineRenderer(overlay: self.route.polyline)
        lineRenderer.strokeColor = UIColor(red: 0.47, green: 0.40, blue: 1.0, alpha: 1.0)
        lineRenderer.lineWidth = 3.0
        lineRenderer.lineJoin = .round
        lineRenderer.lineCap = .butt
        
        //loading view niet meer zichtbaar maken
        shouldShowLoadingView(false)
        
        return lineRenderer
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
                self.showAlert("Er is een onverwachte fout opgetreden, probeer opnieuw.")
            }else if response!.mapItems.count == 0 {
                self.showAlert("Geen resultaten gevonden! 🙆‍♂️ Probeer opnieuw met een andere locatie")
            } else {
                for mapItem in response!.mapItems {
                    self.matchingItems.append(mapItem as MKMapItem)
                    self.tableView.reloadData()
                    //loading view wordt hier niet weergeven
                    self.shouldShowLoadingView(false)
                }
            }
        }
    }
    
    //hier ga ik een pin plaatsen bij de bestemming adres of punt
    func dropPinFor(placemark: MKPlacemark){
        selectedItemPlaceMark = placemark
        
        //Oude bestemming pin verwijderen als ik een nieuwe bestemming kies
        for annotation in mapView.annotations {
            if annotation.isKind(of: MKPointAnnotation.self){
                mapView.removeAnnotation(annotation)
            }
    }
        //Pin plaatsen bij gevraagde bestemming
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        mapView.addAnnotation(annotation)
    }
    
    //hier wordt de polyline gelinkt met het gevraagde bestemming
    func searchResultsWithPolyline(forOriginMapItem originMapItem: MKMapItem?, withDestinationMapItem destinationMapItem: MKMapItem){
        let request = MKDirections.Request()
        
        if originMapItem == nil {
            request.source = MKMapItem.forCurrentLocation()
        } else {
            request.source = originMapItem
        }
        request.destination = destinationMapItem
        request.transportType = MKDirectionsTransportType.automobile
        request.requestsAlternateRoutes = true
        
        let directions = MKDirections(request: request)
        
        directions.calculate { (response, error) in
            guard let response = response else{
                self.showAlert(error.debugDescription)
                return
            }
            self.route = response.routes[0]
            
            if self.mapView.overlays.count == 0 {
                //Lijn op de kaart toevoegen (via route. kan je de afstand en tijd hebben en printen
                self.mapView.addOverlay(self.route!.polyline)
            }
            
            self.zoom(toFitAnnotationsFromMapView: self.mapView, forActiveTripWithDriver: false, withKey: nil)
            
            //Nadat de ployline wordt gemaakt verdwijnt de loading view
            let delegate = AppDelegate.getAppDelegate()
             delegate.window?.rootViewController?.shouldShowLoadingView(false)
        }
    }
    
    //hier zullen de annotations die gelinkt zijn op een beeld te zien zijn doormiddel van het uitzoomen
    func zoom(toFitAnnotationsFromMapView mapView: MKMapView, forActiveTripWithDriver: Bool, withKey key: String?) {
        
        //eerst checken als er annotations zijn
        if mapView.annotations.count == 0 {
            return
        }
        
        //Voor de annotations te kunnen fitten in het scherm moet ik de coordinaten van de scherm declareren
        var topLeftCoordinate = CLLocationCoordinate2D(latitude: -90, longitude: 180)
        var bottomRightCoordinate = CLLocationCoordinate2D(latitude: 90, longitude: -180)
        
        if forActiveTripWithDriver{
            for annotation in mapView.annotations {
                if let annotation = annotation as? DriverAnnotation {
                    if annotation.key == key {
                        topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                        topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                        bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                        bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                    }
                } else {
                    topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
                    topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
                    bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
                    bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
                }
            }
        }
        
        for annotation in mapView.annotations where !annotation.isKind(of: DriverAnnotation.self){
            //hier stel ik de minimum waarde tussen de topleftcoordinate en annotation en die zal gereturnd worden
            topLeftCoordinate.longitude = fmin(topLeftCoordinate.longitude, annotation.coordinate.longitude)
            //hier stel ik de maximum waarde tussen de topleftcoordinate en annotation en die zal gereturnd worden
            topLeftCoordinate.latitude = fmax(topLeftCoordinate.latitude, annotation.coordinate.latitude)
            bottomRightCoordinate.longitude = fmax(bottomRightCoordinate.longitude, annotation.coordinate.longitude)
            bottomRightCoordinate.latitude = fmin(bottomRightCoordinate.latitude, annotation.coordinate.latitude)
        }
        
        //nadat ik de coordinaten heb stel ik nu de region in
        var region = MKCoordinateRegion(center: CLLocationCoordinate2DMake(topLeftCoordinate.latitude - (topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 0.4, topLeftCoordinate.longitude + (bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 0.4), span: MKCoordinateSpan(latitudeDelta: fabs(topLeftCoordinate.latitude - bottomRightCoordinate.latitude) * 3.0, longitudeDelta: fabs(bottomRightCoordinate.longitude - topLeftCoordinate.longitude) * 3.0))
        
        region = mapView.regionThatFits(region)
        mapView.setRegion(region, animated: true)
    }
    
    //hier verwijder ik de annotatations zowel voor een bestuurder als voor een passagier als er een rit geannuleerd wordt
    func removeOverlaysAndAnnotations(forDrivers: Bool?, forPassengers: Bool?){
        for annotation in mapView.annotations{
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            }
            
            if forPassengers! {
                if let annotation = annotation as? PassengerAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
            
            if forDrivers! {
                if let annotation = annotation as? DriverAnnotation {
                    mapView.removeAnnotation(annotation)
                }
            }
        }
        
        for overlay in mapView.overlays {
            if overlay is MKPolyline {
                mapView.removeOverlay(overlay)
            }
        }
    }
    
    //zone dat aangeeft dat de bestuurder en passagier 100m van elkaar zijn
    func setCustomRegion(forAnnotationType type: AnnotationType, withCoordinate coordinate: CLLocationCoordinate2D){
        if type == .pickup {
            let pikcupRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "pickup")
            manager?.startMonitoring(for: pikcupRegion)
        } else if type == .destination{
            let destinationRegion = CLCircularRegion(center: coordinate, radius: 100, identifier: "destination")
            manager?.startMonitoring(for: destinationRegion)
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
            shouldShowLoadingView(true)
            view.endEditing(true)
        }
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        
        let currentUserId = Auth.auth().currentUser?.uid
        //verwijder de matchingitems (resultaten) van de bestemming lijst
        matchingItems = []
        tableView.reloadData()
        
        //verwijder bestemming coordinaat van de database
        DataService.instance.REF_USERS.child(currentUserId!).child("tripCoordinate").removeValue()
        
        //verwijder de ploylines, passagier annotations en bestemming annotations
        mapView.removeOverlays(mapView.overlays)
        for annotation in mapView.annotations{
            if let annotation = annotation as? MKPointAnnotation{
                mapView.removeAnnotation(annotation)
            } else if annotation.isKind(of: PassengerAnnotation.self){
                mapView.removeAnnotation(annotation)
            }
        }
        
        //kaart centreren op de locatie van de gebruiker
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
        cell.textLabel?.font = UIFont(name: "Avenir Next", size: 18)
        cell.textLabel?.textColor = UIColor(red: 0.66, green: 0.66, blue: 1.0, alpha: 1.0)
        
        cell.detailTextLabel?.text = mapItem.placemark.title
        cell.detailTextLabel?.font = UIFont(name: "Avenir Next", size: 12)
        cell.detailTextLabel?.textColor = UIColor(red: 0.66, green: 0.66, blue: 1.0, alpha: 1.0)
    
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchingItems.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //wanneer je op een item klikt van lijst gebeurt er dit allemaal
        shouldShowLoadingView(true)
        
        let currentUserId = Auth.auth().currentUser?.uid
        let passengerCoordinate = manager?.location?.coordinate
        let passengerAnnotation = PassengerAnnotation(coordinate: passengerCoordinate!, key: currentUserId!)
        mapView.addAnnotation(passengerAnnotation)
        
        //Adres van bestemming in lijst wordt netjes overgenomen in textfield na selectie
        bestemmingTextField.text = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        //Na het selecteren van de bestemming worden de coordinaten hier opgeslagen
        let selectedMapItem = matchingItems[indexPath.row]
        DataService.instance.REF_USERS.child(currentUserId!).updateChildValues(["tripCoordinate": [selectedMapItem.placemark.coordinate.latitude,selectedMapItem.placemark.coordinate.longitude]])
        
        //Pin verwijderen na het ingeven van een nieuwe bestemming
        dropPinFor(placemark: selectedMapItem.placemark)
        
        searchResultsWithPolyline(forOriginMapItem: nil , withDestinationMapItem: selectedMapItem)
        
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
