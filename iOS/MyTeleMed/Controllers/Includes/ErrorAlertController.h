//
//  ErrorAlertController.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 11/18/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ErrorAlertController : UIAlertController

+ (instancetype)sharedInstance;

- (instancetype)show:(NSError *)error;
- (instancetype)show:(NSError *)error withCallback:(void (^)(void))callback;
- (void)dismiss;

@end
