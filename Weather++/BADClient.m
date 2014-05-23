//
//  BADClient.m
//  Weather++
//
//  Created by brett davis on 5/23/14.
//  Copyright (c) 2014 brett davis. All rights reserved.
//

#import "BADClient.h"
#import "BADCondition.h"
#import "BADDailyForecast.h"

@interface BADClient()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation BADClient

- (id)init {
    if (self = [super init]) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config];
    }
    return self;
}

- (RACSignal *)fetchJSONFromURL:(NSURL *)url {
    NSLog(@"Fetching: %@",url.absoluteString);
    
    // Returns the signal (factory)
    return [[RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        // Creates an NSURLSessionDataTask to fetch data from the URL
        NSURLSessionDataTask *dataTask = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (! error) {
                NSError *jsonError = nil;
                id json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
                if (! jsonError) {
                    // Serializes the JSON
                    [subscriber sendNext:json];
                }
                else {
                    // Notify the subscriber of error
                    [subscriber sendError:jsonError];
                }
            }
            else {
                // Notify the subscriber of error
                [subscriber sendError:error];
            }
            
            // Notify the subscriber that request is completed
            [subscriber sendCompleted];        }];
        
        // Starts the network request
        [dataTask resume];
        
        // Creates and returns an RACDisposable object which handles the cleanup
        return [RACDisposable disposableWithBlock:^{
            [dataTask cancel];
        }];
    }] doError:^(NSError *error) {
        // Logs any errors
        NSLog(@"%@",error);
    }];
}

- (RACSignal *)fetchCurrentConditionsForLocation:(CLLocationCoordinate2D)coordinate {
    NSLog(@" getting current conditions");
    
    // Formats the URL with current latitude and longitude
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/weather?lat=%f&lon=%f&units=imperial",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Create the signal
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Convert the JSON into BADCondition object
        return [MTLJSONAdapter modelOfClass:[BADCondition class] fromJSONDictionary:json error:nil];
    }];
}

- (RACSignal *)fetchHourlyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast?lat=%f&lon=%f&units=imperial&cnt=12",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Map the JSON
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Build an RACSequence
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Map new list of objects
        return [[list map:^(NSDictionary *item) {
            // Convert JSON into BADCondition object
            return [MTLJSONAdapter modelOfClass:[BADCondition class] fromJSONDictionary:item error:nil];
            // get an array
        }] array];
    }];
}

- (RACSignal *)fetchDailyForecastForLocation:(CLLocationCoordinate2D)coordinate {
    NSString *urlString = [NSString stringWithFormat:@"http://api.openweathermap.org/data/2.5/forecast/daily?lat=%f&lon=%f&units=imperial&cnt=7",coordinate.latitude, coordinate.longitude];
    NSURL *url = [NSURL URLWithString:urlString];
    
    // Use the generic fetch method and map results to convert into an array of Mantle objects
    return [[self fetchJSONFromURL:url] map:^(NSDictionary *json) {
        // Build a sequence from the list of raw JSON
        RACSequence *list = [json[@"list"] rac_sequence];
        
        // Use a function to map results from JSON to Mantle objects
        return [[list map:^(NSDictionary *item) {
            return [MTLJSONAdapter modelOfClass:[BADDailyForecast class] fromJSONDictionary:item error:nil];
        }] array];
    }];
}

@end
