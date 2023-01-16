//
//  JimoMapView.swift
//  Jimo
//
//  Created by Gautam Mekkat on 7/9/22.
//

import SwiftUI
import MapKit
import Collections


struct JimoMapView: UIViewRepresentable {
    @ObservedObject var mapViewModel: MapViewModel
    
    var tappedPin: (MKJimoPinAnnotation?) -> ()
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsCompass = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.addAnnotations(mapViewModel.pins)
        mapView.tintAdjustmentMode = .normal
        mapView.tintColor = .systemBlue
        mapView.showsUserLocation = true
        mapView.register(JimoPinView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(JimoPinView.self))
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Handle region, don't change if the region is already changing
        if !context.coordinator.isRegionChanging && mapView.region != mapViewModel._mkCoordinateRegion {
            mapView.setRegion(mapViewModel._mkCoordinateRegion, animated: true)
        }
        
        // Handle pins
        let annotations = Set(mapViewModel.pins)
        let uiViewAnnotations = Set(mapView.annotations.compactMap({ $0 as? MKJimoPinAnnotation }))
        let toAdd = annotations.subtracting(uiViewAnnotations)
        let toRemove = uiViewAnnotations.subtracting(annotations)
        if toAdd.count > 0 {
            mapView.addAnnotations(Array(toAdd))
        }
        if toRemove.count > 0 {
            mapView.removeAnnotations(Array(toRemove))
        }
        
        // Handle selectedPin
        let uiViewSelectedAnnotation = mapView.selectedAnnotations.first as? MKJimoPinAnnotation
        if mapViewModel.selectedPin != uiViewSelectedAnnotation {
            if let selectedPin = mapViewModel.selectedPin,
               let pin = mapView.annotations.first(where: { $0 as? MKJimoPinAnnotation == selectedPin }) {
                // We need to reference the object in the map view (even though equality is properly implemented)
                // Assuming this is because MapKit is in Objective C and doing some pointer bs
                mapView.selectAnnotation(pin, animated: true)
            } else if let uiViewSelectedAnnotation = uiViewSelectedAnnotation {
                mapView.deselectAnnotation(uiViewSelectedAnnotation, animated: true)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        private var parent: JimoMapView
        private var regularPinsCapacity: Int = 25
        private var isRecomputingDots = false
        private(set) var isRegionChanging = false
        
        init(_ parent: JimoMapView) {
            self.parent = parent
        }
        
        var mapViewModel: MapViewModel {
            parent.mapViewModel
        }
        
        func recomputeDots(_ mapView: MKMapView) {
            guard mapView.selectedAnnotations.isEmpty else {
                return
            }
            let annotations = mapView.annotations(in: mapView.visibleMapRect)
            DispatchQueue.global(qos: .userInitiated).async {
                let annotations: [MKJimoPinAnnotation] = annotations
                    .compactMap({ $0 as? MKJimoPinAnnotation })
                    .sorted(by: { compare($0, isLargerThan: $1) })
                DispatchQueue.main.async {
                    UIView.animate(withDuration: 0.25) {
                        for (i, annotation) in annotations.enumerated() {
                            if i < self.regularPinsCapacity {
                                mapView.pinView(for: annotation)?.toPin()
                            } else {
                                mapView.pinView(for: annotation)?.toDot()
                            }
                        }
                    }
                }
            }
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.mapViewModel._mkCoordinateRegion = mapView.region
                if self.isRecomputingDots {
                    return
                }
                self.isRecomputingDots = true
                self.recomputeDots(mapView)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.isRecomputingDots = false
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isRegionChanging = true
        }
        
        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            isRegionChanging = false
            // Does not need to be on main because it's not a published var
            self.mapViewModel.visibleMapRect = mapView.rectangularRegion()
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Alter the MKUserLocationView (iOS 14+)
            if #available(iOS 14.0, *), annotation is MKUserLocation {
                let reuse = NSStringFromClass(MKUserLocationView.self)
                if let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuse) {
                    return view
                }
                let view = MKUserLocationView(annotation: annotation, reuseIdentifier: reuse)
                
                view.zPriority = .max  // Show user location above other annotations
                view.isEnabled = false // Ignore touch events and do not show callout
                return view
            }
            if let annotation = annotation as? MKJimoPinAnnotation {
                let view = mapView.dequeueReusableAnnotationView(
                    withIdentifier: NSStringFromClass(JimoPinView.self),
                    for: annotation
                ) as? JimoPinView
                view?.toDot()
                return view
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            self.recomputeDots(mapView)
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            DispatchQueue.main.async {
                if let annotation = view.annotation as? MKJimoPinAnnotation {
                    print("Called tappedPin from didSelect")
                    self.parent.tappedPin(annotation)
                    UIView.animate(withDuration: 0.1) {
                        self.highlight(view, annotation: annotation)
                        for pin in mapView.annotations {
                            if let pin = pin as? MKJimoPinAnnotation, pin != annotation {
                                mapView.pinView(for: pin)?.toDot()
                            }
                        }
                    }
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            DispatchQueue.main.async {
                guard let annotation = view.annotation as? MKJimoPinAnnotation else {
                    return
                }
                if self.mapViewModel.selectedPin == annotation {
                    print("Called tappedPin(nil) from didDeselect")
                    self.parent.tappedPin(nil)
                }
                UIView.animate(withDuration: 0.1) {
                    self.removeHighlight(for: view)
                }
                self.recomputeDots(mapView)
            }
        }
        
        private func highlight(_ view: MKAnnotationView, annotation: MKJimoPinAnnotation) {
            (view as? JimoPinView)?.toPin()
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            view.layer.shadowOffset = .zero
            if let category = annotation.category, let color = UIColor(named: category) {
                view.layer.shadowColor = color.cgColor
                view.layer.shadowRadius = 20
                view.layer.shadowOpacity = 0.75
                view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
            }
        }
        
        private func removeHighlight(for view: MKAnnotationView) {
            view.transform = .identity
            view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
            view.layer.shadowRadius = 0
            view.layer.shadowColor = nil
            view.layer.shadowPath = nil
        }
    }
}

fileprivate extension MKMapView {
    var pinAnnotations: [MKJimoPinAnnotation] {
        annotations.compactMap { $0 as? MKJimoPinAnnotation }
    }
    
    func pinView(for annotation: MKJimoPinAnnotation) -> JimoPinView? {
        return self.view(for: annotation) as? JimoPinView
    }
    
    func scaleVisibleMapRect(scale s: Double) -> MKMapRect {
        let p = (1.0 - s) / 2.0
        let origin = MKMapPoint(
            x: visibleMapRect.origin.x + visibleMapRect.size.width * p,
            y: visibleMapRect.origin.y + visibleMapRect.size.height * p
        )
        return MKMapRect(
            origin: origin,
            size: MKMapSize(width: visibleMapRect.size.width * s, height: visibleMapRect.size.height * s)
        )
    }
}

fileprivate extension RandomAccessCollection {
    func binarySearchFirstIndex(where predicate: (Iterator.Element) -> Bool) -> Index {
        var low = startIndex
        var high = endIndex
        while low != high {
            let mid = index(low, offsetBy: distance(from: low, to: high)/2)
            if !predicate(self[mid]) {
                low = index(after: mid)
            } else {
                high = mid
            }
        }
        return low
    }
}

fileprivate extension OrderedSet {
    func firstN(_ n: Int) -> Set<Iterator.Element> {
        if count > n {
            return Set(self[0..<n])
        }
        return Set(self)
    }
    
    mutating func insertFirstWhere(_ element: Iterator.Element, predicate: (Iterator.Element) -> Bool) {
        let index = self.binarySearchFirstIndex(where: predicate)
        if index < self.count {
            self.insert(element, at: index)
        } else {
            self.append(element)
        }
    }
}

fileprivate func compare(_ annotation: MKJimoPinAnnotation, isLargerThan annotation2: MKJimoPinAnnotation) -> Bool {
    return annotation.numPosts > annotation2.numPosts || (annotation.numPosts == annotation2.numPosts && annotation.placeId ?? "" > annotation2.placeId ?? "")
}
