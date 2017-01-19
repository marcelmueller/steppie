//
//  StepsViewController.swift
//  Steppie
//
//  Created by Marcel Muller on 12/31/16.
//  Copyright © 2016 Marcel Muller. All rights reserved.
//

import UIKit
import HealthKit


class StepsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet fileprivate var tableView: UITableView!
    
    let stepCellIdentifier = "stepCell"
    fileprivate let totalStepsCellIdentifier = "totalStepsCell"
    
    fileprivate let healthKitManager = HealthKitManager.sharedInstance
    
    fileprivate var steps = [HKQuantitySample]()
    
    fileprivate let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        // Eu sei que tenho acesso aos dados do health porque consigo printar os passos dados hoje:
        
        print(steps.count)
        
        
        //      activityIndicator.startAnimating()
        requestHealthKitAuthorization()
        
    }
    
    // TableView Data Source
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: stepCellIdentifier)! as UITableViewCell
        
        let step = steps[indexPath.row]
        let numberOfSteps = Int(step.quantity.doubleValue(for: healthKitManager.stepsUnit))
        
        cell.textLabel?.text = "\(numberOfSteps) steps"
        cell.detailTextLabel?.text = dateFormatter.string(from: step.startDate)
        
        return cell
    }
}

private extension StepsViewController {
    
    func requestHealthKitAuthorization() {
        let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount as Any)
        healthKitManager.healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
            
            DispatchQueue.main.async {
                
                if success {
                    self.queryStepsSum()
                    self.querySteps()
                } else {
                    print(error.debugDescription)
                }
            }
        })
    }
    
    func queryStepsSum() {
        let sumOption = HKStatisticsOptions.cumulativeSum
        let statisticsSumQuery = HKStatisticsQuery(quantityType: healthKitManager.stepsCount!, quantitySamplePredicate: nil, options: sumOption) { [unowned self] (query, result, error) in
            
            DispatchQueue.main.async {
                
                if let sumQuantity = result?.sumQuantity() {
                    let headerView = self.tableView.dequeueReusableCell(withIdentifier: self.totalStepsCellIdentifier)! as UITableViewCell
                    
                    let numberOfSteps = Int(sumQuantity.doubleValue(for: self.healthKitManager.stepsUnit))
                    headerView.textLabel?.text = "\(numberOfSteps) total"
                    self.tableView.tableHeaderView = headerView
                }
                
                //            self.activityIndicator.stopAnimating()
            }
        }
        healthKitManager.healthStore?.execute(statisticsSumQuery)
    }
    
    // DAQUI PRA BAIXO É CÓDIGO DA APPPLE - https://developer.apple.com/reference/healthkit/hkstatisticscollectionquery
    
    func querySteps() {
        
        let calendar = Calendar.current
        
        let interval = NSDateComponents()
        interval.day = 7
        
        // Set the anchor at 3:00 a.m. Eu precisei atualizar isso porque não estava em Swift 3. Mas aí fica dando esse erro.
        var anchorComponents = calendar.dateComponents([.day, .month, .year, .weekday], from: Date())
        anchorComponents.hour = 3
        
        var day = (anchorComponents.weekday! - 2 + 7) % 7
        anchorComponents.day = day
        
        
        guard let anchorDate = calendar.date(from: anchorComponents) else {
            fatalError("*** unable to create a valid date from the given components ***")
        }
        
        guard let quantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount) else {
            fatalError("*** Unable to create a step count type ***")
        }
        
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: quantityType,
                                                quantitySamplePredicate: nil,
                                                options: .cumulativeSum,
                                                anchorDate: anchorDate,
                                                intervalComponents: interval as DateComponents)
        
        // Set the results handler
        query.initialResultsHandler = {
            query, results, error in
            
            // Set the results handler
            query.initialResultsHandler = {
                query, results, error in
                
                guard let statsCollection = results else {
                    // Perform proper error handling here
                    fatalError("*** An error occurred while calculating the statistics: \(error?.localizedDescription) ***")
                }
                
                let endDate = NSDate()
            
                
                guard let startDate = calendar.date(byAdding: .month, value: -3, to: endDate as Date) else {
                    fatalError("*** Unable to calculate the start date ***")
                }
                
                // Plot the weekly step counts over the past 3 months
                statsCollection.enumerateStatistics(from: startDate, to: endDate as Date) { [unowned self] statistics, stop in
                    
                    if let quantity = statistics.sumQuantity() {
                        let date = statistics.startDate
                        let value = quantity.doubleValue(for: HKUnit.count())
                        
                        // Call a custom method to plot each data point.
                        self.plotWeeklyStepCount(value, forDate: date)
                    }
                }
            }
            
            healthStore.executeQuery(query)
        }
    }}
