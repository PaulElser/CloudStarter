import time
import os
import sys
from prometheus_client import start_http_server, Counter
import re
import geoip2.database
from datetime import datetime

# Define metrics
location_requests = Counter('nginx_geoip_location_requests_total', 'Number of requests per location',
                            ['latitude', 'longitude', 'country', 'city', 'ip_address', 'timestamp'])

# Regular expression to parse log lines
log_pattern = re.compile(r'(?P<ip>[\d\.]+) .* \[(?P<timestamp>.*?)\] "(?P<request>.*?)" (?P<status>\d+) \d+ ".*?" ".*?" ".*?" (?P<country_code>\w+) (?P<city_name>.*)')

# Initialize GeoIP2 reader
geoip_db_path = '/etc/nginx/GeoLite2-City.mmdb'

def parse_log(log_file):
    if not os.path.exists(log_file):
        print(f"Log file {log_file} does not exist. Waiting for it to be created...")
        return

    with open(log_file, 'r') as f:
        f.seek(0, 2)  # Go to the end of the file
        while True:
            line = f.readline()
            if not line:
                time.sleep(0.1)  # Sleep briefly
                continue
            
            match = log_pattern.match(line)
            if match:
                ip = match.group('ip')
                timestamp = datetime.strptime(match.group('timestamp'), '%d/%b/%Y:%H:%M:%S %z').isoformat()
                try:
                    response = reader.city(ip)
                    lat = str(response.location.latitude)
                    lon = str(response.location.longitude)
                    country = response.country.name
                    city = response.city.name
                    if lat and lon:
                        location_requests.labels(latitude=lat, longitude=lon, country=country, city=city,
                                                 ip_address=ip, timestamp=timestamp).inc()
                except geoip2.errors.AddressNotFoundError:
                    # IP not found in database, skip this entry
                    continue

def main():
    print("Starting GeoIP exporter...")
    
    # Check if GeoIP database exists
    if not os.path.exists(geoip_db_path):
        print(f"Error: GeoIP database not found at {geoip_db_path}")
        sys.exit(1)

    try:
        global reader
        reader = geoip2.database.Reader(geoip_db_path)
    except Exception as e:
        print(f"Error initializing GeoIP database: {e}")
        sys.exit(1)

    # Start up the server to expose metrics.
    try:
        start_http_server(9114)
        print("GeoIP exporter started on port 9114")
    except Exception as e:
        print(f"Error starting HTTP server: {e}")
        sys.exit(1)

    log_file = '/var/log/nginx/access.log'
    # Parse log file continuously
    parse_log(log_file)

if __name__ == '__main__':
    main()
