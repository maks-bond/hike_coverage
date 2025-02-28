import SwiftUI
import MapKit

struct MapView: UIViewRepresentable {
    @Binding var hikes: [Hike]
    @Binding var currentHike: Hike
    @Binding var selectedHike: Hike?
    @Binding var userLocation: CLLocationCoordinate2D?
    
    private let mapView = MKMapView()
    @State private var hasCenteredOnUser = false  // Tracks whether we have zoomed in on the user
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .none  // Do not automatically follow the user
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)

        // ✅ Only center on user location once (on first load)
        if let location = userLocation, !hasCenteredOnUser {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
            uiView.setRegion(region, animated: true)
            hasCenteredOnUser = true  // ✅ Prevents re-centering on every update
        }

        // Draw saved routes
        for hike in hikes {
            var coords = hike.coordinates
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            if let selected = selectedHike, selected.id == hike.id {
                polyline.title = "selected"
                centerOnRoute(hike, in: uiView)
            }
            uiView.addOverlay(polyline)
        }

        // ✅ Ensure the current hike is displayed but does not change map focus
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

    private func centerOnRoute(_ hike: Hike, in mapView: MKMapView) {
        guard !hike.coordinates.isEmpty else { return }
        let polyline = MKPolyline(coordinates: hike.coordinates, count: hike.coordinates.count)
        let rect = polyline.boundingMapRect
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            
            // ✅ Ensure current hike is red, selected hike is green, and others are blue
            if let polyline = overlay as? MKPolyline {
                if polyline.title == "current" {
                    renderer.strokeColor = UIColor.red  // Recording route in red
                } else if polyline.title == "selected" {
                    renderer.strokeColor = UIColor.orange  // Selected hike in orange
                } else {
                    renderer.strokeColor = UIColor.blue  // Saved hikes in blue
                }
            }
            
            renderer.lineWidth = 3
            return renderer
        }
    }
}
