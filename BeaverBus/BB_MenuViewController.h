//
//  BB_MenuViewController.h
//  BeaverBus
//
//  Created by norredm on 1/12/15.
//  Copyright (c) 2015 Oregon State University. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include "BB_AppDelegate.h"

@class BB_ViewController;

@interface BB_MenuViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *stopsVisibility;

@property (strong, nonatomic) IBOutlet UIView *view;


- (void)showInView:(UIView *)aView withImage:(UIImage *)image withMessage:(NSString *)message animated:(BOOL)animated withFrame:(CGRect)box controller:(BB_ViewController *)mapViewController;
- (void)removeAnimate;
- (IBAction)toggleStopsVisibility:(id)sender;
- (IBAction)showBusInformation:(id)sender;

@end
