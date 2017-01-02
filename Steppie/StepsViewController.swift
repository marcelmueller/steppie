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
    
    func querySteps() {
        let sampleQuery = HKSampleQuery(sampleType: healthKitManager.stepsCount!,
                                        predicate: nil,
                                        limit: 100,
                                        sortDescriptors: nil)
        { [unowned self] (query, results, error) in
            
            DispatchQueue.main.async {
                
                if let results = results as? [HKQuantitySample] {
                    self.steps = results
                    self.tableView.reloadData()
                }
                //            self.activityIndicator.stopAnimating()
            }
        }
        
        healthKitManager.healthStore?.execute(sampleQuery)
    }
    
}
