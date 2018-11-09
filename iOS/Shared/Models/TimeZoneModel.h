//
//  TimeZoneModel.h
//  Med2Med
//
//  Created by Shane Goodwin on 7/13/18.
//  Copyright © 2018 SolutionBuilt. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Model.h"

@protocol TimeZoneDelegate <NSObject>

@required
- (void)updateTimeZones:(NSArray *)newTimeZones;

@optional
- (void)updateTimeZonesError:(NSError *)error;

@end

@interface TimeZoneModel : Model

@property (weak) id delegate;

@property (nonatomic) NSNumber *ID; // Med2Med Only
@property (nonatomic) NSString *Description;
@property (nonatomic) NSNumber *Offset;

- (void)getTimeZones;

@end
