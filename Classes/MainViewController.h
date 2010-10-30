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


@interface MainViewController : UIViewController <FlipsideViewControllerDelegate,UIAccelerometerDelegate> {
	IBOutlet MKMapView *maMapView;
	IBOutlet UIButton *refreshButton;
	IBOutlet UILabel *distanceA;
	IBOutlet UILabel *distanceR;
	CFTimeInterval lastTime;

	UIAccelerationValue myAccelerometer[3];
	
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
#pragma mark Accelerometer Delegates
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;

#pragma mark -
#pragma mark Autres méthodes
- (void)initMap;
- (void)getKML;
- (void)majCarte;
- (BOOL)pauseAnnotationExists;
- (CLLocationDistance) getDistance: (CLLocationCoordinate2D *)arrayCoords;
- (CLLocationDistance) getDistanceCovered: (CLLocationCoordinate2D *)arrayCoords;
- (float)estimateCourse:(CLLocationCoordinate2D)fromPoint toPoint:(CLLocationCoordinate2D)toPoint;


@property (nonatomic, retain) UIButton *refreshButton;
@property (nonatomic, retain) UILabel *distanceA;
@property (nonatomic, retain) UILabel *distanceR;


@end
