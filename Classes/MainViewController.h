//
//  MainViewController.h
//  iBulot
//
//  Created by Jocelyn Nourry on 11/10/10.
//  Copyright 2010 Personal. All rights reserved.
//

#import "FlipsideViewController.h"
#import <MapKit/MapKit.h>
#import "KMLParser.h"


@interface MainViewController : UIViewController <FlipsideViewControllerDelegate> {
	IBOutlet MKMapView *maMapView;
	IBOutlet UIButton *refreshButton;
	IBOutlet UILabel *distanceA;
	IBOutlet UILabel *distanceR;
	
	KMLParser *kml;
	
	// Objets liés à la connexion URL au fichier .kml
	NSURLConnection *connection;
	NSURLRequest *request;
	NSMutableData *payload;
	
	NSFileManager *monFileManager;
}

- (IBAction)showInfo:(id)sender;
- (IBAction)refreshCarte:(id)sender;

#pragma mark -
#pragma mark NSURLConnection Delegates
- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data;
- (void)connectionDidFinishLoading:(NSURLConnection *)conn;
- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error;

#pragma mark -
#pragma mark Autres méthodes
- (void)getKML;
- (void)majCarte;

@property (nonatomic, retain) UIButton *refreshButton;
@property (nonatomic, retain) UILabel *distanceA;
@property (nonatomic, retain) UILabel *distanceR;


@end
