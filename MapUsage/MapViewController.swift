//
//  MapViewController.swift
//  MapUsage
//
//  Created by YASIN AKCA on 17.04.2020.
//  Copyright © 2020 YASIN AKCA. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var commentText: UITextField!
    
    var locationManager = CLLocationManager()
    
    var chosenLatitude: Double?
    var chosenLongitude: Double?
    
    var chosenName = ""
    var chosenId: UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude: Double?
    var annotationLongitude: Double?

    @IBOutlet weak var mapView: MKMapView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        if chosenName != "" {
            //coredata
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Places")
            let id = chosenId?.uuidString
            fetchRequest.predicate = NSPredicate(format: "id = %@", id!)
            fetchRequest.returnsObjectsAsFaults = false
            
            do {
                let results = try context.fetch(fetchRequest)
                if results.count > 0 {
                    for result in results as! [NSManagedObject] {
                        if let name = result.value(forKey: "name") as? String {
                            annotationTitle = name
                            if let comment = result.value(forKey: "comment") as? String {
                                annotationSubtitle = comment
                                if let latitude = result.value(forKey: "latitude") as? Double {
                                    annotationLatitude = latitude
                                    if let longitude = result.value(forKey: "longitude") as? Double {
                                        annotationLongitude = longitude
                                        
                                        let annotation = MKPointAnnotation()
                                        let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude!, longitude: annotationLongitude!)
                                        annotation.coordinate = coordinate
                                        annotation.title = annotationTitle
                                        annotation.subtitle = annotationSubtitle
                                        
                                        self.mapView.addAnnotation(annotation)
                                        self.nameText.text = annotationTitle
                                        self.commentText.text = annotationSubtitle
                                    }
                                }
                            }
                        }
                    }
                }
            }catch {
                print("Error")
            }
        }
        
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(recognizer:)))
        recognizer.minimumPressDuration = 2
        self.mapView.addGestureRecognizer(recognizer)
        
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
        let region = MKCoordinateRegion(center: location, span: span)
        self.mapView.setRegion(region, animated: true)
    }
    
    @objc func chooseLocation(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == .began {
            let touchedPoint = recognizer.location(in: self.mapView)
            let touchedCoordinates = self.mapView.convert(touchedPoint, toCoordinateFrom: self.mapView)
            
            chosenLatitude = touchedCoordinates.latitude
            chosenLongitude = touchedCoordinates.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinates
            annotation.title = nameText.text
            annotation.subtitle = commentText.text
            self.mapView.addAnnotation(annotation)
        }
    }

    @IBAction func saveClicked(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Places", into: context)
        
        newPlace.setValue(nameText.text!, forKey: "name")
        newPlace.setValue(commentText.text!, forKey: "comment")
        newPlace.setValue(UUID(), forKey: "id")
        newPlace.setValue(chosenLatitude, forKey: "latitude")
        newPlace.setValue(chosenLongitude, forKey: "longitude")
        
        do {
            try context.save()
            print("success")
        }catch {
            print("error")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "newPlace"), object: nil)
        navigationController?.popViewController(animated: true)
    }
}
