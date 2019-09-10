//
//  ViewController.swift
//  Locations
//
//  Created by Isaac Ballas on 2019-08-30.
//  Copyright © 2019 Isaacballas. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
  // MARK: - Properties
  let locationManager = CLLocationManager()
  var location: CLLocation?
  var updatingLocation = false
  var lastLocationError: Error?
  var geocoder = CLGeocoder()
  var placemark: CLPlacemark?
  var performingReverseGeocoding = false
  var lastGeocodingError: Error?
  var timer: Timer?
  var managedObjectContext: NSManagedObjectContext!
  
  // MARK: - Outlets
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  
  // MARK: - Actions
  @IBAction func getLocation() {
    // Ask for permission before getting location or it will not work.
    let authStatus = CLLocationManager.authorizationStatus()
    if authStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    if authStatus == .denied || authStatus == .restricted {
      showLocationServicesDeniedAlert()
      return
    }
    // Clear out these variables and start fresgh
    placemark = nil
    lastGeocodingError = nil
    startLocationManager()
    updateLabels()
  }
  
  // Hide the nav bar
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }
  
  // Show the nav bar on the next screen
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.isNavigationBarHidden = false
    
  }
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    
  }
  
  // MARK: - CLLocationManagerDelegate
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError: \(error.localizedDescription)")
    // Keep trying until coordinates are found.
    if (error as NSError).code == CLError.locationUnknown.rawValue { return }
    // In the case of a more serious error (network, ect) store the error in lastLocationError
    lastLocationError = error
    stopLocationManager()
    updateLabels()
  }
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("DidUpdateLocations: \(newLocation)")
    // If the time at which the given location object was determined is less than 5 seconds, cache the result. Instead of a newLocation, it gives the most recent one.
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
    // To determine whether new readings are more accurate than previous ones, you will use the `horizontalAccuracy` that is less than 0. In which case these measurements are invalid and ignore them.
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
    if let location = location {
      distance = newLocation.distance(from: location)
    }
    
    // This is where you determind if the new reading is more useful than the precious one. Generally speaking, core location starts out with a fairly inaccurate reading amnd then gives you more accurate ones as time passes. PS a larger accuracy values means less accurate.
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      // Clear out previous error
      lastLocationError = nil
      location = newLocation
      // if the new location accuracy is equal or better than the desired accuracy, stop asking location updates.
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        print("We are done")
        stopLocationManager()
        if distance > 0 {
          performingReverseGeocoding = false
        }
      }
      updateLabels()
      if !performingReverseGeocoding {
        print("We are about to geocode")
        performingReverseGeocoding = true
        geocoder.reverseGeocodeLocation(newLocation) { (placemarks, error) in
          self.lastGeocodingError = error
          if error == nil, let p = placemarks, !p.isEmpty {
            self.placemark = p.last!
          } else {
            self.placemark = nil
          }
          self.performingReverseGeocoding = false
          self.updateLabels()
        }
      }
    } else if distance < 1 {
      let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
      if timeInterval > 10 {
        print("Force Done")
        stopLocationManager()
        updateLabels()
      }
    }
  }
  
  // MARK:- Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TagLocation" {
      let controller = segue.destination as! LocationsDetailsViewController
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      // Pass the managed object context to talk to the core data
      controller.managedObjectContext = managedObjectContext
    }
  }
  
  // MARK: - Helper Methods
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alert.addAction(okAction)
    present(alert, animated: true, completion: nil)
  }
  
  func updateLabels() {
    if let location = location {
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.isHidden = false
      messageLabel.text = ""
      
      if let placemark = placemark {
        addressLabel.text = string(from: placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching For Addess..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      // error handling
      let statusMessage: String
      if let error = lastLocationError as NSError? {
        // User did not give permission to use location.
        if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          // If the error is something aside from denied permision, run this block.
          statusMessage = "Error Getting Location"
        }
        // Check if user disabled location services for the whole device instead of the app only.
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = "Tap 'Get My Location' to start."
      }
      messageLabel.text = statusMessage
    }
    configureGetButton()
  }
  
  func configureGetButton() {
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
    } else {
      getButton.setTitle("Get My Location", for: .normal)
    }
  }
  
  func string(from placemark: CLPlacemark) -> String {
    // There will be 2 lines of text
    var line1 = ""
    // if subThroroughfare add it to the string, this is a house number
    if let s = placemark.subThoroughfare {
      line1 += s + " "
    }
    // Same as above but add a space so its not squished.
    if let s = placemark.thoroughfare {
      line1 += s
    }
    // Same logic as above
    var line2 = ""
    if let s = placemark.locality {
      line2 += s + " "
    }
    if let s = placemark.administrativeArea {
      line2 += s + " "
    }
    if let s = placemark.postalCode {
      line2 += s
    }
    // Concactenate the two lines.
    return line1 + "\n" + line2
  }
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }
  }
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  @objc func didTimeOut() {
    print("Time Out")
    if location == nil {
      stopLocationManager()
      lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
    }
  }

}

