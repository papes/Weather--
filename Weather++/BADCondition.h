//
//  BADCondition.h
//  Weather++
//
//  Created by brett davis on 5/23/14.
//  Copyright (c) 2014 brett davis. All rights reserved.
//

#import "MTLModel.h"
#import <Mantle.h>

@interface BADCondition : MTLModel <MTLJSONSerializing>

// Weather data properties
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, strong) NSNumber *humidity;
@property (nonatomic, strong) NSNumber *temperature;
@property (nonatomic, strong) NSNumber *tempHigh;
@property (nonatomic, strong) NSNumber *tempLow;
@property (nonatomic, strong) NSString *locationName;
@property (nonatomic, strong) NSDate *sunrise;
@property (nonatomic, strong) NSDate *sunset;
@property (nonatomic, strong) NSString *conditionDescription;
@property (nonatomic, strong) NSString *condition;
@property (nonatomic, strong) NSNumber *windBearing;
@property (nonatomic, strong) NSNumber *windSpeed;
@property (nonatomic, strong) NSString *icon;

// Map weather conditions to image files
- (NSString *)imageName;

@end
