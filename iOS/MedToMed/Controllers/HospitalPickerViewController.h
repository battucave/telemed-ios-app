//
//  HospitalPickerViewController.h
//  TeleMed
//
//  Created by Shane Goodwin on 11/28/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HospitalPickerViewController : UIViewController <UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic) NSMutableArray *hospitals;

@end
