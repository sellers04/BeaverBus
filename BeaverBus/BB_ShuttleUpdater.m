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


int const NORTH = 1;
int const WEST = 2;
int const EAST = 3;

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
    //NSURLSession *session;
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

- (BOOL)initialNetworkRequest
{
    mapState.shuttles = [[NSMutableArray alloc] init];
    for (int i = 0; i < 4; i++){
        BB_Shuttle *newShuttle = [[BB_Shuttle alloc] init];
        newShuttle.isOnline = FALSE;
        [mapState.shuttles addObject:newShuttle];
    }

    sem = dispatch_semaphore_create(0);
    NSLog(@"created: sem is %@", sem);
    NSLog(@"Starting requests...");
    
    [self getStops];


    
    [self getShuttles];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    //[BB_MapState get].shuttles =
    //NSLog(@"Done shuttles");

    [self getEstimates];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    for (BB_Stop *stop in mapState.stops){
        NSLog(@"%@",stop.etaArray);
    }


    //Need both stops and shuttles before continuing... //TODO: and estimates
    if (!mapState.stopsRequestComplete || !mapState.shuttleRequestComplete){
        NSLog(@"stops or shuttles complete FALSE");
        return false;
    }

    NSLog(@"stops or shuttles complete TRUE");
    dispatch_async(dispatch_get_main_queue(), ^{
        [mapState initStopMarkers];
        [mapState initShuttleMarkers];
        [self distributeStops];
    });

    NSLog(@"Done with all!");

    [self startShuttleUpdaterHandler];

    return true;
}

- (void)startShuttleUpdaterHandler{
    NSLog(@"startingShuttleUpdater...");
    [timer invalidate];

    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(updateEvent) userInfo:nil repeats:TRUE];
}

- (void)updateEvent{
    NSLog(@"UpdateEvent");
    mapState.shuttleRequestComplete = false;
    sem = dispatch_semaphore_create(0);
    [self getShuttles];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);


    if (mapState.shuttleRequestComplete){
        //Successful update
        NSLog(@"Done waiting");
        [self animateHandler];
    } else {

        //Failed to update!

    }

    [self getEstimates];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    [self distributeStops];
    
    [BB_MapState get].stopsInvalid = true;
    
    //NSLog(@"Done waiting");
    [self animateHandler];

    //Redraw the infowindow by setting the selected marker again
    if ([mapState.mapView.selectedMarker isKindOfClass:[BB_Stop class]]){
        mapState.mapView.selectedMarker = mapState.mapView.selectedMarker;
    }

}



-(void)animateHandler
{



    NSMutableArray *shuttles = [BB_MapState get].shuttles;

    //Rotate >> Wait 0.5 seconds >> Move position
    int64_t delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);

    for (BB_Shuttle *shuttle in shuttles) {
        [shuttle.marker setRotation:([shuttle.heading doubleValue])];
        //[shuttle.marker setPosition:CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude)];


        dispatch_after(popTime, dispatch_get_main_queue(), ^{
            [shuttle.marker setPosition:CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude)];
        });

    }
    double incAmount = .00005;
    //NSLog(@"MAPSTATE shuttle: lat: %f, lon: %f",((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.latitude, ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.longitude);

    //NSLog(@"shuttle1MarkerPos: %f , %f", shuttle1.marker.position.latitude, shuttle1.marker.position.longitude);

    //NSLog(@"POST shuttle1MarkerPos: %f , %f", shuttle1.marker.position.latitude, shuttle1.marker.position.longitude);
    //NSLog(@"POST MAPSTATE shuttle: lat: %f, lon: %f",((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.latitude, ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.longitude);
    //NSLog(@"Dispatch resume");
    //dispatch_resume(dispatchSource);
    //shuttle1.marker.po
    
}



-(NSArray*)getDistance:(BB_Shuttle *)shuttle andIncrementVarible:(int)inc
{
    //NSLog(@"Lat: %f Lon: %f", shuttle.latitude, shuttle.longitude);
    double latDiff = abs(shuttle.marker.position.latitude - shuttle.latitude);
    double lonDiff = abs(shuttle.marker.position.longitude - shuttle.longitude);

    double hypDist = sqrt((latDiff*latDiff)+(lonDiff*lonDiff));

    double numIterations = hypDist/inc;

    //NSLog(@"NumIterations: %f",numIterations);
    double latInc = latDiff/numIterations;
    double lonInc = lonDiff/numIterations;



    //NSLog(@"For shuttleIndex: %d , latInc = %f, lonInc = %f", [[BB_MapState get].shuttles indexOfObject:shuttle], latInc, lonInc);

    NSArray *arr = [NSArray arrayWithObjects:[NSNumber numberWithDouble:latInc], [NSNumber numberWithDouble:lonInc],nil];
    //NSNumber *arr[2] = {[NSNumber numberWithDouble:latInc], [NSNumber numberWithDouble:lonInc]};

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
    NSLog(@"%d, %d, %d, %d", [northEstimates count], [west1Estimates count], [west2Estimates count], [eastEstimates count]);
    [mapState.tableView reloadData];

}


- (BOOL) getStops{
    NSLog(@"getStops()");
    NSURL *url = [NSURL URLWithString:@"http://osushuttles.com/Services/JSONPRelay.svc/GetStops"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";


    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSLog(@"stops getDataTask completion handler");
        if (error == nil){
            NSError *jsonParsingError = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
            //NSLog(@"StopArray : %@", jsonArray);
            
            NSMutableArray *stopsArray = [[NSMutableArray alloc] init];
            int count = [jsonArray count];
            NSMutableArray *seenRouteLocs = [[NSMutableArray alloc] init];

            NSMutableDictionary* stopsDict = [[NSMutableDictionary alloc] init];

            //NSLog(@"jsonArray count: %d", [jsonArray count]);
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

                        [stopsDict setObject:((BB_Stop*)[stopsArray objectAtIndex:[seenRouteLocs indexOfObject:locIter]]) forKey:[obj objectForKey:@"RouteStopID"]];

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

                    [stopsDict setObject:newStop forKey:[obj objectForKey:@"RouteStopID"]];
                }

            }

            mapState.stopsDict = stopsDict;

            mapState.stops = stopsArray;
            //seenRouteLocs = NULL;
            mapState.stopsRequestComplete = true;
            
            dispatch_semaphore_signal(sem);
        }else{
            mapState.stopsRequestComplete = false;
            dispatch_semaphore_signal(sem);
            NSLog(@"signaled stops: sem is %@", sem);
        }
    }];
    [getDataTask resume];
    
    return true;
}



- (BOOL) getEstimates
{
    NSURL *url = [NSURL URLWithString:@"http://www.osushuttles.com/Services/JSONPRelay.svc/GetRouteStopArrivals"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];


        for (id obj in jsonArray){
            //NSLog(@"OBJ name: %@", [obj objectForKey:@"RouteStopID"]);
            NSNumber *stopId = [obj objectForKey:@"RouteStopID"];

            NSArray *jsonVehicleEstimates = [obj objectForKey:@"VehicleEstimates"];

            BB_Stop *stop = [mapState.stopsDict objectForKey:stopId];

            //for (BB_Stop *tempStop in mapState.stops){

                   // stop = tempStop;
                   // break;


            //}

            NSNumber *vehicleId;

            switch ([[obj objectForKey:@"RouteID"] integerValue]){
                case NORTH_ROUTE:
                   // temp = [[[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"] integerValue];

                    stop.etaArray[NORTH_ETA] = [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"];
                    break;

                case WEST_ROUTE:
                    vehicleId = [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"VehicleID"];

                    if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == vehicleId){
                        stop.etaArray[WEST1_ETA] = [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"];
                    }

                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == vehicleId){
                        stop.etaArray[WEST2_ETA] = [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"];
                    }

                    vehicleId = [[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"VehicleID"];

                    if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == vehicleId){
                        stop.etaArray[WEST1_ETA] = [[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"SecondsToStop"];
                    }
                    else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == vehicleId){
                        stop.etaArray[WEST2_ETA] = [[jsonVehicleEstimates objectAtIndex:1] objectForKey:@"SecondsToStop"];
                    }
                    break;

                case EAST_ROUTE:
                    //NSLog(@"EAST seconds to stop: %@", [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"]);
                    stop.etaArray[EAST_ETA] = [[jsonVehicleEstimates objectAtIndex:0] objectForKey:@"SecondsToStop"];
                    break;

            }

        }

        dispatch_semaphore_signal(sem);


        /*
         for every stopID in RouteStopArrivalTimes{
         find stop in myStops that contains stopID
         
         switch (routeID){
         case NorthRoute:
         stop.etaArray[0] = vehicleestimates[0].secondstoStop
         
         
         case EastRoute:
         stop.etaArray[3] = vehicleestimates[0].secondstoStop
         
         
        case WestRoute: //double route
            vehicleID = vehicleestimates[0].vehicleid
            if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == vehicleID){
                stop.etaArray[1] = vehicleestimates[0].secondstostop
            }
            else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == vehicleID){
                stop.etaArray[2] = vehicleestimates[0].secondstostop
            }
            vehicleID = vehicleestimates[1].vehicleid
            if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:1]).vehicleID == vehicleID){
                stop.etaArray[1] = vehicleestimates[1].secondstostop
            }
            else if (((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).vehicleID == vehicleID){
                stop.etaArray[2] = vehicleestimates[1].secondstostop
            }
         }
         
         dispatch_semaphore_signal(sem);
         }*/

    }];
    [getDataTask resume];

    return true;

//---------------
    /*
    int randomMax = 16;
    
    NSMutableArray *stops = mapState.stops;
    for (BB_Stop *stop in stops) {
        {
            for (NSNumber *num in stop.servicedRoutes) {
                NSNumber *r = [NSNumber numberWithInt:(arc4random() % randomMax)];
                switch ([num integerValue]) {
                    case NORTH_ROUTE:
                        stop.etaArray[NORTH_ETA] = r;
                        break;
                        
                    case WEST_ROUTE:
                        stop.etaArray[WEST1_ETA] = r;
                        stop.etaArray[WEST2_ETA] = r;
                        break;
                        
                    case EAST_ROUTE:
                        stop.etaArray[EAST_ETA] = r;
                        break;
                        
                    default:
                        NSLog(@"ERROR DEFAULT");
                }
            }
        }
    }
    
    
    dispatch_semaphore_signal(sem);
    
    
    return true;
     */
}

- (BOOL) getShuttles{
    //NSURL *url = [NSURL URLWithString:@"http://portal.campusops.oregonstate.edu/files/shuttle/GetMapVehiclePoints.txt"];
    NSURL *url = [NSURL URLWithString:@"http://www.osushuttles.com/Services/JSONPRelay.svc/GetMapVehiclePoints"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if (error == nil){
            
            NSError *jsonParsingError = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
            //NSLog(@"ShuttleArray : %@", jsonArray);
            
            //NSMutableArray *shuttlesArray = [[NSMutableArray alloc] init];
            int count = [jsonArray count];
            //BOOL firstWestSeen = false;
            NSLog(@"shuttle jsonArray count: %d", [jsonArray count]);
            
            //TODO: Figure out bool array for setting online states if no shuttle found
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
                newShuttle.isOnline = true;
                
                //NSLog(@"\nOLD LAT: %f \n NEW LAT: %f \n", ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:i]).latitude, newShuttle.latitude);
                
                //NSLog(@"Heading is: %@", newShuttle.heading);
                //NSLog(@"RouteID: %d", [[obj objectForKey:@"RouteID"] integerValue]);
                
            
                
                switch ([[obj objectForKey:@"RouteID"] integerValue]) {
                    case NORTH_ROUTE:
                        newShuttle.imageName = @"shuttle_green";
                        newShuttle.color = [UIColor colorWithRed:.439 green:.659 blue:0 alpha:1]; //Green
                        [mapState setShuttle:0 withNewShuttle:newShuttle];
                        //newShuttle.name = @"North";
                        onlineStates[0] = true;
                        break;
                    case WEST_ROUTE:
                        newShuttle.imageName = @"shuttle_orange";
                        newShuttle.color = [UIColor colorWithRed:.878 green:.667 blue:.059 alpha:1]; //Yellow
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
                        newShuttle.imageName = @"shuttle_purple";
                        newShuttle.color = [UIColor colorWithRed:.667 green:.4 blue:.804 alpha:1]; //Purple
                        [mapState setShuttle:3 withNewShuttle:newShuttle];
                        //newShuttle.name = @"East";
                        onlineStates[3] = true;
                        break;
                    default:
                        break;
                }
                NSLog(@"Shuttlename as set: %@", newShuttle.imageName);
            }
            //NSLog(@"Shuttlename as set: %@", newShuttle.imageName);
            for (int i = 0; i < 4; i++) {
                if (!onlineStates[i]){
                    ((BB_Shuttle *)[mapState.shuttles objectAtIndex:i]).isOnline = false;
                    
                }
                else ((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).isOnline = true;
            }
            
            //  NSLog(@"ShuttlesArray len: %d", [shuttlesArray count]);
            
            mapState.shuttleRequestComplete = true;
            dispatch_semaphore_signal(sem);
            NSLog(@"signaled shuttles: sem is %@", sem);
        }
        else {
            
            mapState.shuttleRequestComplete = false;
            dispatch_semaphore_signal(sem);
            NSLog(@"signaled shuttles: sem is %@", sem);
        }
    }];
    [getDataTask resume];
    
    return true;
}

@end
