//
//  MainViewController.m
//  iBulot
//
//  Created by Jocelyn Nourry on 11/10/10.
//  Copyright 2010 Personal. All rights reserved.
//

#import "MainViewController.h"
#import <MapKit/MapKit.h>

// Déclaration des globales par défaut
// - nombre d'annotations
int nb_points = 5;

// - distances
double distance_aller = 0;
double distance_retour = 0;


@implementation MainViewController

@synthesize refreshButton;


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
		
	// Petit message d'alerte pour les gens qui essaient avec autre chose qu'un iPhone
	NSString *device = [[UIDevice currentDevice] model];
	if  ([device rangeOfString:@"iPhone"].location == NSNotFound)
		{
		UIAlertView *alert = [[UIAlertView alloc]
							  initWithTitle:@"Attention !!"
							  message:@"Cette application ne fonctionne que sur iPhone"
							  delegate:self 
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil];
		[alert show];
		[alert release];
		}
	[device release];
	
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
	
	// Recherche du tracé et des points
	[self getKML];
}

#pragma mark -
#pragma mark Autres méthodes
- (void)getKML
{
	// Affichage de la roue de recherche d'activité réseau
	UIApplication* app = [UIApplication sharedApplication];
	app.networkActivityIndicatorVisible = YES;
	
	NSString *pathKML = [NSString stringWithFormat:@"http://www.rollers-coquillages.org/getkml.php?nb=%d",nb_points];
	
	request = [NSURLRequest requestWithURL:[NSURL URLWithString:pathKML]
							   cachePolicy:NSURLRequestUseProtocolCachePolicy
						   timeoutInterval:10.0];	
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
							  initWithTitle:@"Problème de connexion"
							  message:@"La connexion au site R&C n'a pas pu être établie"
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
	int sequenceNumber = 0;
	
	for (KMLPlacemark *placemark in (kml.overlays))
		 {
			if ([placemark isKindOfClass:[MKPolyline class]])
			{
				sequenceNumber++;
				CLLocationDistance distanceSequence = 0;

				CLLocationCoordinate2D multicoords[100];
					
				// Création d'un NSRange de 0 à 100 points
				NSRange multirange;
				multirange.location = 0;
				multirange.length = 100;
					
				// Récupération des points dans le MKPolyline (à l'aide d'une méthode héritée de MKMultiPoint)
				[placemark getCoordinates:multicoords range:multirange];

				int i;
				for (i=0; i<multirange.length; i++)
					{
					NSLog(@"multicoords : %f %f",multicoords[i].latitude,multicoords[i].longitude);

					CLLocationDistance distanceBetween2Points = 0;
						
					if (floor(fabs(multicoords[i].latitude)) != 0 &&
						floor(fabs(multicoords[i].longitude)) != 0 &&
						floor(fabs(multicoords[i+1].latitude)) != 0 &&
						floor(fabs(multicoords[i+1].longitude)) != 0 &&
						i<99)
						{
							// Calcul de la distance entre deux points consécutifs
							distanceBetween2Points = MKMetersBetweenMapPoints(
										MKMapPointForCoordinate(multicoords[i]),
										MKMapPointForCoordinate(multicoords[i+1])     );
							NSLog(@"Distance : %f",distanceBetween2Points);
							distanceSequence = distanceSequence + distanceBetween2Points;
						}
					}
					if (sequenceNumber==1)
					{
						distanceA.text = [NSString stringWithFormat:@"%.02f km", distanceSequence/1000];
						distance_aller = distanceSequence;
					}
					else if (sequenceNumber==2)
					{
						distanceR.text = [NSString stringWithFormat:@"%.02f km", distanceSequence/1000];
						distance_retour = distanceSequence;
					}
					distanceTotale = distanceTotale + distanceSequence;
					
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
						  initWithTitle:@"Problème de connexion"
						  message:@"La connexion au site R&C a été interrompue. Veuillez réessayer."
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
		
	// Suppression des annotations sauf la position de l'utilisateur
	NSMutableArray *toRemove = [NSMutableArray arrayWithCapacity:10];
	for (id annotation in maMapView.annotations)
		if (annotation != maMapView.userLocation)
			[toRemove addObject:annotation];
	[maMapView removeAnnotations:toRemove];
		
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
	[maMapView release];
	[payload release];
	[connection release];
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
    return [kml viewForAnnotation:annotation];
}


@end
