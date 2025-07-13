import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var hikes: [Hike]
    @Binding var currentHike: Hike
    @Binding var selectedHike: Hike?
    @Binding var userLocation: CLLocationCoordinate2D?
    @Binding var centerOnUser: Bool  // New binding to trigger centering
    
    private let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none
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

        // Center on user if requested
        if centerOnUser, let location = userLocation {
            let region = MKCoordinateRegion(
                center: location,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            uiView.setRegion(region, animated: true)
            centerOnUser = false  // Reset the trigger
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
