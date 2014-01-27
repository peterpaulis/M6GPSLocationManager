M6GPSLocationManager
====================

Cocoa iOS Location manager based on CLLocationManager

- If the result accuracy is better than acceptableAccuracy, we are done
- If we get an update on occuracy, we wait maximumWaitTimeForBetterResult to get a better one, if this doesn't happen, we are done and take the best one
- If we are constantly getting updates, which exceed maximumAttempts, we take th best one (probably we are moving anyway)
- If we don't get any other update in 30 sec, we are done (there won't be probably any other update)

<pre>
- (void)scopeToCurrentLocationWithAcceptableAccuracy:(CLLocationAccuracy)acceptableAccuracy
                      maximumWaitTimeForBetterResult:(NSTimeInterval)maximumWaitTimeForBetterResult
                                     maximumAttempts:(NSInteger)maximumAttempts
                                        onCompletion:(M6GPSLocationManagerCompletion)completion;
</pre>

Simple method with predefined values
<pre>
- (void)scopeToCurrentLocation:(M6GPSLocationManagerCompletion)completion;
</pre>

#Usage
<pre>
[[M6GPSLocationManager shared] scopeToCurrentLocation:^(NSError *error, CLLocation *location) {
  // do smth. usefull      
}];
</pre>
