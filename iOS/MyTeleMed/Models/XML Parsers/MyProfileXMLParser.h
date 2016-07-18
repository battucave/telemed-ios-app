//
//  MyProfileXMLParser.h
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyProfileModel.h"
#import "RegisteredDeviceModel.h"

@interface MyProfileXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) MyProfileModel *myProfile;
@property (nonatomic) RegisteredDeviceModel *registeredDevice;
@property (nonatomic) NSMutableArray *myRegisteredDevices;
@property (nonatomic) NSMutableDictionary *timeZone;
@property (nonatomic) NSMutableString *currentElementValue;
@property (nonatomic) NSString *currentModel;

@end
