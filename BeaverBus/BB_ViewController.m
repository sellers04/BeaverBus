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
#import <GoogleMaps/GoogleMaps.h>
#import <UIKit/UIKit.h>

static BB_ViewController *mainViewController = NULL;

@interface BB_ViewController ()

@property (strong, nonatomic) IBOutlet UIView *mainView;
@property (strong, nonatomic) PopUpViewController *popViewController;


@end

#define LABEL_TAG 100

@implementation BB_ViewController

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


- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationItem.leftBarButtonItem = [self OSULogoBar];

    _optionsMenuIsOpen = false;
    self.navigationItem.rightBarButtonItem = [self optionsBar];

    [self.navigationController.navigationBar setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIFont fontWithName:@"Gudea-Bold" size:22],
       NSFontAttributeName,
      nil]];


    self.navigationItem.title = @"Beaver Bus Tracker";


    changedStopEstimatePairs = [[NSMutableArray alloc] init];



    self.view = [BB_MapState get].mapView;

    if (![BB_MapState get].didInitialRequest){
        //Initial request failed, show try again dialog
     //   [networkFailAlert show];
    }
    // Else, continue

	// Do any additional setup after loading the view, typically from a nib.


    //TODO: map label subview
    //UIView *mapLabel = [[[NSBundle mainBundle] loadNibNamed:@"MapLabelView" owner:self options:nil] objectAtIndex:0];
/*


    float percentage = .7f;
    int xpos = self.view.frame.size.width * ((1-percentage) / 2);
int ypos = self.view.frame.size.height * ((1-percentage) / 2);
    int width = self.view.frame.size.width * (1-percentage);
    int height = self.view.frame.size.height * (1-percentage);

   // mapLabel.frame = CGRectMake(xpos, ypos, width, height);

    UIView *mapLabel = [[UIView alloc] initWithFrame:CGRectMake(xpos, ypos, width, height)];
    [mapLabel setBackgroundColor:[UIColor whiteColor]];

    [self.view addSubview:mapLabel];
*/
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
    self.navigationItem.rightBarButtonItem = item;

    return item;
}

- (void)openOptionsMenu
{
    if (!_optionsMenuIsOpen){
                _popViewController = [[PopUpViewController alloc] initWithNibName:@"PopUpViewController" bundle:nil];
        [_popViewController setTitle:@"Options"];
        [_popViewController showInView:self.view withImage:nil withMessage:@"" animated:YES controller:self];

    } else {
      
        [_popViewController removeAnimate];
    }
}

-(void)viewDidAppear:(BOOL)animated
{

    
}

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
