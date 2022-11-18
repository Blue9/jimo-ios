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
    @Binding var pins: [MKJimoPinAnnotation]
    @Binding var selectedPin: MKJimoPinAnnotation?

    // RegionWrapper allows us to set the region binding without updating the view
    @ObservedObject var regionWrapper: RegionWrapper
    var selectPin: (MKJimoPinAnnotation) -> ()
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsCompass = false
        mapView.pointOfInterestFilter = .excludingAll
        mapView.addAnnotations(pins)
        mapView.tintAdjustmentMode = .normal
        mapView.tintColor = .systemBlue
        mapView.showsUserLocation = true
        mapView.register(JimoPinView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(JimoPinView.self))
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Handle region
        if mapView.region != regionWrapper.region.wrappedValue {
            mapView.setRegion(regionWrapper.region.wrappedValue, animated: true)
        }
        
        // Handle pins
        let annotations = Set(pins)
        let uiViewAnnotations = Set(mapView.annotations.compactMap({ $0 as? MKJimoPinAnnotation }))
        let toAdd = annotations.subtracting(uiViewAnnotations)
        let toRemove = uiViewAnnotations.subtracting(annotations)
        if toAdd.count > 0 {
            mapView.addAnnotations(Array(toAdd))
        }
        if toRemove.count > 0 {
            // TODO: should remove from sortedVisibleAnnotations as well
            mapView.removeAnnotations(Array(toRemove))
        }
        
        // Handle selectedPin
        let uiViewSelectedAnnotation = mapView.selectedAnnotations.first as? MKJimoPinAnnotation
        if selectedPin != uiViewSelectedAnnotation {
            if let selectedPin = selectedPin {
                mapView.selectAnnotation(selectedPin, animated: true)
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
        private var sortedVisibleAnnotations: OrderedSet<MKJimoPinAnnotation> = OrderedSet()
        private var regularPinsCapacity: Int = 25
        private var isRecomputingDots = false
        
        init(_ parent: JimoMapView) {
            self.parent = parent
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.regionWrapper._region = mapView.region
            }
            if isRecomputingDots {
                return
            }
            isRecomputingDots = true
            let newVisibleAnnotations = Set(mapView.annotations(in: mapView.scaleVisibleMapRect(scale: 0.8)).compactMap({ $0 as? MKJimoPinAnnotation }))
            let changedToVisible = newVisibleAnnotations.subtracting(sortedVisibleAnnotations)
            let changedToHidden = sortedVisibleAnnotations.subtracting(newVisibleAnnotations)
            let oldRegularPins = sortedVisibleAnnotations.firstN(regularPinsCapacity)
            for annotation in changedToHidden {
                sortedVisibleAnnotations.remove(annotation)
            }
            for annotation in changedToVisible {
                sortedVisibleAnnotations.insertFirstWhere(annotation, predicate: { compare(annotation, isLargerThan: $0) })
            }
            var newRegularPins = sortedVisibleAnnotations.firstN(regularPinsCapacity)
            if let selectedPin = parent.selectedPin {
                newRegularPins.insert(selectedPin)
            }
            UIView.animate(withDuration: 0.25) {
                newRegularPins.subtracting(oldRegularPins).forEach({ mapView.pinView(for: $0)?.toPin() })
                oldRegularPins.subtracting(newRegularPins).forEach({ mapView.pinView(for: $0)?.toDot() })
            } completion: { _ in
                /// Add delay to give the CPU some breathing room
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.isRecomputingDots = false
                }
            }
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
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: NSStringFromClass(JimoPinView.self), for: annotation) as? JimoPinView
                if !sortedVisibleAnnotations.firstN(regularPinsCapacity).contains(annotation) {
                    view?.toDot()
                }
                return view
            }
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
            self.isRecomputingDots = true
            let oldRegularPins = sortedVisibleAnnotations.firstN(regularPinsCapacity)
            for view in views.compactMap({ $0 as? JimoPinView }) {
                guard let annotation = view.annotation as? MKJimoPinAnnotation else {
                    return
                }
                sortedVisibleAnnotations.insertFirstWhere(annotation, predicate: { compare(annotation, isLargerThan: $0) })
            }
            let newRegularPins = sortedVisibleAnnotations.firstN(regularPinsCapacity)
            
            // TODO: this can probably be moved to a function
            UIView.animate(withDuration: 0.25) {
                newRegularPins.subtracting(oldRegularPins).forEach({ mapView.pinView(for: $0)?.toPin() })
                oldRegularPins.subtracting(newRegularPins).forEach({ mapView.pinView(for: $0)?.toDot() })
            } completion: { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    self.isRecomputingDots = false
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? MKJimoPinAnnotation {
                parent.selectPin(annotation)
                UIView.animate(withDuration: 0.1) {
                    self.highlight(view, annotation: annotation)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            guard let annotation = view.annotation as? MKJimoPinAnnotation else {
                return
            }
            if parent.selectedPin == annotation {
                parent.selectedPin = nil
            }
            // We don't set parent.selectedPin to nil here, that is only done when the quick view is dismissed
            // (that ensures that if selectedPin is non-nil, then the quick view is visible)
            UIView.animate(withDuration: 0.1) {
                if !self.sortedVisibleAnnotations.firstN(self.regularPinsCapacity).contains(annotation) {
                    (view as? JimoPinView)?.toDot()
                } else {
                    view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
                self.removeHighlight(for: view)
            }
        }
        
        private func highlight(_ view: MKAnnotationView, annotation: MKJimoPinAnnotation) {
            (view as? JimoPinView)?.toPin()
            view.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            view.layer.shadowOffset = .zero
            if let category = annotation.category, let color = UIColor(named: category) {
                view.layer.shadowColor = color.cgColor
            }
            view.layer.shadowRadius = 20
            view.layer.shadowOpacity = 0.75
            view.layer.shadowPath = UIBezierPath(rect: view.bounds).cgPath
        }
        
        private func removeHighlight(for view: MKAnnotationView) {
            if let annotation = view.annotation as? MKJimoPinAnnotation {
                if !sortedVisibleAnnotations.firstN(regularPinsCapacity).contains(annotation) {
                    (view as? JimoPinView)?.toDot()
                } else {
                    view.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                }
            }
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
    return annotation.numPosts > annotation2.numPosts || (annotation.numPosts == annotation2.numPosts && annotation.placeId! > annotation2.placeId!)
}
