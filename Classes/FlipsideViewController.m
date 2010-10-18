//
//  FlipsideViewController.m
//  iBulot
//
//  Created by Jocelyn Nourry on 11/10/10.
//  Copyright 2010 Personal. All rights reserved.
//

#import "FlipsideViewController.h"

extern int nb_points;

@implementation FlipsideViewController

@synthesize delegate;
@synthesize monSlider;
@synthesize valeurSlider;


- (void)viewDidLoad {
    [super viewDidLoad];
		
	if (nb_points > 0)
		{
		monSlider.value = nb_points;
		valeurSlider.text = [NSString stringWithFormat:@"%d", nb_points];
		}
			
    self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];      
}


- (IBAction)done:(id)sender {
	[self.delegate flipsideViewControllerDidFinish:self];	
}

// Dès qu'on change la valeur du Slider
- (IBAction)updateSlider:(UISlider *)sender {
	nb_points = (int)[sender value];
	 
	valeurSlider.text = [NSString stringWithFormat:@"%d", nb_points];
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
    [super dealloc];
}


@end
