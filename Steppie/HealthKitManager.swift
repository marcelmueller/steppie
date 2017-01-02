//
//  HealthKitManager.swift
//  Steppie
//
//  Created by Marcel Muller on 12/31/16.
//  Copyright © 2016 Marcel Muller. All rights reserved.
//

import HealthKit

class HealthKitManager {
    
    class var sharedInstance: HealthKitManager {
        struct Singleton {
            static let sharedInstance = HealthKitManager()
        }
        
        return Singleton.sharedInstance
    }
    
    let healthStore: HKHealthStore? = {
        if HKHealthStore.isHealthDataAvailable() {
            return HKHealthStore()
        } else {
            return nil
        }
    }()
    
    let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
    
    let stepsUnit = HKUnit.count()
    
    
   
}
