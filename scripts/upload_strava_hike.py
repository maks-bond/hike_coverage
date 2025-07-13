import argparse
import boto3
import gpxpy
import gpxpy.gpx
import uuid
from datetime import datetime, timezone
from haversine import haversine, Unit
from decimal import Decimal

def calculate_distance_km(points):
    """Calculates the total distance of a route in kilometers."""
    distance = 0.0
    for i in range(len(points) - 1):
        p1 = (points[i].latitude, points[i].longitude)
        p2 = (points[i+1].latitude, points[i+1].longitude)
        distance += haversine(p1, p2, unit=Unit.KILOMETERS)
    return distance

def encode_coordinates(points):
    """Encodes coordinates into the 'lat,lon;lat,lon' format used by the app."""
    return ";".join([f"{p.latitude},{p.longitude}" for p in points])

def main():
    """
    Parses a GPX file from Strava and uploads it as a new hike to DynamoDB.
    """
    parser = argparse.ArgumentParser(
        description="Upload a Strava GPX file to the HikeCoverage DynamoDB table.",
        formatter_class=argparse.RawTextHelpFormatter
    )
    parser.add_argument("gpx_file", help="Path to the .gpx file exported from Strava.")
    parser.add_argument("user_name", help="The user name to associate the hike with (the one you entered in the app).")
    parser.add_argument("--notes", help="Optional notes for the hike.", default="")
    parser.add_argument("--region", help="The AWS region for DynamoDB.", default="us-east-2")
    parser.add_argument("--table-name", help="The DynamoDB table name.", default="hikes")
    parser.add_argument("--profile", help="The AWS profile to use for credentials.", default=None)

    args = parser.parse_args()

    print(f"Processing GPX file: {args.gpx_file}")

    try:
        with open(args.gpx_file, 'r') as gpx_file_content:
            gpx = gpxpy.parse(gpx_file_content)
    except FileNotFoundError:
        print(f"Error: The file '{args.gpx_file}' was not found.")
        return
    except Exception as e:
        print(f"Error parsing GPX file: {e}")
        return

    points = []
    for track in gpx.tracks:
        for segment in track.segments:
            points.extend(segment.points)

    if not points:
        print("No track points found in the GPX file.")
        return

    # Determine start time: from GPX metadata or first track point
    start_time = gpx.time if gpx.time else points[0].time
    if not start_time:
        start_time = datetime.now()
        print("Warning: Could not determine start time from GPX. Using current time.")

    # Ensure the datetime object is timezone-aware before formatting.
    # GPX files use UTC by standard, so we can safely assume it if missing.
    if start_time.tzinfo is None:
        start_time = start_time.replace(tzinfo=timezone.utc)

    # Calculate and encode data
    distance_km = calculate_distance_km(points)
    coordinates_str = encode_coordinates(points)
    hike_id = str(uuid.uuid4())
    hike_name = f"Hike on {start_time.strftime('%Y-%m-%d %H:%M:%S %z')}"
    start_timestamp = int(start_time.timestamp())

    print(f"  - Hike ID: {hike_id}")
    print(f"  - User: {args.user_name}")
    print(f"  - Date: {start_time.strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"  - Distance: {distance_km:.2f} km")
    print(f"  - Points: {len(points)}")

    # Prepare the item for DynamoDB
    item_to_upload = {
        'hike_id': hike_id,
        'user_uuid': args.user_name,
        'hike_name': hike_name,
        'start_time': Decimal(start_timestamp),
        'distance': Decimal(f'{distance_km:.6f}'), # Use string to preserve precision
        'notes': args.notes,
        'location': coordinates_str
    }

    # Upload to DynamoDB
    try:
        print(f"\nUploading to DynamoDB table '{args.table_name}' in region '{args.region}'...")
        session = boto3.Session(profile_name=args.profile, region_name=args.region)
        dynamodb = session.resource('dynamodb')
        table = dynamodb.Table(args.table_name)
        table.put_item(Item=item_to_upload)
        print("\n✅ Successfully uploaded hike!")
        print("You can now pull-to-refresh in the app to see the new route.")
    except Exception as e:
        print(f"\n❌ Error uploading to DynamoDB: {e}")
        print("Please ensure your AWS credentials are configured correctly (e.g., via `aws configure`).")

if __name__ == "__main__":
    main()