# Annotating a Map with Custom Data

Annotate a map with location-specific data using default and customized annotation views and callouts.

## Overview

This sample code project demonstrates how to display a map with custom annotations, each with a customized callout provided by its [`MKAnnotationView`][1]. In addition, the Map Callouts sample project shows how you can extend annotations with custom views, strings, and callout accessory views using [`MKAnnotation`][2] and [`MKAnnotationView`][1].

[1]:https://developer.apple.com/documentation/mapkit/mkannotationview
[2]:https://developer.apple.com/documentation/mapkit/mkannotation

## Provide an Annotation

Annotations offer a way to highlight specific coordinates on a map and provide additional information. You can use annotations to call out addresses, points of interest, and particular destinations.

To display an annotation on a map, your app must provide two distinct objects: an annotation object and an annotation view.

An annotation object conforms to the `MKAnnotation` protocol and manages the data for the annotation, such as the [`coordinate`][3], [`title`][4], and [`subtitle`][5] properties as shown in this section of the sample code.

``` swift
class SanFranciscoAnnotation: NSObject, MKAnnotation {
    
    // This property must be key-value observable, which the `@objc dynamic` attributes provide.
    @objc dynamic var coordinate = CLLocationCoordinate2D(latitude: 37.779_379, longitude: -122.418_433)
    
    // Required if you set the annotation view's `canShowCallout` property to `true`
    var title: String? = NSLocalizedString("SAN_FRANCISCO_TITLE", comment: "SF annotation")
    
    // This property defined by `MKAnnotation` is not required.
    var subtitle: String? = NSLocalizedString("SAN_FRANCISCO_SUBTITLE", comment: "SF annotation")
}
```
[View in Source](x-source-tag://AnnotationExample)

Derived from the `MKAnnotationView` class, an annotation view draws the visual representation of the annotation on the map surface. Register annotation views with the `MKMapView` so the map view can create and efficiently reuse them. Use a default annotation view if you need to customize the content with  a callout, or change the default marker. Use a custom annotation view if you want to have a completely custom view appear for the annotation.

``` swift
private func registerMapAnnotationViews() {
    mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(BridgeAnnotation.self))
    mapView.register(CustomAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(CustomAnnotation.self))
    mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(SanFranciscoAnnotation.self))
    mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: NSStringFromClass(FerryBuildingAnnotation.self))
}
```
[View in Source](x-source-tag://RegisterAnnotationViews)

When an annotation comes into view, the map view asks the [`MKMapDelegate`][6] to provide the appropriate annotation view.

``` swift
func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    
    guard !annotation.isKind(of: MKUserLocation.self) else {
        // Make a fast exit if the annotation is the `MKUserLocation`, as it's not an annotation view we wish to customize.
        return nil
    }
    
    var annotationView: MKAnnotationView?
    
    if let annotation = annotation as? BridgeAnnotation {
        annotationView = setupBridgeAnnotationView(for: annotation, on: mapView)
    } else if let annotation = annotation as? CustomAnnotation {
        annotationView = setupCustomAnnotationView(for: annotation, on: mapView)
    } else if let annotation = annotation as? SanFranciscoAnnotation {
        annotationView = setupSanFranciscoAnnotationView(for: annotation, on: mapView)
    } else if let annotation = annotation as? FerryBuildingAnnotation {
        annotationView = setupFerryBuildingAnnotationView(for: annotation, on: mapView)
    }
    
    return annotationView
}
```
[View in Source](x-source-tag://CreateAnnotationViews)

Before returning from the delegate call providing the annotation view, you configure the annotation view with any customizations required for the annotation. For example, use a flag icon for an annotation view representing San Francisco.

``` swift
private func setupSanFranciscoAnnotationView(for annotation: SanFranciscoAnnotation, on mapView: MKMapView) -> MKAnnotationView {
    let reuseIdentifier = NSStringFromClass(SanFranciscoAnnotation.self)
    let flagAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier, for: annotation)
    
    flagAnnotationView.canShowCallout = true
    
    // Provide the annotation view's image.
    let image = #imageLiteral(resourceName: "flag")
    flagAnnotationView.image = image
    
    // Provide the left image icon for the annotation.
    flagAnnotationView.leftCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "sf_icon"))
    
    // Offset the flag annotation so that the flag pole rests on the map coordinate.
    let offset = CGPoint(x: image.size.width / 2, y: -(image.size.height / 2) )
    flagAnnotationView.centerOffset = offset
    
    return flagAnnotationView
}
```
[View in Source](x-source-tag://ConfigureAnnotationViews)

[3]:https://developer.apple.com/documentation/mapkit/mkannotation/1429524-coordinate
[4]:https://developer.apple.com/documentation/mapkit/mkannotation/1429522-title
[5]:https://developer.apple.com/documentation/mapkit/mkannotation/1429520-subtitle
[6]:https://developer.apple.com/documentation/mapkit/mkmapviewdelegate

## Create Callouts

A callout is a standard or custom view that can appear with an annotation view. A standard callout displays the annotation’s title, and it can display additional content such as a subtitle, images, and a control.

A callout can be customized in multiple ways. To place a disclosure button inside a callout:

``` swift
let rightButton = UIButton(type: .detailDisclosure)
markerAnnotationView.rightCalloutAccessoryView = rightButton
```
[View in Source](x-source-tag://CalloutButton)

When the disclosure button is tapped, MapKit calls [`mapView(_:annotationView:calloutAccessoryControlTapped:)`][7] for the app to handle the tap event.

[7]:https://developer.apple.com/documentation/mapkit/mkmapviewdelegate/1616211-mapview

Callouts can also include images, such as the [`detailCalloutAccessoryView`][8]:

``` swift
// Provide an image view to use as the accessory view's detail view.
markerAnnotationView.detailCalloutAccessoryView = UIImageView(image: #imageLiteral(resourceName: "ferry_building"))
```
[View in Source](x-source-tag://CalloutImage)
 
[8]:https://developer.apple.com/documentation/mapkit/mkannotationview/1452543-detailcalloutaccessoryview
