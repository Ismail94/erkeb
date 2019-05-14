//
//  UpdateService.swift
//  erkeb
//
//  Created by Ismail on 04/05/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import Foundation
import UIKit
import MapKit
import Firebase

class UpdateService {
    static var instance = UpdateService()
    //hier wordt de locatie van de passagier upgedated naar gelang zijn locatie doormiddel van de coordinaat
    func updateUserLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot] {
                for user in userSnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        DataService.instance.REF_USERS.child(user.key).updateChildValues(["coordinate" : [coordinate.latitude, coordinate.longitude]])
                    }
                }
            }
        })
    }
    //hier wordt de locatie van de passagier upgedated naar gelang zijn locatie doormiddel van de coordinaat
    func updateDriverLocation(withCoordinate coordinate: CLLocationCoordinate2D){
        DataService.instance.REF_DRIVERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot {
                    if driver.key == Auth.auth().currentUser?.uid{
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true {
                            DataService.instance.REF_DRIVERS.child(driver.key).updateChildValues(["coordinate" : [coordinate.latitude, coordinate.longitude]])
                        }
                    }
                }
            }
        })
    }
    
    func observeTrips(handler: @escaping(_ coordinateDict: Dictionary<String, AnyObject>?) -> Void){
        DataService.instance.REF_TRIPS.observe(.value, with:  { (snapshot) in
            if let tripSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for trip in tripSnapshot{
                    if trip.hasChild("passengerKey") && trip.hasChild("tripIsAccepted"){
                        if let tripDict = trip.value as? Dictionary<String, AnyObject>{
                            handler(tripDict)
                        }
                    }
                }
            }
        })
    }
    
    //via dit functie gaat de passagier een rit kunnen annvragen en doorsturen naar de bestuurder
    func updateTripsWithCoordinatesUponRequest(){
        DataService.instance.REF_USERS.observeSingleEvent(of: .value, with: { (snapshot) in
            if let userSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for user in userSnapshot{
                    if user.key == Auth.auth().currentUser?.uid{
                        if !user.hasChild("userIsDriver"){
                            if let userDict = user.value as? Dictionary<String, AnyObject>{
                                let pickupArray = userDict["coordinate"] as! NSArray
                                let destinationArray = userDict["tripCoordinate"] as! NSArray
                                
                                DataService.instance.REF_TRIPS.child(user.key).updateChildValues(["pickupCoordinate": [pickupArray[0], pickupArray[1]], "destinationCoordinate": [destinationArray[0], destinationArray[1]], "passengerKey": user.key, "tripIsAccepted": false ])
                            }
                        }
                    }
                }
            }
        })
    }

    //hier aanvaard de bestuurder de rit aan van de passagier
    func driverAcceptTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String){
        DataService.instance.REF_TRIPS.child(passengerKey).updateChildValues(["driverKey": driverKey, "tripIsAccepted": true])
        DataService.instance.REF_DRIVERS.child(driverKey).updateChildValues(["driverIsOnTrip": true])
    }
    
    func cancelTrip(withPassengerKey passengerKey: String, forDriverKey driverKey: String?){
        DataService.instance.REF_TRIPS.child(passengerKey).removeValue()
        DataService.instance.REF_USERS.child(passengerKey).child("tripCoordinate").removeValue()
        if driverKey != nil {
            DataService.instance.REF_DRIVERS.child(driverKey!).updateChildValues(["driverIsOnTrip": false])
        }
    }
}
