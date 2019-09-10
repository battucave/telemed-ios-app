//
//  ErrorAlertController.h
//  TeleMed
//
//  Created by Shane Goodwin on 11/18/16.
//  Copyright © 2016 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ErrorAlertController : UIAlertController

+ (instancetype _Nonnull)sharedInstance;

- (instancetype _Nonnull)show:(NSError * _Nullable)error;
- (instancetype _Nonnull)show:(NSError * _Nullable)error withRetryCallback:(void (^ _Nullable)(void))callback;
- (instancetype _Nonnull)show:(NSError * _Nullable)error withRetryCallback:(void (^ _Nullable)(void))retryCallback cancelCallback:(void (^ _Nullable)(void))cancelCallback;
- (void)dismiss;
- (void)presentAlertController:(BOOL)animated completion:(void (^ _Nullable)(void))completion; // Only used by CallModel

@end
