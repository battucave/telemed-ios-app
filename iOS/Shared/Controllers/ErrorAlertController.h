//
//  ErrorAlertController.h
//  TeleMed
//
//  Created by Shane Goodwin on 11/18/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ErrorAlertController : UIAlertController

+ (instancetype)sharedInstance;

- (instancetype)show:(NSError *)error;
- (instancetype)show:(NSError *)error withCallback:(void (^)(void))callback;
- (instancetype)show:(NSError *)error withRetryCallback:(void (^)(void))retryCallback cancelCallback:(void (^)(void))cancelCallback;
- (void)dismiss;
- (void)presentAlertController:(BOOL)animated completion:(void (^ _Nullable)(void))completion; // Only used by CallModel

@end
