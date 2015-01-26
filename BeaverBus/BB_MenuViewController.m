//
//  BB_MenuViewController.m
//  BeaverBus
//
//  Created by norredm on 1/12/15.
//  Copyright (c) 2015 Oregon State University. All rights reserved.
//

#import "BB_MenuViewController.h"
#import "BB_ViewController.h"
#import "BB_MapState.h"
#import "PopUpViewController.h"

@interface BB_MenuViewController ()

@property BB_ViewController *mapViewController;
@property PopUpViewController *busInformationViewController;

@end

@implementation BB_MenuViewController

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
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)showInView:(UIView *)aView withImage:(UIImage *)image withMessage:(NSString *)message animated:(BOOL)animated withFrame:(CGRect)box controller:(BB_ViewController *) mapViewController;
{
    NSLog(@"Show inView");
    _mapViewController = mapViewController;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.view.frame = box;
        [aView addSubview:self.view];
        
        //self.logoImg.image = image;
        //self.messageLabel.text = message;
        if (animated) {
            [self showAnimate];
        }
    });
}


- (void)showAnimate
{
    NSLog(@"Show animate : %@", NSStringFromCGRect(self.view.frame));
    self.view.alpha = 1;
    self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
    self.view.alpha = 0;
    [UIView animateWithDuration:.20 animations:^{
        self.view.alpha = 0.95;
        self.view.transform = CGAffineTransformMakeScale(1, 1);
        
        //_mapViewController.optionsMenuIsOpen = true;
        ;        NSLog(@"optionsMenuIsOpen set to :: %hhd", _mapViewController.optionsMenuIsOpen);

    }];
    
    
}

- (void)removeAnimate
{
    NSLog(@"Remove animate");
    [UIView animateWithDuration:.25 animations:^{
        self.view.transform = CGAffineTransformMakeScale(1.3, 1.3);
        self.view.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.view removeFromSuperview];
            self.view.transform = CGAffineTransformMakeScale(1.0, 1.0);
            
            //_mapViewController.optionsMenuIsOpen = false;
            NSLog(@"optionsMenuIsOpen set to :: %hhd", _mapViewController.optionsMenuIsOpen);
        }
    }];
    
    
}

- (IBAction)toggleStopsVisibility:(id)sender {
    [[BB_MapState get] changeStopsVisibility];
    [self removeAnimate];
    [_mapViewController setOptionsMenuIsOpen:false];
}

- (IBAction)showBusInformation:(id)sender {
    [self removeAnimate];
    [_mapViewController setOptionsMenuIsOpen:false];
    _busInformationViewController = [[PopUpViewController alloc] initWithNibName:@"PopUpViewController" bundle:nil];
    CGRect menuFrame = CGRectMake(0, 0, 100, 150);
    NSLog(@"Here is rect: %@", NSStringFromCGRect(menuFrame));
    _mapViewController = [BB_ViewController get];
    //NSLog(@"FRAME: %@", NSStringFromCGRect([[_mapViewController getMainView] frame]));
    [_busInformationViewController showInView:[_mapViewController getMainView] withImage:nil withMessage:@"" animated:YES];
    //        [_popViewController setTitle:@"Options"];
    //        [_popViewController showInView:self.view withImage:nil withMessage:@"" animated:YES controller:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
