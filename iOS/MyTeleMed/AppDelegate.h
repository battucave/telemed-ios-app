//
//  AppDelegate.h
//  MyTeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UIAlertViewDelegate>

@property (nonatomic) UIWindow *window;
@property (nonatomic) UIStoryboard *storyboard;

- (void)showMainScreen;

@end
