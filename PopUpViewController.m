//
//  PopUpViewController.m
//  NMPopUpView
//
//  Created by Nikos Maounis on 9/12/13.
//  Copyright (c) 2013 Nikos Maounis. All rights reserved.
//

#import "PopUpViewController.h"

@interface PopUpViewController ()

@property (strong, nonatomic) BB_ViewController *mapViewController;

@end

static BB_MapState *mapState;

@implementation PopUpViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    self.view.backgroundColor=[[UIColor blackColor] colorWithAlphaComponent:.6];
    self.popUpView.layer.cornerRadius = 5;
    self.popUpView.layer.shadowOpacity = 0.8;
    self.popUpView.layer.shadowOffset = CGSizeMake(0.0f, 0.0f);

    mapState = [BB_MapState get];

    if (mapState.stopsVisible){
        [_stopsVisibilityButton setTitle:@"Disable" forState:UIControlStateNormal];
    } else {
        [_stopsVisibilityButton setTitle:@"Enable" forState:UIControlStateNormal];
    }

    [_stopsVisibilityButton addTarget:self action:@selector(changeSwitch:) forControlEvents:UIControlEventTouchUpInside];
    
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)showAnimate
{
    self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    self.view.alpha = 0;
    [UIView animateWithDuration:.20 animations:^{
        self.view.alpha = 0.95;
        self.view.transform = CGAffineTransformMakeScale(1, 1);
    }];
    
}

- (IBAction)closePopup:(id)sender {
    [self removeAnimate];
}

- (IBAction)changeSwitch:(id)sender{

    if (mapState.stopsVisible){
        NSLog(@"disable the stops");
        [mapState changeStopsVisibility];
        [_stopsVisibilityButton setTitle:@"Enable" forState:UIControlStateNormal];

    } else {
        NSLog(@"enable the stops");
        [mapState changeStopsVisibility];
        [_stopsVisibilityButton setTitle:@"Disable" forState:UIControlStateNormal];
    }

}


- (void)removeAnimate
{
    [UIView animateWithDuration:.25 animations:^{
        self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.view removeFromSuperview];
        }
    }];

    //_mapViewController.optionsMenuIsOpen = false;
    


}

//- (void)showInView:(UIView *)aView withImage:(UIImage *)image withMessage:(NSString *)message animated:(BOOL)animated controller:(BB_ViewController *) mapViewController;
- (void)showInView:(UIView *)aView withImage:(UIImage *)image withMessage:(NSString *)message animated:(BOOL)animated
{
    //_mapViewController = mapViewController;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [aView addSubview:self.view];
        self.view.frame = aView.bounds;
        NSLog(@"Show in View popup frame: %@", NSStringFromCGRect(self.view.frame));

        //self.logoImg.image = image;
        //self.messageLabel.text = message;
        if (animated) {
            [self showAnimate];
        }
    });
    //_mapViewController.optionsMenuIsOpen = true;
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
