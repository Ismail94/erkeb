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
}
