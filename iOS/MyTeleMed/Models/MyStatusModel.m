//
//  MyStatusModel.m
//  MyTeleMed
//
//  Created by Shane Goodwin on 5/26/15.
//  Copyright (c) 2015 SolutionBuilt. All rights reserved.
//

#import "MyStatusModel.h"
#import "MyStatusXMLParser.h"

#ifdef DEBUG
	#import "MyProfileModel.h"
#endif

@implementation MyStatusModel

+ (instancetype)sharedInstance
{
	static dispatch_once_t token;
	static MyStatusModel *sharedMyStatusInstance = nil;
	
	dispatch_once(&token, ^
	{
		sharedMyStatusInstance = [[self alloc] init];
	});
	
	return sharedMyStatusInstance;
}

- (void)getWithCallback:(void (^)(BOOL success, MyStatusModel *status, NSError *error))callback
{
	[self.operationManager GET:@"MyStatus" parameters:nil success:^(__unused AFHTTPRequestOperation *operation, id responseObject)
	{
		NSXMLParser *xmlParser = (NSXMLParser *)responseObject;
		MyStatusXMLParser *parser = [[MyStatusXMLParser alloc] init];
		
		[parser setMyStatus:self];
		[xmlParser setDelegate:parser];
		
		// Parse the xml file
		if ([xmlParser parse])
		{
			/*/ TESTING ONLY (used to generate fictitious on call entries if none were found)
			#ifdef DEBUG
				if ([self.CurrentOnCallEntries count] == 0)
				{
					// Config settings
					static int numberOfOnCallEntries = 8;
					static int numberOfFutureOnCallEntriesPerDay = 3;
					
					NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
					NSMutableArray *debugCurrentOnCallEntries = [[NSMutableArray alloc] init];
					NSMutableArray *debugFutureOnCallEntries = [[NSMutableArray alloc] init];
					NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
					MyProfileModel *profile = [MyProfileModel sharedInstance];
					
					// Generate current on call entries (and future on call entries if none set)
					for (int i = 0; i < numberOfOnCallEntries; i++)
					{
						OnCallEntryModel *currentOnCallEntry = [[OnCallEntryModel alloc] init];
						NSDate *onCallDate = [calendar dateBySettingHour:i minute:0 second:0 ofDate:[NSDate date] options:0];
						
						[currentOnCallEntry setAccountID:profile.MyPreferredAccount.ID];
						[currentOnCallEntry setAccountKey:[numberFormatter numberFromString:profile.MyPreferredAccount.PublicKey]];
						[currentOnCallEntry setAccountName:profile.MyPreferredAccount.Name];
						[currentOnCallEntry setSlotDesc:@"Slot Description"];
						[currentOnCallEntry setSlotID:[NSNumber numberWithInt:i]];
						[currentOnCallEntry setStarted:onCallDate];
						[currentOnCallEntry setWillEnd:[NSDate dateWithTimeInterval:86400 sinceDate:onCallDate]];
						
						[debugCurrentOnCallEntries addObject:currentOnCallEntry];
						
						if ([self.FutureOnCallEntries count] == 0)
						{
							OnCallEntryModel *futureOnCallEntry = [[OnCallEntryModel alloc] init];
							
							[futureOnCallEntry setAccountID:profile.MyPreferredAccount.ID];
							[futureOnCallEntry setAccountKey:[numberFormatter numberFromString:profile.MyPreferredAccount.PublicKey]];
							[futureOnCallEntry setAccountName:profile.MyPreferredAccount.Name];
							[futureOnCallEntry setSlotDesc:@"Slot Description"];
							[futureOnCallEntry setSlotID:[NSNumber numberWithInt:(i + numberOfOnCallEntries)]];
							[futureOnCallEntry setWillStart:[NSDate dateWithTimeInterval:(86400 * ((i / numberOfFutureOnCallEntriesPerDay) + 1)) sinceDate:onCallDate]];
							
							[debugFutureOnCallEntries addObject:futureOnCallEntry];
							
							if (i == 0)
							{
								[self setNextOnCall:futureOnCallEntry.WillStart];
							}
						}
					}
					
					[self setCurrentOnCallEntries:debugCurrentOnCallEntries];
					[self setOnCallNow:YES];
					
					if ([debugFutureOnCallEntries count] > 0)
					{
						[self setFutureOnCallEntries:debugFutureOnCallEntries];
					}
				}
			#endif
			//*/
			
			// Sort on call now entries by start time
			self.CurrentOnCallEntries = [self.CurrentOnCallEntries sortedArrayUsingComparator:^NSComparisonResult(OnCallEntryModel *onCallEntryModelA, OnCallEntryModel *onCallEntryModelB)
			{
				return [onCallEntryModelA.Started compare:onCallEntryModelB.Started];
			}];
			
			// Sort next on call entries by start time
			self.FutureOnCallEntries = [self.FutureOnCallEntries sortedArrayUsingComparator:^NSComparisonResult(OnCallEntryModel *onCallEntryModelA, OnCallEntryModel *onCallEntryModelB)
			{
				return [onCallEntryModelA.WillStart compare:onCallEntryModelB.WillStart];
			}];
			
			callback(YES, self, nil);
		}
		// Error parsing xml file
		else
		{
			NSError *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier] code:10 userInfo:[[NSDictionary alloc] initWithObjectsAndKeys:@"Status Error", NSLocalizedFailureReasonErrorKey, @"There was a problem retrieving your Status.", NSLocalizedDescriptionKey, nil]];
			
			callback(NO, nil, error);
		}
	}
	failure:^(__unused AFHTTPRequestOperation *operation, NSError *error)
	{
		NSLog(@"MyStatusModel Error: %@", error);
		
		// Build a generic error message
		error = [self buildError:error usingData:operation.responseData withGenericMessage:@"There was a problem retrieving your Status." andTitle:@"Status Error"];
		
		callback(NO, nil, error);
	}];
}

@end

@implementation OnCallEntryModel

@end
