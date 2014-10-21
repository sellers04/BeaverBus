//
//  BB_ShuttleUpdater.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_ShuttleUpdater.h"
#import "BB_StopEstimatePair.h"
#import "BB_Stop.h"
#import "BB_Shuttle.h"
#import "BB_MapState.h"
#import "BB_ViewController.h"
#import "Reachability.h"
#import <math.h>

int const NORTH_ROUTE = 7;
int const WEST_ROUTE = 9;
int const EAST_ROUTE = 8;

int const NORTH_ETA = 0;
int const WEST1_ETA = 1;
int const WEST2_ETA = 2;
int const EAST_ETA = 3;

static BB_ShuttleUpdater *shuttleUpdater = NULL;
static BB_MapState *mapState;

dispatch_semaphore_t sem;

NSTimer *timer;

@implementation BB_ShuttleUpdater


@synthesize session = _session;

- (NSURLSession *)session
{
    if(!_session)
    {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    }
    return _session;
}

+ (BB_ShuttleUpdater *)get
{
    @synchronized(shuttleUpdater)
    {
        if (!shuttleUpdater || shuttleUpdater == NULL){
            shuttleUpdater = [[BB_ShuttleUpdater alloc] init];
            mapState = [BB_MapState get];
        }
        return shuttleUpdater;
    }
}

- (BOOL)connected
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus networkStatus = [reachability currentReachabilityStatus];
    return networkStatus != NotReachable;
}

- (BOOL)initialNetworkRequest
{


    NSLog(@"initialNetworkRequest");

    mapState.shuttles = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++){
        BB_Shuttle *newShuttle = [[BB_Shuttle alloc] init];
        newShuttle.isOnline = FALSE;
        [mapState.shuttles addObject:newShuttle];
    }

    sem = dispatch_semaphore_create(0);

    if (![self connected]) {
        // not connected
        [BB_ViewController get].showNetworkErrorAlert;
    } else {
        // connected, do some internet stuff
            [self getStops];
    }



    //[self getShuttles:YES];
   // dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
   // dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

   // [self getEstimates:YES];
  //  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    //TODO: also check for successful getEstimates
    if (!mapState.stopsRequestComplete || !mapState.shuttleRequestComplete){
        //If either failed, return early
       // return false;
    }

    //dispatch_async(dispatch_get_main_queue(), ^{
       // [mapState initStopMarkers];
       // [mapState initShuttleMarkers];
       // [self distributeStops];
    //});


    return true;
}

- (void)startShuttleUpdaterHandler
{
    NSLog(@"startShuttleUpdaterHandler");

    [timer invalidate];
    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateEvent) userInfo:nil repeats:TRUE];
}

- (void)stopShuttleUpdaterHandler
{
    [timer invalidate];
}

- (void)updateEvent
{
    NSLog(@"updateEvent");

    mapState.shuttleRequestComplete = false;
    sem = dispatch_semaphore_create(0);

    if (![self connected]) {
        // not connected, show some error window/view
        [BB_ViewController get].slideUpdateErrorView;
       // [BB_ViewController get].showUpdateErrorView;
    } else {
        // connected, do some internet stuff
        [self getShuttles:NO];
    }

   // [self getShuttles:NO];

 //  dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    if (mapState.shuttleRequestComplete){
        //Successful update
     //   [self animateHandler];
    } else {
        //Failed to update
       // NSLog(@"failed to update");
        //TODO: show update fail error
    //    [[BB_ViewController get] showUpdateErrorView];
    }

    //TODO: check for getEstimates fail
   // [self getEstimates:NO];

    //dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    //[self distributeStops];
    
    //[BB_MapState get].stopsInvalid = true;


}

-(void)animateHandler
{
    NSLog(@"inside anim");
    NSMutableArray *shuttles = [BB_MapState get].shuttles;

    for (BB_Shuttle *shuttle in shuttles) {

        //If a shuttle comes online after update, make its marker visible
        if (shuttle.marker.opacity == 0){
            shuttle.marker.opacity = 1;
        }

        //Heading goes to 0 when at a stop, and looks strange. Try to avoid?
        if ([shuttle.heading doubleValue] != 0 || shuttle.groundSpeed != 0){
            [shuttle.marker setRotation:([shuttle.heading doubleValue])];
        }
        [shuttle.marker setPosition:CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude)];
    }
}

-(NSArray*)getDistance:(BB_Shuttle *)shuttle andIncrementVarible:(int)inc
{
    double latDiff = abs(shuttle.marker.position.latitude - shuttle.latitude);
    double lonDiff = abs(shuttle.marker.position.longitude - shuttle.longitude);

    double hypDist = sqrt((latDiff*latDiff)+(lonDiff*lonDiff));

    double numIterations = hypDist/inc;

    double latInc = latDiff/numIterations;
    double lonInc = lonDiff/numIterations;
    NSArray *arr = [NSArray arrayWithObjects:[NSNumber numberWithDouble:latInc], [NSNumber numberWithDouble:lonInc],nil];

    return arr;
}

- (void) distributeStops{
    NSMutableArray *northEstimates = [[NSMutableArray alloc] init];
    NSMutableArray *west1Estimates = [[NSMutableArray alloc] init];
    NSMutableArray *west2Estimates = [[NSMutableArray alloc] init];
    NSMutableArray *eastEstimates = [[NSMutableArray alloc] init];
    
    for (BB_Stop *stop in mapState.stops) {
        for (NSNumber *num in stop.servicedRoutes) {
            
            BB_StopEstimatePair *newPair = [[BB_StopEstimatePair alloc] init];
            BB_StopEstimatePair *altPair = [[BB_StopEstimatePair alloc] init];
            
            switch ([num integerValue]) {
                case NORTH_ROUTE:
                    newPair.eta = stop.etaArray[NORTH_ETA];
                    newPair.marker = stop.marker;
                    [northEstimates addObject:newPair];
                    break;
                case WEST_ROUTE:
                    newPair.eta = stop.etaArray[WEST1_ETA];
                    newPair.marker = stop.marker;
                    [west1Estimates addObject:newPair];
                    //May cause problems. pass by value?
                    altPair.eta = stop.etaArray[WEST2_ETA];
                    altPair.marker = stop.marker;
                    [west2Estimates addObject:altPair];
                    break;
                case EAST_ROUTE:
                    newPair.eta = stop.etaArray[EAST_ETA];
                    newPair.marker = stop.marker;
                    [eastEstimates addObject:newPair];
                    break;
                default:
                    break;
            }
        }
    }
    
    NSComparator comparator = ^(BB_StopEstimatePair *obj1, BB_StopEstimatePair *obj2) {
        if([obj1.eta integerValue] > [obj2.eta integerValue]){
            return NSOrderedDescending;
        }
        if([obj1.eta integerValue] < [obj2.eta integerValue]){
            
            return NSOrderedAscending;
        }
        return NSOrderedSame;
    };
    
    NSMutableArray *shuttles = mapState.shuttles;
    
    [northEstimates sortUsingComparator:comparator];
    [west1Estimates sortUsingComparator:comparator];
    [west2Estimates sortUsingComparator:comparator];
    [eastEstimates sortUsingComparator:comparator];

    ((BB_Shuttle*)shuttles[0]).stopEstimatePairs= northEstimates;
    ((BB_Shuttle*)shuttles[1]).stopEstimatePairs = west1Estimates;
    ((BB_Shuttle*)shuttles[2]).stopEstimatePairs = west2Estimates;
    ((BB_Shuttle*)shuttles[3]).stopEstimatePairs = eastEstimates;
    //NSLog(@"%d, %d, %d, %d", [northEstimates count], [west1Estimates count], [west2Estimates count], [eastEstimates count]);



    dispatch_async(dispatch_get_main_queue(), ^{

    //Redraw the infowindow by setting the selected marker again
        if ([mapState.mapView.selectedMarker.userData isKindOfClass:[BB_Stop class]]){
            mapState.mapView.selectedMarker = mapState.mapView.selectedMarker;
        }
    });

}


- (BOOL) getStops
{
    NSLog(@"getStops()");
    NSURL *url = [NSURL URLWithString:@"http://osushuttles.com/Services/JSONPRelay.svc/GetStops"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";


    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil){
            NSError *jsonParsingError = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
            
            NSMutableArray *stopsArray = [[NSMutableArray alloc] init];
            int count = [jsonArray count];
            NSMutableArray *seenRouteLocs = [[NSMutableArray alloc] init];

            NSMutableDictionary* stopIDObjectPairs = [[NSMutableDictionary alloc] init];

            for(int i = 0; i < count; i++){
                BOOL found = false;
                id obj = [jsonArray objectAtIndex:i];
                NSNumber *routeId = [NSNumber numberWithInteger:[[obj objectForKey:@"RouteID"] integerValue]];
                double latitude = [[obj objectForKey:@"Latitude"] doubleValue];
                double longitude = [[obj objectForKey:@"Longitude"] doubleValue];

                for (CLLocation *locIter in seenRouteLocs) {
                    if ([locIter coordinate].latitude == latitude && [locIter coordinate].longitude == longitude) {
                        [((BB_Stop*)[stopsArray objectAtIndex:[seenRouteLocs indexOfObject:locIter]]).servicedRoutes addObject:routeId];
                        //NSLog(@"Duplicate. Adding %@ to stop", routeId);

                        [stopIDObjectPairs setObject:((BB_Stop*)[stopsArray objectAtIndex:[seenRouteLocs indexOfObject:locIter]]) forKey:[obj objectForKey:@"RouteStopID"]];

                        found = true;
                        break;
                    }
                }

                if(!found){
                    //NSLog(@"New Stop");
                    BB_Stop *newStop = [[BB_Stop alloc] init];
                    newStop.servicedRoutes = [[NSMutableArray alloc] initWithObjects:routeId, nil];
                    newStop.name = [obj objectForKey:@"Description"];
                    
                    newStop.latitude = latitude;
                    newStop.longitude = longitude;
                    
                    newStop.etaArray = [NSMutableArray arrayWithObjects:@-1, @-1, @-1, @-1, nil];
                    
                    CLLocation *loc = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
                    [seenRouteLocs addObject:loc];
                    [stopsArray addObject:newStop];

                    [stopIDObjectPairs setObject:newStop forKey:[obj objectForKey:@"RouteStopID"]];
                }

            }

            mapState.stopIDObjectPairs = stopIDObjectPairs;

            mapState.stops = stopsArray;
            //seenRouteLocs = NULL;
            mapState.stopsRequestComplete = true;
            
           // dispatch_semaphore_signal(sem);
            [self getShuttles:YES];
        }else{

            mapState.stopsRequestComplete = false;
           // dispatch_semaphore_signal(sem);

        }
    }];

    [getDataTask resume];
    
    return true;
}

- (BOOL) getEstimates:(BOOL)initialRequest
{
    NSLog(@"getEstimates");
    NSURL *url = [NSURL URLWithString:@"http://www.osushuttles.com/Services/JSONPRelay.svc/GetRouteStopArrivals"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];

        for (id obj in jsonArray){
            NSNumber *stopId = [obj objectForKey:@"RouteStopID"];

            NSArray *jsonVehicleEstimates = [obj objectForKey:@"VehicleEstimates"];

            BB_Stop *stop = [mapState.stopIDObjectPairs objectForKey:stopId];

            NSNumber *vehicleId;
            double num;
            switch ([[obj objectForKey:@"RouteID"] integerValue]){
                case NORTH_ROUTE:
                    if ([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"OnRoute"] boolValue] == false){
                        stop.etaArray[NORTH_ETA] = @-1;
                    } else{
                        num = round([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"] doubleValue] / 60);
                        stop.etaArray[NORTH_ETA] = [NSNumber numberWithDouble:num];
                    }
                    break;

                case WEST_ROUTE:
                    vehicleId = [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"VehicleID"];

                    if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == vehicleId){
                        if ([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"OnRoute"] boolValue] == false){
                            stop.etaArray[WEST1_ETA] = @-1;
                        } else {
                            num = round([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"] doubleValue] / 60);
                            stop.etaArray[WEST1_ETA] = [NSNumber numberWithDouble:num];
                        }
                    }

                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == vehicleId){
                        if ([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"OnRoute"] boolValue] == false){
                            stop.etaArray[WEST2_ETA] = @-1;
                        } else {
                        num = round([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"] doubleValue] / 60);
                        stop.etaArray[WEST2_ETA] = [NSNumber numberWithDouble:num];
                        }
                    }

                    vehicleId = [[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"VehicleID"];

                    if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == vehicleId){
                        if ([[[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"OnRoute"] boolValue] == false){
                            stop.etaArray[WEST1_ETA] = @-1;
                        } else {
                            num = round([[[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"SecondsToStop"] doubleValue] / 60);
                            stop.etaArray[WEST1_ETA] = [NSNumber numberWithDouble:num];
                        }
                    }
                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == vehicleId){
                        if ([[[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"OnRoute"] boolValue] == false){
                            stop.etaArray[WEST2_ETA] = @-1;
                        } else {
                            num = round([[[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"SecondsToStop"] doubleValue] / 60);
                            stop.etaArray[WEST2_ETA] = [NSNumber numberWithDouble:num];
                        }
                    }
                    break;

                case EAST_ROUTE:
                    if ([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"OnRoute"] boolValue] == false){
                        stop.etaArray[EAST_ETA] = @-1;
                    } else{
                        num = round([[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"] doubleValue] / 60);
                        stop.etaArray[EAST_ETA] = [NSNumber numberWithDouble:num];
                    }
                    break;
            }
        }

       // dispatch_semaphore_signal(sem);


        if (initialRequest){
            dispatch_async(dispatch_get_main_queue(), ^{
            [mapState initStopMarkers];
            [mapState initShuttleMarkers];
                [self startShuttleUpdaterHandler];
            });
        }
        [self distributeStops];

    }];
//dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
    [getDataTask resume];
//});
    return true;

}

- (BOOL) getShuttles:(BOOL)initialRequest
{
    //NSURL *url = [NSURL URLWithString:@"http://portal.campusops.oregonstate.edu/files/shuttle/GetMapVehiclePoints.txt"];
    NSURL *url = [NSURL URLWithString:@"http://www.osushuttles.com/Services/JSONPRelay.svc/GetMapVehiclePoints"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error == nil){
            
            NSError *jsonParsingError = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
            int count = [jsonArray count];
            NSLog(@"Number of shuttles found in jsonArray: %d", [jsonArray count]);

            bool onlineStates[] = {false, false, false, false};
            
            for(int i = 0; i < count; i++){
                id obj = [jsonArray objectAtIndex:i];
            
                BB_Shuttle *newShuttle = [[BB_Shuttle alloc] init];
                newShuttle.latitude = [[obj objectForKey:@"Latitude"] doubleValue];
                newShuttle.longitude = [[obj objectForKey:@"Longitude"] doubleValue];
                newShuttle.vehicleID = [obj objectForKey:@"VehicleID"];
                newShuttle.routeID =[obj objectForKey:@"RouteID"];
                newShuttle.heading = [obj objectForKey:@"Heading"];
                newShuttle.name = [obj objectForKey:@"Name"];
                newShuttle.groundSpeed = [[obj objectForKey:@"GroundSpeed"] doubleValue];
                newShuttle.isOnline = true;
                
                switch ([[obj objectForKey:@"RouteID"] integerValue]) {
                    case NORTH_ROUTE:
                        [newShuttle setImageName:@"shuttle_green"];
                        [newShuttle setColor:[UIColor colorWithRed:.439 green:.659 blue:0 alpha:1]]; //Green
                        [mapState setShuttle:0 withNewShuttle:newShuttle];
                        onlineStates[0] = true;
                        break;
                    case WEST_ROUTE:
                        [newShuttle setImageName:@"shuttle_orange"];
                        [newShuttle setColor:[UIColor colorWithRed:.878 green:.667 blue:.059 alpha:1]]; //Yellow
                        if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == newShuttle.vehicleID){
                            [mapState setShuttle:1 withNewShuttle:newShuttle];
                            onlineStates[1] = true;
                        }
                        else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == newShuttle.vehicleID){
                            [mapState setShuttle:2 withNewShuttle:newShuttle];
                            onlineStates[2] = true;
                        }
                        else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).isOnline == FALSE){
                            [mapState setShuttle:1 withNewShuttle:newShuttle];
                            onlineStates[1] = true;
                        }
                        else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).isOnline == FALSE){
                            [mapState setShuttle:2 withNewShuttle:newShuttle];
                            onlineStates[2] = true;
                        }
                        break;
                    case EAST_ROUTE:
                        [newShuttle setImageName:@"shuttle_purple"];
                        [newShuttle setColor:[UIColor colorWithRed:.667 green:.4 blue:.804 alpha:1]]; //Purple
                        [mapState setShuttle:3 withNewShuttle:newShuttle];
                        onlineStates[3] = true;
                        break;
                    default:
                        break;
                }

            }

            //Set the online states depending on what was found from json
            for (int i = 0; i < 4; i++) {
                if (!onlineStates[i]){
                    ((BB_Shuttle *)[mapState.shuttles objectAtIndex:i]).isOnline = false;
                }
                else ((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).isOnline = true;
            }

            mapState.shuttleRequestComplete = true;
           // dispatch_semaphore_signal(sem);

                     if (!initialRequest){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self animateHandler];
                });
            }
            [self getEstimates:initialRequest];
        } else { //Error was non-nil
            mapState.shuttleRequestComplete = false;
           // dispatch_semaphore_signal(sem);
        }

    }];

    //NSLog(@"task: %@", getDataTask.taskDescription);
   //dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){

    [getDataTask resume];
  // });
    return true;
}

@end
