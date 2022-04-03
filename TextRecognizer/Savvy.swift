//
//  Savvy.swift
//  TextRecognizer
//
//  Created by K Saravana Kumar on 19/05/20.
//  Copyright © 2020 K Saravana Kumar. All rights reserved.
//

import Foundation

var tabletCountIdentifyArray = ["caja","comprimidos","cápsulas","grageas","pill","dragee"]


class CentralVariables {
    var productKeyWords = [String]()
    var proudctList = [String: [ProductDetails]]()
    var ProductConType = [String:[concentrationType]]()
    var errors = errorlogs(dictionary: [:])
}
var global = CentralVariables()

enum concentrationType: String {
    case Mg = "mg", Ml = "ml"
}


class ProductDetails: NSObject {
    var name: String
    var descriptionText: String
    var speechtext: String
    var concentration: [Concentration]
    var presentation: String
    var concentrationKey: String
    var presentationKey: String
    var concentrationType: String
    var API: String?
    var laboratory: String
    
    init(dictionary: [String: AnyObject])throws {
        
        guard let name = dictionary["name"] as? String else {
            throw NSError(domain: "name nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.name = name
        /*
        guard let descriptionText = dictionary["description"] as? String else {
            throw NSError(domain: "descriptionText nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        */
        self.descriptionText = dictionary["description"] as? String ?? ""
        
        guard let speechtext = dictionary["speechtext"] as? String else {
            throw NSError(domain: "speechtext nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.speechtext = speechtext
        
        if let concentration = dictionary["concentration"] as? [String: AnyObject] {
            
           //self.concentration = concentration
            
            var concentrationArray = [Concentration]()
            
            for (key, value) in concentration {
                
                concentrationArray.append(Concentration.init(dictionary: concentration, key: key, value: value))
                
            }
            self.concentration = concentrationArray
            
        }else{
            self.concentration = [Concentration]()
        }
        /*
        guard let concentration = dictionary["concentration"] as? String else {
            throw NSError(domain: "concentration nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.concentration = concentration
        */
        
        guard let presentation = dictionary["presentation"] as? String else {
            throw NSError(domain: "presentation nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.presentation = presentation
        
        if let concentrationKey = dictionary["concentrationKey"] as? String {
            
            self.concentrationKey = concentrationKey
            
        }else if let concentrationKey = dictionary["concentrationKey"] as? Double {
            
            self.concentrationKey = String(concentrationKey)
            
        }else{
                throw NSError(domain: "concentrationKey nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        
//        guard let concentrationKey = dictionary["concentrationKey"] as? String || dictionary["concentrationKey"] as? Double else {
//
//        }
//        self.concentrationKey = concentrationKey
        
        guard let presentationKey = dictionary["presentationKey"] as? String else {
            throw NSError(domain: "presentationKey nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.presentationKey = presentationKey
        
        guard let concentrationType = dictionary["concentrationType"] as? String else {
            throw NSError(domain: "concentrationType nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.concentrationType = concentrationType
        /*
        guard let API = dictionary["API"] as? String else {
            throw NSError(domain: "API nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
         */
        self.API = dictionary["API"] as? String ?? ""
        
        guard let laboratory = dictionary["laboratory"] as? String else {
            throw NSError(domain: "laboratory nil", code: 101, userInfo: ["class": "productDetails", "value": dictionary])
        }
        self.laboratory = laboratory
        
        
    }
    
}

class errorlogs: NSObject {
    var noclearproduct: String
    var nodata: String
    var nomatching: String
    var dataInsufficient: String
    var rotateLeft: String
    var rotateUp: String
    var rotateDown: String
    
    init(dictionary: [String: AnyObject]){
        
        self.noclearproduct = dictionary["noclearproduct"] as? String ?? "Todavía estoy identificando el producto, un momento"
        
        self.nodata = dictionary["nodata"] as? String ?? "Ningún objeto encontrado"
        
        self.nomatching = dictionary["nomatching"] as? String ?? "Este no es tu producto que buscas"
        
        self.dataInsufficient = dictionary["dataInsufficient"] as? String ?? "Todavía estoy identificando el producto, un momento"
        
        self.rotateLeft = dictionary["dataInsufficient"] as? String ?? "La orientación de su producto es izquierda, gire el teléfono"
        self.rotateUp = dictionary["dataInsufficient"] as? String ?? "La orientación de su producto está arriba, gire el teléfono"
        self.rotateDown = dictionary["dataInsufficient"] as? String ?? "La orientación de su producto está hacia abajo, gire el teléfono"
        
        
    }
}

class Concentration: NSObject {
    var ingredient: [String]
    var ingredientValue: AnyObject
    
    init(dictionary: [String: AnyObject], key: String, value: AnyObject){
        
        if let increArray = value["key"] as? [String]{
           self.ingredient = increArray
        }else{
           self.ingredient = []
        }
        
        if let increValue = value["value"] as? AnyObject{
           self.ingredientValue = increValue
        }else{
            self.ingredientValue = "" as AnyObject
        }
        
        
    }
}


