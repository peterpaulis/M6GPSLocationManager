//
//  M6GPSLocationManager.h
//  ...
//
//  Created by Peter Paulis (peter@min60.com) on 20.1.2011.
//  Copyright (c) 2013 Min60 s.r.o. - http://min60.com. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^M6GPSLocationManagerCompletion)(NSError * error, CLLocation * location);

@interface M6GPSLocationManager : NSObject<CLLocationManagerDelegate>

@property (nonatomic, strong, readonly) CLLocation * location;

+ (M6GPSLocationManager *)shared;

- (void)scopeToCurrentLocation:(M6GPSLocationManagerCompletion)completion;

- (void)scopeToCurrentLocationWithAcceptableAccuracy:(CLLocationAccuracy)acceptableAccuracy
                      maximumWaitTimeForBetterResult:(NSTimeInterval)maximumWaitTimeForBetterResult
                                     maximumAttempts:(NSInteger)maximumAttempts
                                        onCompletion:(M6GPSLocationManagerCompletion)completion;

@end
