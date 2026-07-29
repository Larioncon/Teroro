import SwiftUI
import MapKit

// UIViewRepresentable for MKMapView to detect region change start/end accurately
struct MapViewRepresentable: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var isMoving: Bool
    @Binding var hasCenteredOnUser: Bool
    var mapType: MKMapType

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
        mapView.mapType = mapType
        mapView.showsCompass = false
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if uiView.mapType != mapType {
            uiView.mapType = mapType
        }
        if !hasCenteredOnUser && (region.center.latitude != 50.4501 || region.center.longitude != 30.5234) {
            uiView.setRegion(region, animated: true)
            DispatchQueue.main.async {
                self.hasCenteredOnUser = true
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        private var debounceTimer: Timer?
        private var isInitialCenterDone = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard let location = userLocation.location, !isInitialCenterDone else { return }
            isInitialCenterDone = true
            let newRegion = MKCoordinateRegion(
                center: location.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
            )
            mapView.setRegion(newRegion, animated: true)
            DispatchQueue.main.async {
                self.parent.region = newRegion
                self.parent.hasCenteredOnUser = true
            }
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            DispatchQueue.main.async {
                self.parent.isMoving = true
            }
        }

        func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
            DispatchQueue.main.async {
                self.parent.isMoving = true
            }
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            debounceTimer?.invalidate()
            debounceTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    self.parent.isMoving = false
                    self.parent.region = mapView.region
                }
            }
        }
    }
}
