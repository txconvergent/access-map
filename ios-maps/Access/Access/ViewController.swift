//
//  ViewController.swift
//  Access
//
//  Created by Sahil Parikh on 3/6/19.
//  Copyright © 2019 access-maps. All rights reserved.
//

import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections


class ViewController: UIViewController, MGLMapViewDelegate{
    
    var mapView: NavigationMapView!
    private var UTAustin: MGLCoordinateBounds!
    
    var annotation: MGLPointAnnotation?
    var directionsRoute: Route?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "mapbox://styles/txaccessmaps/cjtqf4lsq01fk1fp4zn44vku5")
        mapView = NavigationMapView(frame: view.bounds, styleURL: url)
        view.addSubview(mapView)
        // Set the map view's delegate
        mapView.delegate = self
        
        // allow the map to display the user's
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        
        // Add a gesture recognizer to the map view
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(longPress)

    }
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did a long press to map coordinates
        
        let point = sender.location(in: mapView)
        if mapView == nil {
            print("here")
        }
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        // remove old annotation
        if let oldAnnoation = annotation{
            mapView.removeAnnotation(oldAnnoation)
        }
        
        // Create a basic point annotation and add it to the map
        let newAnnotation = MGLPointAnnotation()
        newAnnotation.coordinate = coordinate
        newAnnotation.title = "Start navigation"
        mapView.addAnnotation(newAnnotation)
        
        
        //calculate the route from current location to destination
        calculateRoute(from: (mapView.userLocation!.coordinate), to: newAnnotation.coordinate) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
        //set the global annotation
        annotation = newAnnotation
        
    }
    
    // draw the route on the map
    func drawRoute(route: Route) {
        guard route.coordinateCount > 0 else {
            return }
        
        // Convert the route's coordinates into a polyline
        
        var routeCoordinates = route.coordinates!
        
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        
        // if there's already a route line on the map reset it's shape to new route
        if let source = mapView.style?.source(withIdentifier: "route-source") as? MGLShapeSource {
            source.shape = polyline
        } else {
            let source = MGLShapeSource(identifier: "route-source", features: [polyline], options: nil)
            
            // Customize the route line color and widtch
            let lineStyle = MGLLineStyleLayer(identifier: "route-style", source: source)
            lineStyle.lineColor = NSExpression(forConstantValue: #colorLiteral(red: 0.1897518039, green: 0.3010634184, blue: 0.7994888425, alpha: 1))
            lineStyle.lineWidth = NSExpression(forConstantValue: 3)
            
            mapView.style?.addSource(source)
            mapView.style?.addLayer(lineStyle)
        }
    }
    
    // Calculte route to be used for used for navigation
    func calculateRoute(from origin: CLLocationCoordinate2D,
                        to destination: CLLocationCoordinate2D,
                        completion: @escaping (Route?, Error?) -> ()) {
        
       // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let origin = Waypoint(coordinate: origin, coordinateAccuracy: -1, name: "Start")
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        
        // Specify that the route is inteded for walking
        let options = NavigationRouteOptions(waypoints: [origin, destination], profileIdentifier: .walking)
        
        // Generate the route object and draw it on the map
        _ = Directions.shared.calculate(options) { [unowned self] (waypoints, routes, error) in
            self.directionsRoute = routes?.first
            // Draw the route on the map after creating it
            self.drawRoute(route: self.directionsRoute!)

        }
        
    }
    
    // Implement the delegate method that allows annotations to show callouts when tapped
    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }
    
    // Present the navigation view controller when the callout is selected
    func mapView(_ mapView: MGLMapView, tapOnCalloutFor annotation: MGLAnnotation) {
        let navigationViewController = NavigationViewController(for: directionsRoute!)
        self.present(navigationViewController, animated: true, completion: nil)
    }
    
 

}

