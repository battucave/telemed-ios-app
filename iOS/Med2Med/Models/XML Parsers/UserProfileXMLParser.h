//
//  UserProfileXMLParser.h
//  Med2Med
//
//  Created by Shane Goodwin on 11/21/17.
//  Copyright © 2017 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UserProfileModel.h"

@interface UserProfileXMLParser : NSObject <NSXMLParserDelegate>

@property (nonatomic) UserProfileModel *userProfile;

@end
