//
//  AppDelegate.swift
//  ARGallery
//
//  Created by Martin Sumera on 17/01/2018.
//  Copyright © 2018 Martin Sumera. All rights reserved.
//

import UIKit
import Hero

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
     var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        let appAssembler = AppAssembler()
    
//        HeroDebugPlugin.isEnabled = true
        
        if var client = window?.rootViewController as? AppAssemblerClient {
            client.assembler = appAssembler
        }
        
        return true
    }

}

