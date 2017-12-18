//
//  MessageNew2ViewController.h
//  MedToMed
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CoreTableViewController.h"

// Protocol to pass form values back to first message new screen when presses back button
@protocol Message2TableViewControllerDelegate <NSObject>
- (void)setFormValues:(NSMutableDictionary *)formValues;
@end

@interface MessageNew2TableViewController : CoreTableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (weak) id delegate;
@property (nonatomic) NSMutableDictionary *formValues;

@end
