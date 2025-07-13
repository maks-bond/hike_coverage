import argparse
import boto3
import gpxpy
import gpxpy.gpx
import os
from datetime import datetime, timezone, timedelta
from haversine import haversine, Unit

def calculate_point_time(point1, point2, speed_mph=3.5):
    """Calculate time needed to walk between two points at given speed."""
    if point1 is None or point2 is None:
        return timedelta(minutes=1)  # Default 1 minute if can't calculate
    
    # Calculate distance between points in miles
    distance = haversine(point1, point2, unit=Unit.MILES)
    
    # Calculate time in hours: distance / speed
    hours = distance / speed_mph
    
    # Convert to timedelta
    return timedelta(hours=hours)

def create_gpx_file(coordinates, start_time):
    """Creates a GPX file from coordinates."""
    gpx = gpxpy.gpx.GPX()
    gpx.creator = "HikeCoverage Exporter"
    
    # Create track
    gpx_track = gpxpy.gpx.GPXTrack()
    gpx.tracks.append(gpx_track)
    
    # Create segment
    gpx_segment = gpxpy.gpx.GPXTrackSegment()
    gpx_track.segments.append(gpx_segment)
    
    # Convert coordinates to points with timestamps
    valid_points = []
    current_time = start_time
    last_point = None
    
    # First pass: collect valid points
    for coord in coordinates:
        if not coord:
            continue
        try:
            lat, lon = map(float, coord.split(','))
            valid_points.append((lat, lon))
        except ValueError:
            print(f"Warning: Skipping invalid coordinate: {coord}")
            continue
    
    # Second pass: create GPX points with timestamps
    for i, (lat, lon) in enumerate(valid_points):
        point = gpxpy.gpx.GPXTrackPoint(lat, lon, time=current_time)
        gpx_segment.points.append(point)
        
        # Calculate time to next point
        if i < len(valid_points) - 1:
            next_point = valid_points[i + 1]
            time_to_next = calculate_point_time((lat, lon), next_point)
            current_time += time_to_next
    
    return gpx

def calculate_distance_miles(coordinates):
    """Calculates the total distance in miles."""
    try:
        points = []
        for coord in coordinates:
            if not coord:  # Skip empty coordinates
                continue
            try:
                lat, lon = map(float, coord.split(','))
                points.append((lat, lon))
            except ValueError:
                print(f"Warning: Skipping invalid coordinate: {coord}")
                continue
        
        if len(points) < 2:
            return 0.0
            
        distance = 0.0
        for i in range(len(points) - 1):
            distance += haversine(points[i], points[i+1], unit=Unit.MILES)
        return distance
    except Exception as e:
        print(f"Error calculating distance: {e}")
        return 0.0

def main():
    parser = argparse.ArgumentParser(description="Download hikes from DynamoDB and convert to GPX files.")
    parser.add_argument("user_name", help="The user name to download hikes for.")
    parser.add_argument("--region", default="us-east-2", help="AWS region")
    parser.add_argument("--table-name", default="hikes", help="DynamoDB table name")
    parser.add_argument("--profile", help="AWS profile name", default=None)
    args = parser.parse_args()

    # Create output directory
    output_dir = os.path.join(os.path.dirname(__file__), "exported_gpx")
    os.makedirs(output_dir, exist_ok=True)

    # Connect to DynamoDB
    session = boto3.Session(profile_name=args.profile, region_name=args.region)
    dynamodb = session.resource('dynamodb')
    table = dynamodb.Table(args.table_name)

    # Query hikes for the user
    response = table.scan(
        FilterExpression='user_uuid = :user_id',
        ExpressionAttributeValues={':user_id': args.user_name}
    )

    print(f"Found {len(response['Items'])} hikes")

    for hike in response['Items']:
        try:
            # Parse coordinates
            if 'location' not in hike:
                print(f"Warning: Skipping hike with no location data (ID: {hike.get('hike_id', 'unknown')})")
                continue
                
            coordinates = [coord for coord in hike['location'].split(';') if coord.strip()]
            
            if not coordinates:
                print(f"Warning: Skipping hike with empty coordinates (ID: {hike.get('hike_id', 'unknown')})")
                continue
            
            # Calculate distance in miles
            distance_miles = calculate_distance_miles(coordinates)
            
            if distance_miles == 0:
                print(f"Warning: Skipping hike with zero distance (ID: {hike.get('hike_id', 'unknown')})")
                continue
            
            # Create timestamp
            start_time = datetime.fromtimestamp(float(hike['start_time']), tz=timezone.utc)
            date_str = start_time.strftime('%Y-%m-%d')
            
            # Generate filename
            filename = f"Hike_{date_str}_{distance_miles:.1f}mi.gpx"
            filepath = os.path.join(output_dir, filename)
            
            # Create GPX file
            gpx = create_gpx_file(coordinates, start_time)
            
            # Verify there are points in the GPX file
            if not any(segment.points for track in gpx.tracks for segment in track.segments):
                print(f"Warning: Skipping hike with no valid points (ID: {hike.get('hike_id', 'unknown')})")
                continue
            
            # Set metadata
            gpx.name = f"Hike on {date_str}"
            gpx.time = start_time
            
            # Save file
            with open(filepath, 'w') as f:
                f.write(gpx.to_xml())
            
            print(f"Created: {filename}")
        except Exception as e:
            print(f"Error processing hike {hike.get('hike_id', 'unknown')}: {e}")
            continue

if __name__ == "__main__":
    main()
