//
//  DataService.swift
//  erkeb
//
//  Created by Ismail on 29/04/2019.
//  Copyright © 2019 Ismail Abes. All rights reserved.
//

import Foundation
import Firebase

//Refernce of the default database url
let DB_BASE = Database.database().reference()

class DataService {
    static let instance = DataService()
    
    //Verschillende childs aanmaken voor elke URL
    private var _REF_BASE = DB_BASE
    private var _REF_USERS = DB_BASE.child("users")
    private var _REF_DRIVERS = DB_BASE.child("drivers")
    private var _REF_TRIPS = DB_BASE.child("trips")
    
    //hiermee ga ik de childs kunnen aanspreken en gebruiken
    var REF_BASE: DatabaseReference{
        return _REF_BASE
    }
    
    var REF_USERS: DatabaseReference{
        return _REF_USERS
    }
    
    var REF_DRIVERS: DatabaseReference{
        return _REF_DRIVERS
    }
    
    var REF_TRIPS: DatabaseReference{
        return _REF_TRIPS
    }
    
    //functie waarmee ik een nieuwe user kan aanmaken
    func createFirebaseDBUser(uid: String, userData: Dictionary<String, Any>, isDriver: Bool){
        if isDriver{
            REF_DRIVERS.child(uid).updateChildValues(userData)
        } else {
            REF_USERS.child(uid).updateChildValues(userData)
        }
    }
    
    //check als de pickup-modus aan of uit is zodat er een rit kan dooregestuurd worden naar bestuurder
    func driverIsAvailable(key: String, handler: @escaping(_ status: Bool?) -> Void){
        DataService.instance._REF_DRIVERS.observeSingleEvent(of: .value, with:  { (snapshot) in
            if let driverSnapshot = snapshot.children.allObjects as? [DataSnapshot]{
                for driver in driverSnapshot{
                    if driver.key == key{
                        if driver.childSnapshot(forPath: "isPickupModeEnabled").value as? Bool == true{
                            if driver.childSnapshot(forPath: "driverIsOnTrip").value as? Bool == true{
                                handler(false)
                            } else {
                                handler(true)
                            }
                        }
                    }
                }
            }
        })
    }
    
    //hiermee kan ik zien als een bestuurder op rit is
    func driverIsOnTrip(driverKey: String, handler: @escaping(_ status: Bool?, _ driverKey: String?, _ tripKey: String?) -> Void){
        DataService.instance.REF_DRIVERS.child(driverKey).child("driverIsOnTrip").observe(.value, with:  { (driverTripStatusSnapshot) in
            if let driverTripStatusSnapshot = driverTripStatusSnapshot.value as? Bool {
                if driverTripStatusSnapshot == true {
                    DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with: { (tripSnapshot) in
                        if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot]{
                            for trip in tripSnapshot {
                                if trip.childSnapshot(forPath: "driverKey").value as? String == driverKey {
                                    handler(true, driverKey, trip.key)
                                } else {
                                    return
                                }
                            }
                        }
                    })
                } else {
                    handler(false, nil, nil)
                }
            }
        })
    }
    
    //hiermee kan ik zien als een passagier op een rit is
    func passengerIsOnTrip(passengerKey: String, handler: @escaping(_ status: Bool?, _ driverKey: String?, _ tripKey: String?) -> Void){
        DataService.instance.REF_TRIPS.observeSingleEvent(of: .value, with:  { (tripSnapshot) in
            if let tripSnapshot = tripSnapshot.children.allObjects as? [DataSnapshot] {
                for trip in tripSnapshot {
                    if trip.key == passengerKey {
                        if trip.childSnapshot(forPath: "tripIsAccepted").value as? Bool == true {
                            let driverKey = trip.childSnapshot(forPath: "driverKey").value as? String
                            handler(true, driverKey, trip.key)
                        } else {
                            handler(false, nil, nil)
                        }
                    }
                }
            }
        })
    }

    //hiermee zie ik als de bestuurder een passagier is of niet
    func userIsDriver(userKey: String, handler: @escaping(_ status: Bool) -> Void){
        DataService.instance._REF_DRIVERS.observeSingleEvent(of: .value, with:  { (driverSnapshot) in
            if let driverSnapshot = driverSnapshot.children.allObjects as? [DataSnapshot] {
                for driver in driverSnapshot {
                    if driver.key == userKey {
                        handler(true)
                    } else {
                        handler(false)
                    }
                }
            }
        })
    }
}
