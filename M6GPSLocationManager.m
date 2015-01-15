//
//  M6GPSLocationManager.h
//  ...
//
//  Created by Peter Paulis (peter@min60.com) on 20.1.2011.
//  Copyright (c) 2013 Min60 s.r.o. - http://min60.com. All rights reserved.
//

#import "M6GPSLocationManager.h"

#define MaxWaitTime 10.f

@interface M6GPSLocationManager()

@property (nonatomic, strong) CLLocationManager * locationManager;

@property (nonatomic, strong) M6GPSLocationManagerCompletion completionBlock;

@property (nonatomic, assign) NSInteger attempt;
@property (nonatomic, assign, getter = isScoping) BOOL scoping;
@property (nonatomic, assign) CLLocationAccuracy acceptableAccuracy;

@property (nonatomic, strong) CLLocation * bestLocation;
@property (nonatomic, strong, readwrite) CLLocation * location;

@property (nonatomic, assign) NSInteger maximumWaitTimeForBetterResult;
@property (nonatomic, assign) NSInteger maximumAttempts;

@end

@implementation M6GPSLocationManager

static M6GPSLocationManager * _GPSLocationManager;

+ (M6GPSLocationManager *)shared {
    
    if (_GPSLocationManager) {
        return _GPSLocationManager;
    }
    
    _GPSLocationManager = [[M6GPSLocationManager alloc] init];
    return _GPSLocationManager;
}

- (id)init {
    self = [super init];
    if (self) {
    
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.delegate = self;
        
    }
    return self;
}

- (void)dealloc {
    [self cancelPerformStopUpdatingLocationWithBestResult];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Public
////////////////////////////////////////////////////////////////////////

- (void)scopeToCurrentLocation:(M6GPSLocationManagerCompletion)completion {
    
    [self scopeToCurrentLocationWithAcceptableAccuracy:25 maximumWaitTimeForBetterResult:5 maximumAttempts:5 onCompletion:completion];
    
}

- (void)scopeToCurrentLocationWithAcceptableAccuracy:(CLLocationAccuracy)acceptableAccuracy
                      maximumWaitTimeForBetterResult:(NSTimeInterval)maximumWaitTimeForBetterResult
                                     maximumAttempts:(NSInteger)maximumAttempts
                                        onCompletion:(M6GPSLocationManagerCompletion)completion
{
    [self cancelPerformStopUpdatingLocationWithBestResult];
    [self.locationManager stopUpdatingLocation];
    
    self.completionBlock = completion;
    self.attempt = 0;
    self.bestLocation = nil;
    self.scoping = YES;
    self.acceptableAccuracy = acceptableAccuracy;
    self.maximumWaitTimeForBetterResult = maximumWaitTimeForBetterResult;
    self.maximumAttempts = maximumAttempts;
    
    [self performSelector:@selector(stopUpdatingLocationWithBestResult) withObject:nil afterDelay:MaxWaitTime];
    [self.locationManager startUpdatingLocation];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)cancelPerformStopUpdatingLocationWithBestResult {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopUpdatingLocationWithBestResult) object:nil];
}

- (void)stopUpdatingLocationWithBestResult {
    
    if (!self.scoping) {
        return;
    }
    self.scoping = NO;
    [self.locationManager stopUpdatingLocation];
    [self cancelPerformStopUpdatingLocationWithBestResult];
    
    if (self.bestLocation == nil) {
        
        // this is probably the result of repeated kCLErrorLocationUnknown
        if (self.completionBlock) {
            self.completionBlock([NSError errorWithDomain:kCLErrorDomain code:kCLErrorLocationUnknown userInfo:nil], nil);
        }
        
    } else {
    
        self.location = self.bestLocation;
        if (self.completionBlock) {
            self.completionBlock(nil, self.bestLocation);
        }
    
    }
    
}

////////////////////////////////////////////////////////////////////////
#pragma mark - CLLocationManager
////////////////////////////////////////////////////////////////////////

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    if (!self.scoping) {
        [self.locationManager stopUpdatingLocation];
        return;
    }
    
    CLLocation * newLocation = [locations lastObject];
    
    NSDate * eventDate = newLocation.timestamp;
    NSTimeInterval howRecent = abs([eventDate timeIntervalSinceNow]);
    
    // failsafe
    if ((howRecent < 25) && (newLocation.horizontalAccuracy >= 0)) {
    
        ++self.attempt;
        if (self.attempt >= self.maximumAttempts) {
            
            // we have too many attempts, possibly moving?, no reason to take more
            [self stopUpdatingLocationWithBestResult];
            return;
            
        }
        
        if ((self.bestLocation == nil) || (newLocation.horizontalAccuracy < self.bestLocation.horizontalAccuracy)) {
            self.bestLocation = newLocation;
            
            // we have our result
            if (self.bestLocation.horizontalAccuracy <= self.acceptableAccuracy) {
                [self stopUpdatingLocationWithBestResult];
            } else {
                
                [self cancelPerformStopUpdatingLocationWithBestResult];
                [self performSelector:@selector(stopUpdatingLocationWithBestResult) withObject:nil afterDelay:self.maximumWaitTimeForBetterResult];
                
            }
            
        }
        
    }

}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
    if (!self.scoping) {
        return;
    }
    
    if ([error.domain isEqual:kCLErrorDomain]) {
        
        // this error may happen from time to time and looks temporary
        if (error.code == kCLErrorLocationUnknown) {
            [self.locationManager stopUpdatingLocation];
            [self.locationManager startUpdatingLocation];
            return;
        }
        
    }
    
    self.scoping = NO;
    [self.locationManager stopUpdatingLocation];
    [self cancelPerformStopUpdatingLocationWithBestResult];
    
    if (self.completionBlock) {
        self.completionBlock(error, nil);
    }
    
}

@end
