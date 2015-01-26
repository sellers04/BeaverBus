//
//  BB_Favorite.m
//  BeaverBus
//
//  Created by Nick on 1/12/15.
//  Copyright (c) 2015 Oregon State University. All rights reserved.
//

#import "BB_Favorite.h"
#import "BB_MapState.h"


@implementation BB_Favorite



int const NORTH = 0;
int const WEST1 = 1;
int const WEST2 = 2;
int const EAST = 3;




+(void)handleFavoriteTap:(UITapGestureRecognizer *)sender
{
    //Find favorite obj of tapped view. Send stop obj to MapState to have map moved.
    for (int i = 0; i < [[[BB_MapState get] favorites] count]; i++) {
        BB_Favorite *fav = [[[BB_MapState get] favorites] objectAtIndex:i];
        if([sender isEqual:[fav favoriteBar]]){
            [[BB_MapState get] onFavoriteTap:[fav favoriteStop]];
        }
    }
}

+(BB_Favorite*)initNewFavoriteWithStop:(BB_Stop*)stop andFrame:(CGRect)frame
{
    
    NSMutableArray *favorites = [[BB_MapState get] favorites];
    
    BB_Favorite *newFavorite = [[BB_Favorite alloc] init];
    
    newFavorite.favoriteStop = stop;
    newFavorite.favoriteStop.isFavorite = TRUE;
    
    newFavorite.defaultFrame = frame;
    UIControl *favoriteBar = [[UIControl alloc] initWithFrame:frame];
    
    UILabel *favoriteName = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 30)];
    UIView *favoriteEta = [[UILabel alloc] initWithFrame:CGRectMake(120, 0, 100, 30)];
    favoriteName.text = stop.name;
    newFavorite.favoriteName = favoriteName;
    newFavorite.favoriteEtaContainer = favoriteEta;
    
    [favoriteBar setBackgroundColor:[UIColor whiteColor]];
    [favoriteBar setAlpha:0];
    favoriteBar.layer.cornerRadius = 5;
    favoriteBar.layer.masksToBounds = YES;
    favoriteBar.layer.borderWidth = 1;
    favoriteBar.layer.borderColor = [UIColor blackColor].CGColor;
    favoriteBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [favoriteBar addSubview:favoriteName];
    [favoriteBar addSubview:favoriteEta];
    
    
    [favoriteBar setUserInteractionEnabled:true];
    [favoriteBar addTarget:self action:@selector(handleFavoriteTap:) forControlEvents:UIControlEventTouchUpInside];
    
    //[favoriteName setExclusiveTouch:true];
     //[favoriteName setUserInteractionEnabled:true];
    /*
    SEL selector = @selector(handleFavoriteTap:);
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:[BB_Favorite class] action:@selector(handleFavoriteTap:)];
    singleTap.numberOfTapsRequired = 1;
    
    [favoriteBar addGestureRecognizer:singleTap];
    [favoriteBar setExclusiveTouch:YES];
    [favoriteBar setUserInteractionEnabled:YES];
    */
    
    
    
    newFavorite.favoriteBar = favoriteBar;
    
    
    newFavorite.etaLabels = [[NSMutableArray alloc] init];
    
    int x = 0;
    for (NSNumber *eta in stop.etaArray){
        UILabel *etaLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 30, 30)];
        [newFavorite.etaLabels addObject:etaLabel];
        etaLabel.text = [eta stringValue];
        x += 35;
        [favoriteEta addSubview:etaLabel];
    }


    for (BB_Favorite *fav in favorites){
        [UIView animateWithDuration:0.25 animations:^{
            fav.favoriteBar.frame = CGRectMake(frame.origin.x, fav.favoriteBar.frame.origin.y - favoriteBar.frame.size.height, frame.size.width, frame.size.height);

        }];
    }
    
    
    [favorites addObject:newFavorite];
    
    NSMutableString *savedFavNames = [NSMutableString stringWithString:@""];
    
    for (int i = 0; i < [favorites count]; i++){
        if (i!=0) [savedFavNames appendString:@"_"];
        [savedFavNames appendString:((BB_Favorite *)[favorites objectAtIndex:i]).favoriteStop.name];
        NSLog(@"savedfavs: %@", savedFavNames);
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setObject:savedFavNames forKey:@"Favorites"];
    
    [userDefaults synchronize];
    
    NSLog(@"retrieving saved: %@",[[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"]);
    
    return newFavorite;
}

+(void)restoreFavorites
{
    //NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSLog(@"restoreFavs: %@",[[BB_MapState get] mapView]);
    
    
    CGRect frame = CGRectMake(10, [[BB_MapState get] mapView].frame.size.height-50, [[BB_MapState get] mapView].frame.size.width-20, 30);
    //CGRect frame = CGRectMake(10, [[BB_ViewController get] view].frame.size.height-50, [[BB_ViewController get] view].frame.size.width-20, 30);
    
    
    NSArray *splitItems = [[[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"] componentsSeparatedByString:@"_"];
    
    NSLog(@"%@ ---> splitItems", [[NSUserDefaults standardUserDefaults] objectForKey:@"Favorites"]);
    
    
    
    for (NSString *favName in splitItems){
        NSLog(@"Finding %@ in splitItems...", favName);
        for (BB_Stop *stop in [[BB_MapState get] stops]){
            NSLog(@"%@ vs %@", stop.name, favName);
            if ([favName isEqualToString:stop.name]){
                
                BB_Favorite *newFavorite = [self initNewFavoriteWithStop:stop andFrame:frame];
                NSLog(@"Found match! %@", [newFavorite favoriteBar]);
              //  [[[BB_ViewController get] getMainView] addSubview:[newFavorite favoriteBar]] ;
                [[[[BB_MapState get] mainViewController] view] addSubview:[newFavorite favoriteBar]];
             //   NSLog(@"main subviews: %@",)
            }
        }
    }
    

}



+(void)animateFavoritesAfterRemove
{
    NSUInteger count = [[[BB_MapState get] favorites] count];
    for (BB_Favorite *fav in [BB_MapState get].favorites){
        count--;
        
        [UIView animateWithDuration:0.25 animations:^{
            fav.favoriteBar.frame = CGRectMake(fav.defaultFrame.origin.x, fav.defaultFrame.origin.y-(count*fav.defaultFrame.size.height), fav.defaultFrame.size.width, fav.defaultFrame.size.height);
                                     }];
        
    }
}


-(void)updateFavorite
{
    
    NSLog(@"NAME: %@",[self etaLabels]);
    
    dispatch_async(dispatch_get_main_queue(), ^{
    
        for (int i = 0; i < [[_favoriteStop etaArray] count]; i++) {
            NSNumber *eta = [[_favoriteStop etaArray] objectAtIndex:i];
            NSLog(@"Update favorite: %d with %@", i, eta);
            switch (i) {
                case NORTH:
                    ((UILabel*)_etaLabels[NORTH]).text = [eta stringValue];
                    break;
                case WEST1:
                    ((UILabel*)_etaLabels[WEST1]).text = [eta stringValue];
                    break;
                case WEST2:
                    ((UILabel*)_etaLabels[WEST2]).text = [eta stringValue];
                    break;
                case EAST:
                    ((UILabel*)_etaLabels[EAST]).text = [eta stringValue];
                    break;
                default:
                    break;
            }
        }
      //  [_favoriteBar setNeedsDisplay];
    });
    
}




@end
