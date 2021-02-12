//
//  MapViewController.swift
//  ImagesClassifier
//
//  Created by Egor Malyshev on 12.02.2021.
//  Copyright © 2021 Artem Makaroff. All rights reserved.
//

import UIKit
import MapKit
import Vision

class MapViewController: UIViewController, UIGestureRecognizerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var squareLabel: UILabel!
    @IBOutlet weak var roomsCountLabel: UILabel!
    @IBOutlet weak var floorLabel: UILabel!
    @IBOutlet weak var areaSlider: UISlider!
    @IBOutlet weak var roomsCountSlider: UISlider!
    @IBOutlet weak var floorSlider: UISlider!
    
    let spbCenterCoordinate = CLLocationCoordinate2D(latitude: 59.933486, longitude: 30.346385)
    lazy var currentCoordinate = CLLocationCoordinate2D()
    var coordinateIsSet = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let rad: CLLocationDistance = 20000
        let reg = MKCoordinateRegion(center: spbCenterCoordinate, latitudinalMeters: rad, longitudinalMeters: rad)
        mapView.isScrollEnabled = false
        mapView.isZoomEnabled = false
        mapView.setRegion(reg, animated: false)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(mapTapped))
        tapGesture.delegate = self
        mapView.addGestureRecognizer(tapGesture)
    }
    
    @IBAction func squareChanged(_ sender: UISlider) {
        squareLabel.text = "Площадь: \(Int(sender.value))"
        if coordinateIsSet {
            countPrice(coordinate: self.currentCoordinate)
        }
    }
    
    @IBAction func roomsCountChanged(_ sender: UISlider) {
        roomsCountLabel.text = "Количество комнат: \(Int(sender.value))"
        if coordinateIsSet {
            countPrice(coordinate: self.currentCoordinate)
        }
    }
    
    @IBAction func floorChanged(_ sender: UISlider) {
        floorLabel.text = "Этаж: \(Int(sender.value))"
        if coordinateIsSet {
            countPrice(coordinate: self.currentCoordinate)
        }
    }
    
    @objc func mapTapped(_ gesture: UITapGestureRecognizer) {
        coordinateIsSet = true
        let location = gesture.location(in: mapView)
        let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
        self.currentCoordinate = coordinate
        for annotation in mapView.annotations{
            mapView.removeAnnotation(annotation)
        }
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        countPrice(coordinate: coordinate)
    }
    
    func countPrice(coordinate: CLLocationCoordinate2D) {
        let config = MLModelConfiguration()
        let tabularRegressor = try? MyTabularRegressor(configuration: config)
        
        let area = Double(areaSlider.value)
        let floor = Double(floorSlider.value)
        let rooms = Double(roomsCountSlider.value)
        let latitude = coordinate.latitude
        let longitude = coordinate.longitude
        
        guard let model = tabularRegressor,
              area != 0,
              floor != 0,
              rooms != 0
        else {
            priceLabel.text = "0 ₽"
            return
        }
        
        let prediction = try? model.prediction(
            Area: area,
            Floor: floor,
            Rooms: rooms,
            Latitude: latitude,
            Longitude: longitude)
        
        let price = prediction?.Price
        priceLabel.text = "\(Int(price ?? 0).formattedWithSeparator) ₽"
    }
}

extension Formatter {
    static let withSeparator: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.groupingSeparator = " "
        formatter.numberStyle = .decimal
        return formatter
    }()
}

extension BinaryInteger {
    var formattedWithSeparator: String {
        return Formatter.withSeparator.string(for: self) ?? ""
    }
}
