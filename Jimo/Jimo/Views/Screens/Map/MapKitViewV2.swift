//
//  MapKitViewV2.swift
//  Jimo
//
//  Created by Gautam Mekkat on 1/13/22.
//

import SwiftUI
import MapKit

struct MapKitViewV2: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedPin: MapPlace?
    
    var annotations: [PlaceAnnotation]
    
    var onLongPress: (CLLocationCoordinate2D) -> ()
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.addAnnotations(annotations)
        mapView.tintAdjustmentMode = .normal
        mapView.tintColor = .systemBlue
        mapView.showsUserLocation = true
        mapView.register(LocationAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.delegate = context.coordinator
        let longPressRecognizer = UILongPressGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.longPressGesture(sender:))
        )
        let tapRecognizer = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.tapGesture(sender:))
        )
        mapView.addGestureRecognizer(longPressRecognizer)
        mapView.addGestureRecognizer(tapRecognizer)
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        let viewAnnotations = Set(view.annotations.compactMap { $0 as? PlaceAnnotation })
        let currentAnnotations = Set(annotations)
        if let pin = selectedPin, let annotation = viewAnnotations.first(where: { $0.pin == pin }) {
            view.selectAnnotation(annotation, animated: true)
        }
        if view.region != region {
            view.setRegion(region, animated: true)
        }
        if !viewAnnotations.elementsEqual(currentAnnotations) {
            let toRemove = viewAnnotations.subtracting(currentAnnotations)
            let toAdd = currentAnnotations.subtracting(viewAnnotations)
            view.removeAnnotations(Array(toRemove))
            view.addAnnotations(Array(toAdd))
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        private let annotationScaleHelper = AnnotationScaleHelper()
        var parent: MapKitViewV2
        
        init(_ parent: MapKitViewV2) {
            self.parent = parent
        }
        
        @objc func tapGesture(sender: UITapGestureRecognizer) {
            hideKeyboard()
        }
        
        @objc func longPressGesture(sender: UITapGestureRecognizer) {
            guard let mapView = sender.view as? MKMapView, sender.state == .began else {
                return
            }
            let point = sender.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            // TODO: Add in future feature
            // parent.onLongPress(coordinate)
        }
        
        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            self.parent.region = mapView.region
            annotationScaleHelper.updateScales(for: mapView, selectedPinId: parent.selectedPin?.id)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? PlaceAnnotation else {
                return nil
            }
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
            
            if view == nil {
                view = LocationAnnotationView(
                    annotation: annotation,
                    reuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
            }
            view?.annotation = annotation
            view?.zPriority = MKAnnotationViewZPriority(rawValue: MKAnnotationViewZPriority.RawValue(annotation.zIndex))
            view?.transform = self.annotationScaleHelper.transform
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            if let annotation = view.annotation as? PlaceAnnotation {
                DispatchQueue.main.async {
                    self.parent.selectedPin = annotation.pin
                }
                UIView.animate(withDuration: 0.2) {
                    view.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
                }
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            UIView.animate(withDuration: 0.2) {
                view.transform = self.annotationScaleHelper.transform
            }
            DispatchQueue.main.async {
                self.parent.selectedPin = nil
            }
        }
    }
}

fileprivate class AnnotationScaleHelper {
    var scale: AnnotationScale = .regular
    
    var transform: CGAffineTransform {
        CGAffineTransform(scaleX: scale.rawValue, y: scale.rawValue)
    }
    
    func updateScales(for mapView: MKMapView, selectedPinId: PlaceId?) {
        let newScale = getScale(for: mapView.region)
        guard self.scale != newScale else {
            return
        }
        self.scale = newScale
        var annotations = mapView.annotations.compactMap({ $0 as? PlaceAnnotation })
        if let selectedPinId = selectedPinId {
            annotations = annotations.filter({ $0.place.id != selectedPinId })
        }
        let annotationViews = annotations.map({ mapView.view(for: $0) })
        UIView.animate(withDuration: 0.2) {
            for view in annotationViews {
                view?.transform = self.transform
            }
        }
    }
    
    private func getScale(for region: MKCoordinateRegion) -> AnnotationScale {
        if region.span.longitudeDelta > 5 {
            return .small
        }
        return .regular
    }
    
    enum AnnotationScale: CGFloat {
        case small = 0.75, regular = 1
    }
}
