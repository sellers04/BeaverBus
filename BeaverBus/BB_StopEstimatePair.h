//
//  BB_StopEstimatePair.h
//  BeaverBus
//
//  Created by norredm on 9/22/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMaps/GoogleMaps.h>

@interface BB_StopEstimatePair : NSObject

@property (strong, nonatomic) NSNumber *eta;
@property (strong, nonatomic) GMSMarker *marker;


@end
