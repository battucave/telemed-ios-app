//
//  main.m
//  TeleMed
//
//  Created by SolutionBuilt on 9/26/13.
//  Copyright (c) 2013 SolutionBuilt. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AppDelegate.h"
#import "TeleMedApplication.h"

int main(int argc, char * argv[])
{
	@autoreleasepool {
	    //return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
		return UIApplicationMain(argc, argv, NSStringFromClass([TeleMedApplication class]), NSStringFromClass([AppDelegate class]));
	}
}
