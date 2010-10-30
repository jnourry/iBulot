//
//  FlipsideViewController.h
//  iBulot
//
//  Created by Jocelyn Nourry on 11/10/10.
//  Copyright 2010 Personal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iBulotAppDelegate.h"


@protocol FlipsideViewControllerDelegate;


@interface FlipsideViewController : UIViewController {
	id <FlipsideViewControllerDelegate> delegate;
	
	IBOutlet UISlider *monSlider;
	IBOutlet UILabel *valeurSlider;
	IBOutlet UISwitch *shakeSwitch;
}

@property (nonatomic, assign) id <FlipsideViewControllerDelegate> delegate;
@property (nonatomic, retain) IBOutlet UISlider *monSlider;  
@property (nonatomic, retain) IBOutlet UILabel *valeurSlider;  
@property (nonatomic, retain) IBOutlet UISwitch *shakeSwitch;  


- (IBAction)done:(id)sender;
- (IBAction)updateSlider:(UISlider *)sender;
- (IBAction)updateSwitch:(UISwitch *)sender;


@end


@protocol FlipsideViewControllerDelegate
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller;
@end

