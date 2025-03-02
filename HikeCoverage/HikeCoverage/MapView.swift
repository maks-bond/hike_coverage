import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var hikes: [Hike]
    @Binding var currentHike: Hike
    @Binding var selectedHike: Hike?
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var shouldFollowUser: Bool  // New binding to track whether the map should follow

    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none

        // ✅ Detect when the user manually moves the map
        let panGesture = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleMapDrag(_:)))
        mapView.addGestureRecognizer(panGesture)

        return mapView
    }

    private func centerOnSelectedHike(_ hike: Hike, in mapView: MKMapView) {
        guard !hike.coordinates.isEmpty else { return }
        let polyline = MKPolyline(coordinates: hike.coordinates, count: hike.coordinates.count)
        let rect = polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)

        if let location = userLocation, shouldFollowUser {
            let currentRegion = uiView.region
            let newRegion = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)

            // ✅ Only update if the user has NOT moved the map
            if abs(currentRegion.center.latitude - newRegion.center.latitude) > 0.0005 ||
               abs(currentRegion.center.longitude - newRegion.center.longitude) > 0.0005 {
                uiView.setRegion(newRegion, animated: true)
            }
        }

        for hike in hikes {
            var coords = hike.coordinates
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            if let selected = selectedHike, selected.id == hike.id {
                polyline.title = "selected"
                centerOnSelectedHike(hike, in: uiView)
            }
            uiView.addOverlay(polyline)
        }

        if !currentHike.coordinates.isEmpty {
            var coords = currentHike.coordinates
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            polyline.title = "current"
            uiView.addOverlay(polyline)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        @objc func handleMapDrag(_ gesture: UIPanGestureRecognizer) {
            if gesture.state == .began {
                DispatchQueue.main.async {
                    self.parent.shouldFollowUser = false  // ✅ Stop auto-following when user moves map
                }
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            if let polyline = overlay as? MKPolyline {
                if polyline.title == "current" {
                    renderer.strokeColor = UIColor.red
                } else if polyline.title == "selected" {
                    renderer.strokeColor = UIColor.orange
                } else {
                    renderer.strokeColor = UIColor.blue
                }
            }
            renderer.lineWidth = 3
            return renderer
        }
    }
}
