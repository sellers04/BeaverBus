//
//  BB_ShuttleUpdater.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_ShuttleUpdater.h"
#import "BB_Stop.h"
#import "BB_Shuttle.h"
#import "BB_MapState.h"


int const NORTH = 1;
int const WEST = 2;
int const EAST = 3;


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

    NSLog(@"Starting requests...");
    [self getStops];
    //NSLog(@"Done stops");
    [self getShuttles];
    //[BB_MapState get].shuttles =
    //NSLog(@"Done shuttles");

    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    NSLog(@"Done with one");
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);

    dispatch_async(dispatch_get_main_queue(), ^{
        [mapState initStopMarkers];
        [mapState initShuttleMarkers];
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
    NSLog(@"Done waiting");
    [self animateHandler];

}



-(void)animateHandler
{
    NSLog(@"Animate handler");
    dispatch_source_t dispatchSource = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));

    dispatch_time_t startTime =  dispatch_time(DISPATCH_TIME_NOW, 0);

    uint64_t intervalTime = (int64_t)10;

    dispatch_source_set_timer(dispatchSource, startTime, intervalTime, 0);

    BB_Shuttle *shuttle1 =[[BB_MapState get].shuttles objectAtIndex:0];
    //NSArray *firstShuttleArr = [self getDistance:shuttle1 andIncrementVarible:10];

    //double precisionCheck = .0001;

    NSMutableArray *shuttles = [BB_MapState get].shuttles;

    dispatch_source_set_event_handler(dispatchSource, ^{
        NSLog(@"DISPAT+CH");
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
    NSLog(@"MAPSTATE shuttle: lat: %f, lon: %f",((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.latitude, ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.longitude);

    NSLog(@"shuttle1MarkerPos: %f , %f", shuttle1.marker.position.latitude, shuttle1.marker.position.longitude);

    NSLog(@"POST shuttle1MarkerPos: %f , %f", shuttle1.marker.position.latitude, shuttle1.marker.position.longitude);
    NSLog(@"POST MAPSTATE shuttle: lat: %f, lon: %f",((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.latitude, ((BB_Shuttle*)[[BB_MapState get].shuttles objectAtIndex:0]).marker.position.longitude);
    NSLog(@"Dispatch resume");
    dispatch_resume(dispatchSource);
    //shuttle1.marker.po
    
}

-(NSArray*)getDistance:(BB_Shuttle *)shuttle andIncrementVarible:(int)inc
{
    NSLog(@"Lat: %f Lon: %f", shuttle.latitude, shuttle.longitude);
    double latDiff = abs(shuttle.marker.position.latitude - shuttle.latitude);
    double lonDiff = abs(shuttle.marker.position.longitude - shuttle.longitude);

    double hypDist = sqrt((latDiff*latDiff)+(lonDiff*lonDiff));

    double numIterations = hypDist/inc;

    NSLog(@"NumIterations: %f",numIterations);
    double latInc = latDiff/numIterations;
    double lonInc = lonDiff/numIterations;



    NSLog(@"For shuttleIndex: %d , latInc = %f, lonInc = %f", [[BB_MapState get].shuttles indexOfObject:shuttle], latInc, lonInc);

    NSArray *arr = [NSArray arrayWithObjects:[NSNumber numberWithDouble:latInc], [NSNumber numberWithDouble:lonInc],nil];
    //NSNumber *arr[2] = {[NSNumber numberWithDouble:latInc], [NSNumber numberWithDouble:lonInc]};

    return arr;
}


- (BOOL) getStops{
    NSURL *url = [NSURL URLWithString:@"http://osushuttles.com/Services/JSONPRelay.svc/GetStops"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"GET";

    NSURLSessionDataTask *getDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

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

            id mapPoints = [obj objectForKey:@"MapPoints"];
            int mapPointsCount = [mapPoints count];
            //NSLog(@"mappointsCount: %d", mapPointsCount);

            for(int j = 0; j < mapPointsCount; j++){
                id point = [mapPoints objectAtIndex:j];
                double lat = [[point objectForKey:@"Latitude"] doubleValue];
                double lon = [[point objectForKey:@"Longitude"] doubleValue];
                CLLocation *loc = [[CLLocation alloc] initWithLatitude:lat longitude:lon];
                if(![routePoints containsObject:(id)loc]){
                    [routePoints addObject:(id)loc];
                }
                mapState.mapPoints = routePoints;
                //GMSMarker *newMarker = [GMSMarker markerWithPosition:loc]
            }




            newStop.name = [obj objectForKey:@"Description"];
            //NSLog(@"newStop name: %@", newStop.name);
            [stopsArray addObject:newStop];
            //NSLog(@"stopsArray : %@", stopsArray);
        }
        NSLog(@"Stops stuff");
        //NSLog(@"StopsArray count: %d", [stopsArray count]);
        mapState.stops = stopsArray;
        //NSLog(@"Finished first request mapstateStops count: %d", [[BB_MapState get].stops count]);

        dispatch_semaphore_signal(sem);

    }];
    [getDataTask resume];
    
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

        for (int i = 0; i < 4; i++) {
            if (!onlineStates[i]){
                ((BB_Shuttle *)[mapState.shuttles objectAtIndex:i]).isOnline = false;

            }
            else ((BB_Shuttle *)[mapState.shuttles objectAtIndex:2]).isOnline = true;
        }

      //  NSLog(@"ShuttlesArray len: %d", [shuttlesArray count]);

         NSLog(@"Finished second request");


        dispatch_semaphore_signal(sem);

    }];
    [getDataTask resume];
    
    return true;
}

@end
