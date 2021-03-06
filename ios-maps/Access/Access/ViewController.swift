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
    @IBOutlet weak var searchTableView: UITableView!
    
    @IBOutlet weak var addressSearchBar: UISearchBar!
    @IBOutlet weak var headerView: UIView!
    
    var mapView: NavigationMapView!
    private var UTAustin: MGLCoordinateBounds!
    
    var annotation: MGLPointAnnotation?
    var directionsRoute: Route?
    
    var searchResults: [SearchResult] = []
    let searchItemCap = 7
    var PCL = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView = NavigationMapView(frame: view.bounds)
        
        // Set searchbar's delegates
        addressSearchBar.delegate = self
        searchTableView.dataSource = self
        searchTableView.delegate = self
        
        let url = URL(string: "mapbox://styles/txaccessmaps/cjtqf4lsq01fk1fp4zn44vku5")
        mapView = NavigationMapView(frame: view.bounds, styleURL: url)
        view.addSubview(mapView)
        view.addSubview(headerView) // Adding header on top of map view
        // Set the map view's delegate
        mapView.delegate = self
        
        // allow the map to display the user's
        mapView.showsUserLocation = true
        mapView.setUserTrackingMode(.follow, animated: true)
        
        // Add a gesture recognizer to the map view
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPress(_:)))
        mapView.addGestureRecognizer(longPress)
        
        // self.addGestureToDismissKeyboardOnTap() // Create a gesture recognizer that retracts the keyboard on tap for this vieng
        
    }
    
    /*override func viewDidLayoutSubviews() {
     searchTableView.frame = CGRect(x: searchTableView.frame.origin.x, y: searchTableView.frame.origin.y, width: searchTableView.frame.size.width, height: searchTableView.contentSize.height)
     searchTableView.reloadData()
     }*/
    
    @objc func didLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        
        // Converts point where user did a long press to map coordinates
        
        let point = sender.location(in: mapView)
        if mapView == nil {
            print("here")
        }
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        
        updateAnnotation(coordinate: coordinate)
        
        //calculate the route from current location to destination
        calculateRoute(from: (mapView.userLocation!.coordinate), to: coordinate) { (route, error) in
            if error != nil {
                print("Error calculating route")
            }
        }
        
        
    }
    
    func updateAnnotation(coordinate: CLLocationCoordinate2D) {
        // remove old annotation
        if let oldAnnoation = annotation{
            mapView.removeAnnotation(oldAnnoation)
        }
        
        // Create a basic point annotation and add it to the map
        let newAnnotation = MGLPointAnnotation()
        newAnnotation.coordinate = coordinate
        newAnnotation.title = "Start navigation"
        mapView.addAnnotation(newAnnotation)
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

       // Coordinate accuracy is the maximum distance away from the waypoint that the route may still be considered viable, measured in meters. Negative values indicate that a indefinite number of meters away from the route and still be considered viable.
        let tower = CLLocationCoordinate2D(latitude: 30.285494, longitude: -97.739466)
        let origin = Waypoint(coordinate: tower, coordinateAccuracy: -1, name: "Start")
        var waypoints = [Waypoint]()
        waypoints.append(origin)
        let fountainRamp = CLLocationCoordinate2D(latitude: 30.2840589, longitude: -97.7393999)
        let founWay = Waypoint(coordinate: fountainRamp, coordinateAccuracy: -1, name: "fountain")
        waypoints.append(founWay)
        if PCL {
            let PCL = CLLocationCoordinate2D(latitude: 30.28335455, longitude: -97.73841977)
            let pclWay = Waypoint(coordinate: PCL, coordinateAccuracy: -1, name: "PCL")
            waypoints.append(pclWay)
        }
        let destination = Waypoint(coordinate: destination, coordinateAccuracy: -1, name: "Finish")
        waypoints.append(destination)
        PCL = !PCL
        // Specify that the route is inteded for walking
        let options = NavigationRouteOptions(waypoints: waypoints, profileIdentifier: .walking)
        
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
    
    func mapView(_ mapView: MGLMapView) {
        addressSearchBar.resignFirstResponder()
    }
    
    
    
}
