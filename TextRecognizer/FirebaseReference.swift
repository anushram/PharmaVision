//
//  FirebaseReference.swift
//  TextRecognizer
//
//  Created by K Saravana Kumar on 28/04/20.
//  Copyright © 2020 K Saravana Kumar. All rights reserved.
//

import Foundation
import Firebase

func getProductName(completion: @escaping(_ status: Bool,_ object: [String]?)->()) {
    
    let userRef = Database.database().reference().child("Products")
    userRef.observe(.value, with: { (snapshot) in
        
        //        let mutableString = NSMutableString(string: "Rimact\U00e1n")
        //        CFStringTransform(mutableString, nil, "Any-Hex/Java" as NSString, true)
        //
        //        print(mutableString)
        //        let foo = "Rimact\\U00e1n"
        //        let bar = foo.folding(options: .diacriticInsensitive, locale: .current)
        //        print(snapshot.value)
        if let productKeyWords = snapshot.value as? [AnyObject]{
            
            var productNames = [String]()
            
            
            for productName in productKeyWords {
                
                
                if let proDi = productName as? String{
                    
                    productNames.append(proDi)
                    
                }
                
            }
            
            completion(true, productNames)
        }else{
            completion(false, nil)
        }
        
    }) { (error) in
        completion(false, nil)
    }
    
}

func getErrorLogs(completion: @escaping(_ status: Bool,_ object: errorlogs?)->()) {
    
    let userRef = Database.database().reference().child("errorlogs")
    userRef.observe(.value, with: { (snapshot) in
        
        if let errors = snapshot.value as? [String: AnyObject]{
            
            let errorLogs = errorlogs.init(dictionary: errors)
            
            completion(true, errorLogs)
        }else{
            completion(false, nil)
        }
        
    }) { (error) in
        completion(false, nil)
    }
    
}

func getProductDetails(completion: @escaping(_ status: Bool,_ object: [String: [ProductDetails]]?)->()) {
    
    let userRef = Database.database().reference().child("ProductDetails")
    userRef.observe(.value, with: { (snapshot) in
        
        var productList = [String: [ProductDetails]]()
        
        if let productDetailDict = snapshot.value as? [String: Any]{
            
            for (productname, productValue) in productDetailDict {
                
                if let conType = productValue as? [String: Any]{
                    
                    for (_, conTypeVal) in conType {
                        
                        if let concentration = conTypeVal as? [String: Any]{
                            
                            for (_, concentrationValue) in concentration {
                                
                                if let presentation = concentrationValue as? [String: Any]{
                                    
                                    for (_,presentationValue) in presentation {
                                        
                                        if let productValues = presentationValue as? [String: AnyObject] {
                                            do {
                                                let productDetails = try ProductDetails.init(dictionary: productValues)
                                                if let customObj = productList[productname.lowercased()]{
                                                    
                                                    let ifExist = customObj.filter { (productUnique) -> Bool in
                                                        
                                                        return (productUnique.name == productDetails.name && productUnique.concentrationType == productDetails.concentrationType && productUnique.concentrationKey == productDetails.concentrationKey && productUnique.presentationKey == productDetails.presentationKey)
                                                        
                                                    }
                                                    
                                                    if ifExist.count == 0 {
                                                        var cusArray = customObj
                                                        cusArray.append(productDetails)
                                                        productList[productname.lowercased()] = cusArray
                                                    }else{
                                                        let cusArray = customObj
                                                        productList[productname.lowercased()] = cusArray
                                                    }
                                                    
                                                }else{
                                                    
                                                    var cusArray = [ProductDetails]()
                                                    cusArray.append(productDetails)
                                                    productList[productname.lowercased()] = cusArray
                                                }
                                                
                                                //= productDetails
                                            } catch let error {
                                                print(error)
                                            }
                                        }
                                    }
                                }
                                
                            }
                            
                            
                        }
                        
                    }
                    
                }
                
                /*
                 do {
                 let productDetails = try ProductDetails.init(dictionary: value)
                 productList[key] = productDetails
                 } catch let error {
                 print(error)
                 }
                 */
                
            }
            completion(true, productList)
            
        }else{
            completion(false, nil)
        }
        
    }) { (error) in
        completion(false, nil)
    }
    
}
