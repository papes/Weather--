//
//  BADManager.m
//  Weather++
//
//  Created by brett davis on 5/23/14.
//  Copyright (c) 2014 brett davis. All rights reserved.
//

#import "BADManager.h"
#import "BADClient.h"
#import <TSMessages/TSMessage.h>

@interface BADManager ()

// this will allow us to change the values "behind the scenes"
@property (nonatomic, strong, readwrite) BADCondition *currentCondition;
@property (nonatomic, strong, readwrite) CLLocation *currentLocation;
@property (nonatomic, strong, readwrite) NSArray *hourlyForecast;
@property (nonatomic, strong, readwrite) NSArray *dailyForecast;

// for location finding and data fetching
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, assign) BOOL isFirstUpdate;
@property (nonatomic, strong) BADClient *client;

@end

@implementation BADManager

+ (instancetype)sharedManager {
    static id _sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[self alloc] init];
    });
    
    return _sharedManager;
}

- (id)init {
    if (self = [super init]) {
        // Creates location manager and sets delegate to self
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        
        // Creates BADClient object form manager
        _client = [[BADClient alloc] init];
        
        // Observes the currentLocation key on itself which returns a signal
        [[[[RACObserve(self, currentLocation)
            // currentLocation cannot be nil
            ignore:nil]
           
           // Flatten and subscribe to all 3 signals when currentLocation updates
           flattenMap:^(CLLocation *newLocation) {
               return [RACSignal merge:@[
                                         [self updateCurrentConditions],
                                         [self updateDailyForecast],
                                         [self updateHourlyForecast]
                                         ]];
               // Deliver the signal to the subscribers on the main thread
           }] deliverOn:RACScheduler.mainThreadScheduler]
         // Display a banner when error occurs
         // TODO: make this happen within the View instead of Model
         subscribeError:^(NSError *error) {
             [TSMessage showNotificationWithTitle:@"Error"
                                         subtitle:@"There was a problem fetching the latest weather."
                                             type:TSMessageNotificationTypeError];
         }];
    }
    return self;
}

- (void)findCurrentLocation {
    self.isFirstUpdate = YES;
    [self.locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    // Ignore first location due to cache
    if (self.isFirstUpdate) {
        self.isFirstUpdate = NO;
        return;
    }
    
    CLLocation *location = [locations lastObject];
    
    // Stop further updates once we obtain accurate location
    if (location.horizontalAccuracy > 0) {
        // This triggers the RACObservable
        self.currentLocation = location;
        [self.locationManager stopUpdatingLocation];
    }
}

- (RACSignal *)updateCurrentConditions {
    return [[self.client fetchCurrentConditionsForLocation:self.currentLocation.coordinate] doNext:^(BADCondition *condition) {
        self.currentCondition = condition;
        NSLog(@"temp is %f",[self.currentCondition.temperature floatValue]);
        NSLog(@"high is %f",[self.currentCondition.tempHigh floatValue]);
        NSLog(@"low is %f",[self.currentCondition.tempLow floatValue]);
    }];
}

- (RACSignal *)updateHourlyForecast {
    return [[self.client fetchHourlyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.hourlyForecast = conditions;
    }];
}

- (RACSignal *)updateDailyForecast {
    return [[self.client fetchDailyForecastForLocation:self.currentLocation.coordinate] doNext:^(NSArray *conditions) {
        self.dailyForecast = conditions;
    }];
}

@end
