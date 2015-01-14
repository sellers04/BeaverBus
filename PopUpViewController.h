//
//  PopUpViewController.h
//  NMPopUpView
//
//  Created by Nikos Maounis on 9/12/13.
//  Copyright (c) 2013 Nikos Maounis. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "BB_AppDelegate.h"
#import "BB_ViewController.h"

@interface PopUpViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *popUpView;
@property (weak, nonatomic) IBOutlet UIButton *stopsVisibilityButton;


- (void)removeAnimate;
- (void)showInView:(UIView *)aView withImage:(UIImage *)image withMessage:(NSString *)message animated:(BOOL)animated;


@end
