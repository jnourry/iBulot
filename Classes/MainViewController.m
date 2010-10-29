//
//  MainViewController.m
//  iBulot
//
//  Created by Jocelyn Nourry on 11/10/10.
//  Copyright 2010 Personal. All rights reserved.
//

#import "MainViewController.h"
#import <MapKit/MapKit.h>

#define kMaxPoints						100

// Accelerometer constants
#define kAccelerometerFrequency			40
#define kFilteringFactor				0.1
#define kMinEraseInterval				2.0
#define kEraseAccelerationThreshold		2.0


// Déclaration des globales par défaut
// - nombre d'annotations
int nb_points = 5;
int old_nb_points = 10;

// - Shake YES or NO
BOOL shakeStatus=YES;


@implementation MainViewController

@synthesize refreshButton;
@synthesize distanceA;
@synthesize distanceR;



// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
		
	// Petit message d'alerte pour les gens qui essaient avec autre chose qu'un iPhone
	NSString *device = [[UIDevice currentDevice] model];
	if  ([device rangeOfString:@"iPhone"].location == NSNotFound)
		{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Attention !!"
							  message:NSLocalizedString(@"This app only works on iPhone devices",@"")
							  delegate:self 
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		[alert release];
		}
	
	// Définir le zoom
	MKCoordinateSpan span;
	span.latitudeDelta=0.05;
	span.longitudeDelta=0.05;
	
	// Définir les coordonnées de Paris
	CLLocationCoordinate2D parisCoordinates;
	parisCoordinates.latitude=48.858391;
	parisCoordinates.longitude=2.35279;
	
	MKCoordinateRegion parisRegion;
	parisRegion.span=span;
	parisRegion.center=parisCoordinates;
	
	// centrer la carte sur Paris
	[maMapView setRegion:parisRegion animated:TRUE];
	
	// Affichage de la position utilisateur
	maMapView.showsUserLocation = YES;
	maMapView.userLocation.title = NSLocalizedString(@"My Location",@"");

	
	// Gestion de l'accéléromètre
	[[UIAccelerometer sharedAccelerometer] setUpdateInterval:1.0/kAccelerometerFrequency];
	[[UIAccelerometer sharedAccelerometer] setDelegate:self];
	  
	 
}

// To update Map at launch and when you come back from Pref View
- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (nb_points != old_nb_points) {
		// Recherche du tracé et des points
		[self getKML];
	}

}

// Save the number of points used for the current map
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	old_nb_points = nb_points;
}

#pragma mark -
#pragma mark Autres méthodes
- (void)getKML
{
	// Affichage de la roue de recherche d'activité réseau
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
	
	
	// Suppression des annotations sauf la position de l'utilisateur et la position Pause
	NSMutableArray *toRemove = [NSMutableArray arrayWithCapacity:nb_points];
	for (id <MKAnnotation>annotation in maMapView.annotations)
		if (annotation != maMapView.userLocation &&
			annotation.title != @"Pause")
			[toRemove addObject:annotation];
	[maMapView removeAnnotations:toRemove];
	
	
	// Récupération du fichier KML à traiter
	NSString *pathKML = [NSString stringWithFormat:@"http://www.rollers-coquillages.org/getkml.php?nb=%d",nb_points];
	
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:pathKML]
							   cachePolicy:NSURLRequestUseProtocolCachePolicy
						   timeoutInterval:15.0];	
		
	connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	
	if (connection)
	{
		payload = [[NSMutableData data] retain];
		NSLog(@"Début de la connexion	: %@", connection);
	}
	else
	{
		NSLog(@"Problème de connexion");
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:NSLocalizedString(@"Network problem",@"")
							  message:NSLocalizedString(@"Init of URL connexion failed",@"")
							  delegate:self 
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		[alert release];
		
		// Suppression de la roue de recherche d'activité réseau
		UIApplication* app = [UIApplication sharedApplication];
		app.networkActivityIndicatorVisible = NO;
		
	}
}

- (void)majCarte	
{
	NSError *erreur;

	//Enregistrement dans un fichier temporaire dans le dossier Documents
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *pathFichierTemp = [NSString stringWithFormat:@"%@/%@", [paths objectAtIndex: 0], @"tmp.kml"];
	NSLog(@"Path : %@", pathFichierTemp);
	
	[payload writeToFile:pathFichierTemp atomically:NO];
	
	// Suppression du fichier temporaire si il existe
	if([monFileManager fileExistsAtPath:pathFichierTemp]) 
	{
		[monFileManager removeItemAtPath:pathFichierTemp error:&erreur];
		if (erreur)
		{
			NSLog(@"erreur File Manager : %@", erreur);
		}
	}
	
	
	// Suppression de la roue de recherche d'activité réseau
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = NO;
	
	kml = [[KMLParser parseKMLAtPath:pathFichierTemp] retain];

	
	CLLocationDistance distanceTotale = 0;
	CLLocationDistance distanceParcourue = 0;
	CLLocationDistance distanceSegment = 0;
	CLLocationCoordinate2D multicoords[kMaxPoints];
	
	// Création d'un NSRange de 0 à 100 points
	NSRange multirange;
	multirange.location = 0;
	multirange.length = kMaxPoints;


	int segmentNumber = 0;
	int i=0;
	
	// Recherche parmi les placemarks de ceux étant des MKPolyline (ie les 2 segments du parcours)
	for (KMLPlacemark *placemark in (kml.overlays))
		 {
			if ([placemark isKindOfClass:[MKPolyline class]])
			{
				segmentNumber++;
					
				// Récupération des points dans le MKPolyline (à l'aide d'une méthode héritée de MKMultiPoint)
				[placemark getCoordinates:multicoords range:multirange];
				
				// Nettoyage du tableau des parasites (0,-0) (-0,0) etc...
				for (i=0; i<kMaxPoints; i++) {
					if ((floor(fabs(multicoords[i].latitude)) == 0 )  ||
						(floor(fabs(multicoords[i].longitude)) == 0))
						{
							multicoords[i].latitude = 0;
							multicoords[i].longitude = 0;
						}
				}
				
				// Calcul de la distance du segment
				distanceSegment = [self getDistance:multicoords];
				
				// Estimation de la distance parcourue
				distanceParcourue = distanceParcourue + [self getDistanceCovered:multicoords];
				if (distanceParcourue == 0 &&
					segmentNumber==2) {
					distanceParcourue = distanceParcourue + distanceTotale;
				}
				
				NSLog(@"distance parcourue : %f",[self getDistanceCovered:multicoords]);

				
				if (segmentNumber==1)
				{
					// Distance Aller
					distanceA.text = [NSString stringWithFormat:@"%@ : %.02f km",
									  NSLocalizedString(@"First Part",@""),
									  distanceSegment/1000];
				}
				else if (segmentNumber==2)
				{
					// Distance Retour
					distanceR.text = [NSString stringWithFormat:@"%@ : %.02f km",
									  NSLocalizedString(@"Second Part",@""),
									  distanceSegment/1000];
				}
				distanceTotale = distanceTotale + distanceSegment;
					
			}
		 }
	NSLog(@"distanceTotale : %f",distanceTotale);

	
	// Création de tous les objets MKOverlay sur la MapView
    NSArray *overlays = [kml overlays];
    [maMapView addOverlays:overlays];
    
    // Idem pour les objets MKAnnotation
    NSArray *annotations = [kml points];
    [maMapView addAnnotations:annotations];
    
    // Balayage de la liste des "couches" et annotations et création d'un MKMapRect flyTo 
    // qui les rassemble tous
    MKMapRect flyTo = MKMapRectNull;
    for (id <MKOverlay> overlay in overlays) {
        if (MKMapRectIsNull(flyTo)) {
            flyTo = [overlay boundingMapRect];
        } else {
            flyTo = MKMapRectUnion(flyTo, [overlay boundingMapRect]);
        }
    }
    
    for (id <MKAnnotation> annotation in annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(flyTo)) {
            flyTo = pointRect;
        } else {
            flyTo = MKMapRectUnion(flyTo, pointRect);
        }
    }
    
    // Repositionnement de la carte pour que les annotations et les "couches" soient visibles
    maMapView.visibleMapRect = flyTo;
	
}

- (CLLocationDistance) getDistance: (CLLocationCoordinate2D *)arrayCoords;
{
	int i;
	CLLocationDistance retDistance = 0;
	CLLocationDistance distanceBetween2Points = 0;

	for (i=0; i<kMaxPoints; i++)
	{
				
		if (arrayCoords[i].latitude != 0 &&
			arrayCoords[i+1].latitude != 0 &&
			i<99)
		{
			// Calcul de la distance entre deux points consécutifs
			distanceBetween2Points = MKMetersBetweenMapPoints(
															  MKMapPointForCoordinate(arrayCoords[i]),
															  MKMapPointForCoordinate(arrayCoords[i+1])     );
			retDistance = retDistance + distanceBetween2Points;
		}
		else if (arrayCoords[i].latitude != 0 &&
				 arrayCoords[i+1].latitude == 0 
				 )
		{
			// Création d'un pin "Pause" sur la carte
			MKPointAnnotation *pauseAnnotation = [[[MKPointAnnotation alloc] init] autorelease];
			
			pauseAnnotation.coordinate = arrayCoords[i];
			pauseAnnotation.title      = @"Pause";
			
			[maMapView addAnnotation:pauseAnnotation];
		}
	}
	return retDistance;
	
}


- (CLLocationDistance) getDistanceCovered: (CLLocationCoordinate2D *)arrayCoords;
{
	int i, extrapolatedLocationPoint;
	float minInterval=99999999;
	float tempInterval;
	CLLocationDistance retDistance = 0;
	
	// Recherche de l'occurrence du tableau la plus proche de la position utilisateur
	for (i=0; i<kMaxPoints; i++)
	{
		
		if (arrayCoords[i].latitude != 0)
		{
			// Calcul de la distance entre chaque point et la position de l'utilisateur
			tempInterval = MKMetersBetweenMapPoints(
													MKMapPointForCoordinate(arrayCoords[i]),
													MKMapPointForCoordinate(maMapView.userLocation.coordinate)
													);
			//NSLog(@"tempInterval : %f",tempInterval);

			if (tempInterval < minInterval) 
			{
				extrapolatedLocationPoint = i;
				minInterval = tempInterval;
			}
		}
	}
	NSLog(@"extrapolatedLocationPoint : %d",extrapolatedLocationPoint);

	
	if (minInterval < 500) 
	{
		// Calcul de la distance jusqu'au plus proche point
		for (i=0; i<extrapolatedLocationPoint - 1; i++)
		{
				retDistance = retDistance + MKMetersBetweenMapPoints(
																	 MKMapPointForCoordinate(arrayCoords[i]),
																	 MKMapPointForCoordinate(arrayCoords[i+1])     );
		}
		
		// Ajout de la distance avec le point le plus proche
		retDistance = retDistance + MKMetersBetweenMapPoints(
										MKMapPointForCoordinate(arrayCoords[extrapolatedLocationPoint]),
										MKMapPointForCoordinate(maMapView.userLocation.coordinate));
		
		return retDistance;
	}
	// Si on n'a pas trouvé de point concordant, on retourne une distance nulle
	else {
		return 0;
	}

		
}

#pragma mark -
#pragma mark NSURLConnection Delegates
- (void)connection:(NSURLConnection *)conn didReceiveResponse:(NSURLResponse *)response
{
	NSLog(@"Réponse reçue - Longueur prévue : %i", [response expectedContentLength]);
	
	[payload setLength:0];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data
{
	NSLog(@"Réception en cours. Taille : %i  Taille totale : %i", [data length], [payload length]);
	[payload appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn
{
	NSLog(@"Connexion terminée : %@", conn);

	[conn release];
	
	[self majCarte];
	
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error
{
	
	[payload setLength:0];
	UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:NSLocalizedString(@"Network problem",@"")
						  message:NSLocalizedString(@"Connexion to R&C site failed. Please try again",@"")
						  delegate:self 
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil];
	[alert show];
	[alert release];
	
	// Suppression de la roue de recherche d'activité réseau
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = NO;

	NSLog(@"Connexion plantée");		
}


	 
#pragma mark -
#pragma mark Accelerometer Delegates
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration{
	UIAccelerationValue length,x,y,z;
	UIAccelerationValue myAccelerometer[3];
	
	// Lowpass filter
	myAccelerometer[0] = acceleration.x * kFilteringFactor + myAccelerometer[0] * (1.0 - kFilteringFactor);
	myAccelerometer[1] = acceleration.y * kFilteringFactor + myAccelerometer[1] * (1.0 - kFilteringFactor);
	myAccelerometer[2] = acceleration.z * kFilteringFactor + myAccelerometer[2] * (1.0 - kFilteringFactor);
	
	// Compute values of 3 axes (with a high pass simple filter)
	x = acceleration.x - myAccelerometer[0];
	y = acceleration.y - myAccelerometer[1];
	z = acceleration.z - myAccelerometer[2];
	
	// Compute intensity of acceleration
	length = sqrt(x*x + y*y + z*z);
	
	// Update map only
	if ((length >= kEraseAccelerationThreshold) &&
		(CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval)){
		if (shakeStatus == YES) {
			NSLog(@"Dans Accélération -> OK");
			[self getKML];
		}
		lastTime = CFAbsoluteTimeGetCurrent();
	}
	
	
}
	 
	 
- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller {
    
	[self dismissModalViewControllerAnimated:YES];
}


- (IBAction)showInfo:(id)sender {    
	
	FlipsideViewController *controller = [[FlipsideViewController alloc] initWithNibName:@"FlipsideView" bundle:nil];
	controller.delegate = self;
	
	controller.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self presentModalViewController:controller animated:YES];
	
	[controller release];
}

// A l'appui du bouton : Màj
- (IBAction)refreshCarte:(id)sender {  	
	
	// Récupération KML et màj des annotations	
	[self getKML];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc. that aren't in use.
}


- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations.
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


// Désallocation des différents objets
- (void)dealloc {
	[refreshButton release];
	[distanceA release];
	[distanceR release];
	[maMapView release];
	[payload release];
	[request release];
	[super dealloc];
}

#pragma mark MKMapViewDelegate

- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay
{
    return [kml viewForOverlay:overlay];
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
	{
		// Si c'est la punaise "Pause", affichage en vert
		if (annotation.title == @"Pause")
		{
			MKPinAnnotationView *PauseView=[[[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pause"] autorelease];
			
			PauseView.pinColor = MKPinAnnotationColorGreen;
			PauseView.animatesDrop=NO;
			PauseView.canShowCallout = YES;
			PauseView.calloutOffset = CGPointMake(-5, 5);
			
			return PauseView;
		}
		// Sinon, on laisse KMLParser gérer :)
		else
		{
			return [kml viewForAnnotation:annotation];
		}
	}

@end
