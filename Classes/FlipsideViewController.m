//
//  FlipsideViewController.m
//  iBulot
//
//  Created by Jocelyn Nourry on 11/10/10.
//  Copyright 2010 Personal. All rights reserved.
//

#import "FlipsideViewController.h"

extern int nb_points;
extern BOOL shakeStatus;

@implementation FlipsideViewController

@synthesize delegate;
@synthesize monSlider;
@synthesize valeurSlider;
@synthesize shakeSwitch;
@synthesize vue1,vue2;


- (void)viewDidLoad {
    [super viewDidLoad];
		
	// Récupération du nombre de points
	if (nb_points > 0)
		{
		monSlider.value = nb_points;
		valeurSlider.text = [NSString stringWithFormat:@"%d", nb_points];
		}
	
	// Récupération du statut du switch
	if (shakeStatus == YES) 
	{
		[shakeSwitch setOn:YES animated:NO];
	}
	else {
		[shakeSwitch setOn:NO animated:NO];
	}
			
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];      
	
	// Adds gray layers
	//vue1.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];  
	vue1.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.15];
	vue1.layer.cornerRadius = 6.0;
	
	//vue1.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];  
	vue2.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.15];
	vue2.layer.cornerRadius = 6.0;
}


- (IBAction)done:(id)sender {
	[self.delegate flipsideViewControllerDidFinish:self];	
}

// Dès qu'on change la valeur du Slider
- (IBAction)updateSlider:(UISlider *)sender {
	nb_points = (int)[sender value];
	 
	valeurSlider.text = [NSString stringWithFormat:@"%d", nb_points];
	
	// Save Slider value
	NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
	[userPrefs setInteger:nb_points forKey:@"nb_points"];
	[userPrefs synchronize];
}

// Dès qu'on change la valeur du Switch
- (IBAction)updateSwitch:(UISwitch *)sender {
	if (sender.on) 
	{
		shakeStatus = YES;
	}
	else {
		shakeStatus = NO;
	}
	
	// Save Switch state
	NSUserDefaults *userPrefs = [NSUserDefaults standardUserDefaults];
	[userPrefs setBool:shakeStatus forKey:@"shakeStatus"];
	[userPrefs synchronize];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

	

- (void)dealloc {
	[monSlider release];
	[valeurSlider release];
	[shakeSwitch release];
	[vue1 release];
	[vue2 release];
    [super dealloc];
}


@end
