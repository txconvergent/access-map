//
//  ViewControllerSearchExtension.swift
//  Access
//
//  Created by Larry Win on 3/30/19.
//  Copyright © 2019 access-maps. All rights reserved.
//

import Foundation
//import CoreLocation
import UIKit
import Mapbox
import MapboxCoreNavigation
import MapboxNavigation
import MapboxDirections

// Extension for performing location search queries
extension ViewController: UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
	
	// Function called everytime the user updates the searchbar that inserts search results into the TableView
	func searchBar (_ searchBar: UISearchBar, textDidChange searchText: String) {
		getSearchResults(searchText, resultCap: 6) {
			// Callback
			DispatchQueue.main.async {
				// UI updating can only occur on the main thread
				self.updateHeaderHeight()
				self.searchTableView.reloadData()
			}
		}
	}
	
	func searchBarTextDidBeginEditing (_ searchBar: UISearchBar) {
		self.searchTableView.reloadData()
	}
	
	// Retract dropdown once done editing
	func searchBarTextDidEndEditing (_ searchBar: UISearchBar) {
		self.searchResults.removeAll()
		self.searchTableView.reloadData()
		updateHeaderHeight()
	}
	
	// Required function from UITableViewDataSource that inserts the search results into the view
	func tableView (_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
		cell.textLabel?.text = self.searchResults[indexPath.row].placeName
		return cell
	}
	
	
	// Required function from UITableViewDataSource that gets the # of cells in search results table view
	func tableView (_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.searchResults.count
	}
	
	// Function from UITableViewDelegate that will get the coords of the selected thing and get the mapbox waypoint
	func tableView (_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let selected = self.searchResults[indexPath.row] // Selected search result
		
		// Draw route
		
		guard let origin = getCurrentLocation() else {
			print("Error getting user location")
			return
		}
		let dest = selected.coords
		
		updateAnnotation(coordinate: dest)
		
		// Draw the route
		self.calculateRoute(from: origin, to: dest) {
			route, error in
			// Check for the error
			if let err = error {
				print("Error drawing route: \(err)")
			}
		}
		
		self.addressSearchBar.resignFirstResponder()
	}
	
	// Collapse rows when nothings in self.searchReults
	/*func tableView (_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return self.searchResults.count > 0 ? UITableView.automaticDimension : 0
	}*/
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	
	// Performs a get request and inserts the results into self.searchResults
	func getSearchResults (_ query: String, resultCap limit: Int, _ callback: @escaping () -> Void) {
		let key = Bundle.main.object(forInfoDictionaryKey: "MGLMapboxAccessToken") as! String
		
		// Create url and request
		guard let urlStr: String = ("https://api.mapbox.com/geocoding/v5/mapbox.places/\(query).json?limit=\(limit)&proximity=-97.739356,30.286356&access_token=\(key)").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
			print("Error encoding url")
			return
		}
		guard let url = URL(string: urlStr) else {
			print("Error getting url")
			return
		}
		
		// Initialize session
		let session = URLSession(configuration: URLSessionConfiguration.default)
		// Do the thing
		let dataTask = session.dataTask(with: URLRequest(url: url)) {
			data, response, error in
			// Check for the error
			if let err = error {
				print("Error: \(err)")
				return
			}
			// Check to see if our data is there
			guard let data = data else {
				print("Error: data not found")
				return
			}
			// Our data is here, try and parse it
			do {
				let json = try JSONSerialization.jsonObject(with: data, options: [])
				self.searchResults.removeAll()
				let parsed = json as! NSDictionary
				// If nothing was returned by our query, just return
				guard let features = parsed["features"] as? NSArray else {return}
				for feature in features {
					// Add the place name to our list of search results
					guard let castedFeature = feature as? NSDictionary else {return}
					guard let placeName = castedFeature["place_name"] as? String else {return}
					guard let coordinates = castedFeature["center"] as? [Double] else {return}
					let coords = CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
					let searchResult = SearchResult(placeName: placeName, coords: coords)
					self.searchResults.append(searchResult)
				}
				callback()
			} catch {
				print("rip")
				return
			}
		}
		dataTask.resume()
	}
	
	func updateHeaderHeight () {
		// Update tableView
		// Now dynamically resize header
		let headerSize = CGSize(width: headerView.frame.width, height: addressSearchBar.frame.height + searchTableView.contentSize.height + CGFloat(5))
		headerView.frame = CGRect(origin: headerView.frame.origin, size: headerSize)
		searchTableView.frame = CGRect(origin: searchTableView.frame.origin, size: searchTableView.contentSize)
		print(searchTableView.frame.height)
	}
	
	func getCurrentLocation () -> CLLocationCoordinate2D? {
		return self.mapView.userLocation?.coordinate
	}
	
}

struct SearchResult {
	
	let placeName: String
	let coords: CLLocationCoordinate2D
	
}
