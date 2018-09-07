//
//  HospitalPickerViewController.h
//  Med2Med
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreViewController.h"
#import "HospitalModel.h"

@interface HospitalPickerViewController : CoreViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *hospitals;
@property (nonatomic) HospitalModel *selectedHospital;
@property (nonatomic) BOOL shouldSelectHospital;

@end
