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
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    //NSLog(@"Done stops");
    
    [self getShuttles];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    //[BB_MapState get].shuttles =
    //NSLog(@"Done shuttles");

    [self getEstimates];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    NSLog(@"waited: sem is %@", sem);

    NSLog(@"Done with one");
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    NSLog(@"waited: sem is %@", sem);

    //Need both stops and shuttles before continuing...
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
    sem = dispatch_semaphore_create(0);
    [self getShuttles];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    [self getEstimates];
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    [self distributeStops];
    
    //NSLog(@"Done waiting");
    [self animateHandler];
}



-(void)animateHandler
{
    //NSLog(@"Animate handler");
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    dispatch_time_t startTime =  dispatch_time(DISPATCH_TIME_NOW, 0);

    uint64_t intervalTime = (int64_t)10;

    dispatch_source_set_timer(dispatchSource, startTime, intervalTime, 0);

    BB_Shuttle *shuttle1 =[[BB_MapState get].shuttles objectAtIndex:0];
    //NSArray *firstShuttleArr = [self getDistance:shuttle1 andIncrementVarible:10];

    //double precisionCheck = .0001;

    NSMutableArray *shuttles = [BB_MapState get].shuttles;

    dispatch_source_set_event_handler(dispatchSource, ^{
        //NSLog(@"DISPAT+CH");
        /*NSLog(@"dispatch iteration");
        if(!((shuttle1.latitude - shuttle1.marker.position.latitude) < precisionCheck) && !((shuttle1.longitude - shuttle1.marker.position.longitude) < precisionCheck)){
            double newLat = shuttle1.marker.position.latitude + [[firstShuttleArr objectAtIndex:0] doubleValue];
            double newLon = shuttle1.marker.position.longitude + [[firstShuttleArr objectAtIndex:1] doubleValue];
            NSLog(@"New iteration lat: %f , lon: %f", newLat, newLon);
            [shuttle1.marker setPosition:CLLocationCoordinate2DMake(newLat, newLon)];
        }else{
            NSLog(@"Dispatch suspended!");
            dispatch_suspend(dispatchSource);
        }*/




    });
    for (BB_Shuttle *shuttle in shuttles) {
        [shuttle.marker setPosition:CLLocationCoordinate2DMake(shuttle.latitude, shuttle.longitude)];
        [shuttle.marker setRotation:([shuttle.heading doubleValue])];
    }
    double incAmount = .00005;
    //NSLog(@"MAPSTATE shuttle: lat: %f, lon: %f",((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.latitude, ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.longitude);

    //NSLog(@"shuttle1MarkerPos: %f , %f", shuttle1.marker.position.latitude, shuttle1.marker.position.longitude);

    //NSLog(@"POST shuttle1MarkerPos: %f , %f", shuttle1.marker.position.latitude, shuttle1.marker.position.longitude);
    //NSLog(@"POST MAPSTATE shuttle: lat: %f, lon: %f",((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.latitude, ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.longitude);
    //NSLog(@"Dispatch resume");
    dispatch_resume(dispatchSource);
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
                    newPair.eta = stop.etaArray[WEST2_ETA];
                    newPair.marker = stop.marker;
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
    //NSLog(@"%d, %d, %d, %d :: %d", [northEstimatesDict count], [west1EstimatesDict count], [west2EstimatesDict count], [eastEstimatesDict count], count);
    [mapState.tableView reloadData];

}


- (BOOL) getStops{
    NSURL *url = [NSURL URLWithString:@"http://osushuttles.com/Services/JSONPRelay.svc/GetStops"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";


    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

<<<<<<< HEAD
        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        //NSLog(@"StopArray : %@", jsonArray);
        
        NSMutableArray *stopsArray = [[NSMutableArray alloc] init];
        int count = [jsonArray count];
        NSMutableArray *seenRouteLocs = [[NSMutableArray alloc] init];
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
            }

        }
        mapState.stops = stopsArray;
        //seenRouteLocs = NULL;



        
        
        for (BB_Stop *stop in stopsArray) {
            //NSLog(@"Stop: %@. Coords: %f , %f . With servicedRoutes: %@",stop.name, stop.latitude, stop.longitude, stop.servicedRoutes);
            //NSLog(@"%@", stop.servicedRoutes);
        }
        
        //NSLog(@"Finished first request mapstateStops count: %d", [[BB_MapState get].stops count]);
        if (error == nil){

            NSError *jsonParsingError = nil;
            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
            //NSLog(@"StopArray : %@", jsonArray);
            
            NSMutableArray *stopsArray = [[NSMutableArray alloc] init];
            int count = [jsonArray count];
            NSMutableArray *routePoints = [[NSMutableArray alloc] init];
            //NSLog(@"jsonArray count: %d", [jsonArray count]);
            for(int i = 0; i < count; i++){
                id obj = [jsonArray objectAtIndex:i];
                
                BB_Stop *newStop = [[BB_Stop alloc] init];
                newStop.latitude = [[obj objectForKey:@"Latitude"] doubleValue];
                newStop.longitude = [[obj objectForKey:@"Longitude"] doubleValue];



                newStop.name = [obj objectForKey:@"Description"];
                newStop.etaArray = [NSMutableArray arrayWithObjects:@-1, @-1, @-1, @-1, nil];
                //NSLog(@"newStop name: %@", newStop.name);
                [stopsArray addObject:newStop];
                //NSLog(@"stopsArray : %@", stopsArray);
            }
            NSLog(@"Stops stuff");
            //NSLog(@"StopsArray count: %d", [stopsArray count]);
            mapState.stops = stopsArray;
            //NSLog(@"Finished first request mapstateStops count: %d", [[BB_MapState get].stops count]);
            mapState.stopsRequestComplete = true;

            dispatch_semaphore_signal(sem);
            NSLog(@"signaled stops: sem is %@", sem);
        }
        else{
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
    NSURL *url = [NSURL URLWithString:@""];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        //http stuff
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
         }*/
    }];
    //[getDataTask resume];
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
}

- (BOOL) getShuttles{
    NSURL *url = [NSURL URLWithString:@"http://portal.campusops.oregonstate.edu/files/shuttle/GetMapVehiclePoints.txt"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        NSError *jsonParsingError = nil;
        NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonParsingError];
        //NSLog(@"ShuttleArray : %@", jsonArray);
        
        //NSMutableArray *shuttlesArray = [[NSMutableArray alloc] init];
        int count = [jsonArray count];
        //BOOL firstWestSeen = false;
        //NSLog(@"shuttle jsonArray count: %d", [jsonArray count]);

        //TODO: Figure out bool array for setting online states if no shuttle found
        bool onlineStates[] = {false, false, false, false};

        for(int i = 0; i < count; i++){
            id obj = [jsonArray objectAtIndex:i];



            BB_Shuttle *newShuttle = [[BB_Shuttle alloc] init];
            newShuttle.latitude = [[obj objectForKey:@"Latitude"] doubleValue];
            newShuttle.longitude = [[obj objectForKey:@"Longitude"] doubleValue];
            newShuttle.vehicleID = [obj objectForKey:@"VehicleId"];
            newShuttle.routeID =[obj objectForKey:@"RouteID"];
            newShuttle.heading = [obj objectForKey:@"Heading"];
            newShuttle.name = [obj objectForKey:@"Name"];
            newShuttle.isOnline = true;

            //NSLog(@"\nOLD LAT: %f \n NEW LAT: %f \n", ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:i]).latitude, newShuttle.latitude);

            //NSLog(@"Heading is: %@", newShuttle.heading);
            //NSLog(@"RouteID: %d", [[obj objectForKey:@"RouteID"] integerValue]);
            switch ([[obj objectForKey:@"RouteID"] integerValue]) {
                case NORTH:
                    newShuttle.imageName = @"shuttle_green";
                    [mapState setShuttle:0 withNewShuttle:newShuttle];
                    //newShuttle.name = @"North";
                    onlineStates[0] = true;
                    break;
                case WEST:
                    newShuttle.imageName = @"shuttle_purple";
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
                newShuttle.vehicleID = [obj objectForKey:@"VehicleId"];
                newShuttle.routeID =[obj objectForKey:@"RouteID"];
                newShuttle.heading = [obj objectForKey:@"Heading"];
                newShuttle.name = [obj objectForKey:@"Name"];
                newShuttle.isOnline = true;

                //NSLog(@"\nOLD LAT: %f \n NEW LAT: %f \n", ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:i]).latitude, newShuttle.latitude);

                NSLog(@"Heading is: %@", newShuttle.heading);
                switch ([[obj objectForKey:@"RouteID"] integerValue]) {
                    case NORTH:
                        newShuttle.imageName = @"shuttle_green";
                        [mapState setShuttle:0 withNewShuttle:newShuttle];
                        //newShuttle.name = @"North";
                        onlineStates[0] = true;
                        break;
                    case WEST:
                        newShuttle.imageName = @"shuttle_purple";
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

                        /*if(!firstWestSeen) newShuttle.name = @"West 1";
                        else newShuttle.name = @"West 2";*/
                        break;
                    case EAST:
                        newShuttle.imageName = @"shuttle_orange";
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
        }


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
