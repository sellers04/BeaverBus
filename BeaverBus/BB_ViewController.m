//
//  BB_ViewController.m
//  BeaverBus
//
//  Created by Nick on 9/16/14.
//  Copyright (c) 2014 Oregon State University. All rights reserved.
//

#import "BB_ViewController.h"
#import "BB_StopEstimatePair.h"
#import "BB_MapState.h"
#import "PopUpViewController.h"
#import "BB_MapLabelView.h"
#import "BB_Stop.h"
#import "MBProgressHUD.h"
#import <GoogleMaps/GoogleMaps.h>
#import "BB_MenuViewController.h"
#import <UIKit/UIKit.h>

static BB_ViewController *mainViewController = NULL;

@interface BB_ViewController () <UIGestureRecognizerDelegate>


@property (strong, nonatomic) PopUpViewController *popViewController;

@end

#define LABEL_TAG 100

@implementation BB_ViewController

@synthesize optionsMenuIsOpen = _optionsMenuIsOpen;

UIView *updateErrorView;
NSMutableArray *changedStopEstimatePairs;

+ (BB_ViewController *)get
{
    @synchronized(mainViewController)
    {
        if (!mainViewController || mainViewController == NULL){
            mainViewController = [[BB_ViewController alloc] init];
        }
        return mainViewController;
    }
}

-(UIView *)getMainView
{
    return [BB_MapState get].mapView;
}
- (void)viewDidLoad
{
    [super viewDidLoad];

    [BB_MapState get].mainViewController = self;

    
    _menuViewController = [[BB_MenuViewController alloc] initWithNibName:@"BB_MenuViewController" bundle:nil];

    self.navigationItem.leftBarButtonItem = [self OSULogoBar];

    [self setOptionsMenuIsOpen:false];
    //self.navigationItem.rightBarButtonItem = [self optionsBar];

    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"Gudea-Bold" size:22],
       NSFontAttributeName,
      nil]];


    self.navigationItem.rightBarButtonItems = @[[self optionsBar], [self favoritesButton]];
    self.navigationItem.title = @"Beaver Bus Tracker";


    changedStopEstimatePairs = [[NSMutableArray alloc] init];
    
    self.view = [BB_MapState get].mapView;

    _addFavoriteButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_addFavoriteButton addTarget:self action:@selector(addFavorite) forControlEvents:UIControlEventTouchUpInside];
    
    _addFavoriteButton.frame = CGRectMake(0, 0, 80, 40.0);
    _addFavoriteButton.backgroundColor = [UIColor whiteColor];
    //addFavoriteButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [_addFavoriteButton setHidden:YES];
    [self.view addSubview:_addFavoriteButton];

    if (![BB_MapState get].didInitialRequest){
        //Initial request failed, show try again dialog
     //   [networkFailAlert show];
    }
    // Else, continue

	// Do any additional setup after loading the view, typically from a nib.


    //TODO: map label subview
    //UIView *mapLabel = [[[NSBundle mainBundle] loadNibNamed:@"MapLabelView" owner:self options:nil] objectAtIndex:0];



    

}
-(UIBarButtonItem *)OSULogoBar
{
    UIImage *image = [UIImage imageNamed:@"osu_icon.png"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setImage:image forState:UIControlStateNormal];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];

    return item;
}

-(UIBarButtonItem *)optionsBar
{
    UIImage *image = [UIImage imageNamed:@"settingsGear.png"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openOptionsMenu) forControlEvents:UIControlEventTouchUpInside];
    [button setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];

    return item;
}

-(UIBarButtonItem *)favoritesButton
{
    UIImage *image = [UIImage imageNamed:@"settingsGear.png"];
    CGRect buttonFrame = CGRectMake(0, 0, image.size.width, image.size.height);
    UIButton *button = [[UIButton alloc] initWithFrame:buttonFrame];
    [button setBackgroundImage:image forState:UIControlStateNormal];
    [button addTarget:self action:@selector(openOptionsMenu) forControlEvents:UIControlEventTouchUpInside];
    [button setShowsTouchWhenHighlighted:YES];
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return item;
}

- (void)openOptionsMenu
{
    NSLog(@"OptionsMenuIsOpen: %hhd", _optionsMenuIsOpen);
    if (!_optionsMenuIsOpen){
                //_popViewController = [[PopUpViewController alloc] initWithNibName:@"PopUpViewController" bundle:nil];
        CGRect menuFrame = CGRectMake(self.view.frame.size.width-100, 0, 100, 150);
        NSLog(@"Here is rect: %@", NSStringFromCGRect(menuFrame));
        [_menuViewController showInView:self.view withImage:nil withMessage:@"" animated:YES withFrame:menuFrame controller:self];
        _optionsMenuIsOpen = true;
//        [_popViewController setTitle:@"Options"];
//        [_popViewController showInView:self.view withImage:nil withMessage:@"" animated:YES controller:self];
    } else {
        //[_popViewController removeAnimate];
        [_menuViewController removeAnimate];
        _optionsMenuIsOpen = false;
    }
}

-(void)setOptionsMenuIsOpen:(BOOL)optionsMenuIsOpen
{
    _optionsMenuIsOpen = optionsMenuIsOpen;
}

-(void)viewDidAppear:(BOOL)animated
{
    float percentage = .7f;

    int width = self.view.frame.size.width * (percentage);
    NSLog(@"width is: %d", width);
    //int height = self.view.frame.size.height * (1-percentage);

    // mapLabel.frame = CGRectMake(xpos, ypos, width, height);
    NSString *mapLabelText = @"OSU";

    _mapLabel = [[UILabel alloc] init];
    [_mapLabel setText:mapLabelText];
    /*float widthIs = [_mapLabel.text boundingRectWithSize:CGSizeMake(self.view.frame.size.width * percentage, self.view.frame.size.height) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:_mapLabel.font} context:nil].size.width;
    NSLog(@"float: %F", widthIs);*/

    //[_mapLabel setFrame:CGRectMake(0, 0, widthIs, 25)];
    [_mapLabel setFrame:CGRectMake(0, 0, 180, 25)];
    [_mapLabel setCenter:CGPointMake(self.view.frame.size.width / 2, 25)];

    [_mapLabel setTextAlignment:NSTextAlignmentCenter];
    [_mapLabel setBackgroundColor:[UIColor whiteColor]];
    _mapLabel.layer.cornerRadius = 5;
    _mapLabel.layer.masksToBounds = YES;
    _mapLabel.layer.borderWidth = 1;
    _mapLabel.layer.borderColor = [UIColor blackColor].CGColor;
    [_mapLabel setAlpha:0.8];
    [_mapLabel setHidden:YES];
    [self.view addSubview:_mapLabel];



    
}

- (void)setFavoriteButton
{



    if (((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).isFavorite){
        [_addFavoriteButton setTitle:@"Remove Favorite" forState:UIControlStateNormal];
        [_addFavoriteButton removeTarget:self action:@selector(addFavorite) forControlEvents:UIControlEventTouchUpInside];
        [_addFavoriteButton addTarget:self action:@selector(removeFavorite) forControlEvents:UIControlEventTouchUpInside];
    }
    else{
        [_addFavoriteButton setTitle:@"Add Favorite" forState:UIControlStateNormal];
        [_addFavoriteButton removeTarget:self action:@selector(removeFavorite) forControlEvents:UIControlEventTouchUpInside];
        [_addFavoriteButton addTarget:self action:@selector(addFavorite) forControlEvents:UIControlEventTouchUpInside];
    }


}


- (void)removeFavorite
{
    NSLog(@"Removed favorite");

    ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).isFavorite = FALSE;

    [self setFavoriteButton];

}

- (void)refreshFavorite{}


- (void)addFavorite
{


    if ([[BB_MapState get].favorites count] > 2){
        //max favorites reached
        MBProgressHUD *h = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        h.mode = MBProgressHUDModeText;
        h.labelText = @"Can't add any more favorites";
        h.labelFont = [UIFont boldSystemFontOfSize:12];

        [h hide:YES afterDelay:1.75];
    }

    else {

        BB_Favorite *newFavorite = [[BB_Favorite alloc] init];
        newFavorite.favoriteStop = ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData);

        newFavorite.favoriteStop.isFavorite = TRUE;
        //((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).isFavorite = TRUE;

        NSLog(@"Add Favorite");

        [self setFavoriteButton];





        UIView *favoriteBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 35, self.view.frame.size.width*0.8, 25)];
        //UIView *favoriteBar = [[UIView alloc] initWithFrame:CGRectMake(60, 60, 300, 30)];
        UILabel *favoriteName = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 30)];
        UIView *favoriteEta = [[UILabel alloc] initWithFrame:CGRectMake(120, 0, 100, 30)];
        [favoriteEta setTag:1];//For accessing later to update ETAs

        favoriteName.text = ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).name;

        [favoriteBar setBackgroundColor:[UIColor whiteColor]];
        [favoriteBar setAlpha:0];
        favoriteBar.layer.cornerRadius = 5;
        favoriteBar.layer.masksToBounds = YES;
        favoriteBar.layer.borderWidth = 1;
        favoriteBar.layer.borderColor = [UIColor blackColor].CGColor;
        favoriteBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;

        [favoriteBar addSubview:favoriteName];
        [favoriteBar addSubview:favoriteEta];




        newFavorite.favoriteBar = favoriteBar;


        int x = 0;
        for (NSNumber *eta in ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).etaArray){
            UILabel *etaLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 30, 30)];
            etaLabel.text = [eta stringValue];
            x += 35;
            [favoriteEta addSubview:etaLabel];
        }



        for (BB_Favorite *fav in [BB_MapState get].favorites){
            [UIView animateWithDuration:0.25 animations:^{
                fav.favoriteBar.frame = CGRectMake(0, fav.favoriteBar.frame.origin.y - favoriteBar.frame.size.height, self.view.frame.size.width*0.8, 30);
            }];
        }

        [[BB_MapState get].favorites addObject:newFavorite];

        [self.view addSubview:newFavorite.favoriteBar];
     //   [self.view addSubview:favoriteBar];


        [UIView animateWithDuration:0.4 animations:^{
            newFavorite.favoriteBar.alpha = 0.75;
        }];
        
    }



}


     /*
    else {
    NSLog(@"Add Favorite");
    UIView *favoriteBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 35, self.view.frame.size.width*0.8, 25)];
    //UIView *favoriteBar = [[UIView alloc] initWithFrame:CGRectMake(60, 60, 300, 30)];
    UILabel *favoriteName = [[UILabel alloc] initWithFrame:CGRectMake(10, 0, 100, 30)];
    UIView *favoriteEta = [[UILabel alloc] initWithFrame:CGRectMake(120, 0, 100, 30)];

    favoriteName.text = ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).name;

    [favoriteBar setBackgroundColor:[UIColor whiteColor]];
    [favoriteBar setAlpha:0];
    favoriteBar.layer.cornerRadius = 5;
    favoriteBar.layer.masksToBounds = YES;
    favoriteBar.layer.borderWidth = 1;
    favoriteBar.layer.borderColor = [UIColor blackColor].CGColor;
    favoriteBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;

    [favoriteBar addSubview:favoriteName];
    [favoriteBar addSubview:favoriteEta];

    int x = 0;
    for (NSNumber *eta in ((BB_Stop*)[BB_MapState get].mapView.selectedMarker.userData).etaArray){
        UILabel *etaLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, 0, 30, 30)];
        etaLabel.text = [eta stringValue];
        x += 35;
        [favoriteEta addSubview:etaLabel];
    }


    for (UIView *row in _favoriteRows){
        [UIView animateWithDuration:0.25 animations:^{
            row.frame = CGRectMake(0, row.frame.origin.y - favoriteBar.frame.size.height, self.view.frame.size.width*0.8, 30);
        }];
    }


    [_favoriteRows addObject:favoriteBar];

    [self.view addSubview:favoriteBar];


    [UIView animateWithDuration:0.4 animations:^{
        favoriteBar.alpha = 0.75;
            }];

    }
     
     */


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [[BB_ShuttleUpdater get] initialNetworkRequest];
        //Repeat the initial network request
    /*
        if (![[BB_ShuttleUpdater get] initialNetworkRequest]) {
            UIAlertView *networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Unable to request data" message:@"Please check your device's connection." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];
            [networkFailAlert show];
        }
     */
}

- (void)slideUpdateErrorView
{
    //Do not use this code whatsoever
   // UIAlertView *networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Connection could not be established" message:@"Please check your device's connection." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];
   // [networkFailAlert show];

}


- (void)showNetworkErrorAlert
{

    NSLog(@"show the update error view");
    UIAlertView *networkFailAlert =  [[UIAlertView alloc] initWithTitle:@"Unable to request data" message:@"Please check your device's connection." delegate:self cancelButtonTitle:nil otherButtonTitles:@"Try again", nil];
    [networkFailAlert show];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
