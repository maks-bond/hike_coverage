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
        
        // Center the map on user location when the app first opens
        if let location = userLocation, !hasCenteredOnUser {
            let region = MKCoordinateRegion(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
            uiView.setRegion(region, animated: true)
            hasCenteredOnUser = true  // Prevents re-centering every update
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
            renderer.strokeColor = overlay.title == "selected" ? UIColor.green : UIColor.blue
            renderer.lineWidth = 3
            return renderer
        }
    }
}
