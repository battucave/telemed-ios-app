//
//  MessageNew2ViewController.h
//  Med2Med
//
//  Created by Shane Goodwin on 11/22/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoreTableViewController.h"

@interface MessageNew2TableViewController : CoreTableViewController <UITextFieldDelegate, UITextViewDelegate>

@property (weak) id delegate;
@property (nonatomic) NSMutableDictionary *formValues;

@end
