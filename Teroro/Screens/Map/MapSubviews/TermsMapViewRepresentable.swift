import SwiftUI
import MapKit

// MARK: - UIViewRepresentable for MKMapView
struct TermsMapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let items: [TermMapItem]
    var mapType: MKMapType

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        mapView.showsCompass = true
        mapView.mapType = mapType
        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        if mapView.mapType != mapType {
            mapView.mapType = mapType
        }

        // Sync region if changed programmatically outside user scroll
        if !context.coordinator.isUserInteracting {
            let latDiff = abs(mapView.region.center.latitude - region.center.latitude)
            let lonDiff = abs(mapView.region.center.longitude - region.center.longitude)
            if latDiff > 0.001 || lonDiff > 0.001 {
                mapView.setRegion(region, animated: true)
            }
        }

        // Sync annotations
        let currentAnnotations = mapView.annotations.compactMap { $0 as? TermAnnotation }
        let currentIDs = Set(currentAnnotations.map { $0.item.id })
        let newIDs = Set(items.map { $0.id })

        if currentIDs != newIDs {
            mapView.removeAnnotations(currentAnnotations)
            let newAnnotations = items.map { TermAnnotation(item: $0) }
            mapView.addAnnotations(newAnnotations)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: TermsMapViewRepresentable
        var isUserInteracting = false

        init(_ parent: TermsMapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil // System default user location blue dot
            }

            guard let termAnnotation = annotation as? TermAnnotation else {
                return nil
            }

            let identifier = "TermAnnotationView"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: termAnnotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                annotationView?.markerTintColor = .systemRed
                annotationView?.glyphImage = UIImage(systemName: "mappin.and.ellipse")
            } else {
                annotationView?.annotation = termAnnotation
            }

            return annotationView
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            isUserInteracting = true
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.region = mapView.region
                self.isUserInteracting = false
            }
        }
    }
}

class TermAnnotation: NSObject, MKAnnotation {
    let item: TermMapItem
    var coordinate: CLLocationCoordinate2D { item.coordinate }
    var title: String? { item.title }
    var subtitle: String? { item.subtitle }

    init(item: TermMapItem) {
        self.item = item
    }
}
