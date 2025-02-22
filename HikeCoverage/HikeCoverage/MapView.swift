import SwiftUI
import MapKit

// A UIViewRepresentable that wraps an MKMapView.
// It displays saved hikes, the current hike in progress, and highlights a selected route.
struct MapView: UIViewRepresentable {
    @Binding var hikes: [Hike]
    @Binding var currentHike: Hike
    @Binding var selectedHike: Hike?
    
    private let mapView = MKMapView()
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        
        // Set a default region (example: San Francisco)
        let defaultCoordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let region = MKCoordinateRegion(center: defaultCoordinate,
                                        latitudinalMeters: 10000,
                                        longitudinalMeters: 10000)
        mapView.setRegion(region, animated: false)
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove existing overlays.
        uiView.removeOverlays(uiView.overlays)
        
        // Draw all saved hikes.
        for hike in hikes {
            var coords = hike.coordinates
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            // If this hike is selected, highlight it.
            if let selected = selectedHike, selected.id == hike.id {
                polyline.title = "selected"
            }
            uiView.addOverlay(polyline)
        }
        
        // Draw the current hike in progress.
        if !currentHike.coordinates.isEmpty {
            var coords = currentHike.coordinates
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            polyline.title = "current"
            uiView.addOverlay(polyline)
            
            // Update the region to center on the last coordinate.
            if let lastCoord = currentHike.coordinates.last {
                let region = MKCoordinateRegion(center: lastCoord,
                                                latitudinalMeters: 500,
                                                longitudinalMeters: 500)
                uiView.setRegion(region, animated: true)
            }
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
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                if polyline.title == "current" {
                    renderer.strokeColor = UIColor.red
                    renderer.lineWidth = 4
                } else if polyline.title == "selected" {
                    renderer.strokeColor = UIColor.green
                    renderer.lineWidth = 5
                } else {
                    renderer.strokeColor = UIColor.blue
                    renderer.lineWidth = 3
                }
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}
