import SwiftUI
import MapKit

// UIViewRepresentable to wrap MKMapView for advanced overlays.
struct MapView: UIViewRepresentable {
    @Binding var hikes: [Hike]
    @Binding var currentHike: Hike
    
    private let mapView = MKMapView()
    
    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // Remove existing overlays.
        uiView.removeOverlays(uiView.overlays)
        
        // Add overlays for saved hikes.
        for hike in hikes {
            var coords = hike.coordinates
            let polyline = MKPolyline(coordinates: &coords, count: coords.count)
            uiView.addOverlay(polyline)
        }
        
        // Add overlay for the current hike in progress.
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
    
    // Coordinator to handle MKMapViewDelegate callbacks.
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
                    renderer.lineWidth = 3
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
