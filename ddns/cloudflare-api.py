import os
import time
import urllib.request
import logging

from cloudflare import Cloudflare

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
log = logging.getLogger(__name__)

API_TOKEN = os.environ["CLOUDFLARE_API_TOKEN"]
ZONE_ID   = os.environ["CLOUDFLARE_ZONE_ID"]
RECORD_ID = os.environ["CLOUDFLARE_RECORD_ID"]
DOMAIN    = os.environ["CLOUDFLARE_DOMAIN"]
INTERVAL  = int(os.environ.get("UPDATE_INTERVAL", "300"))

client = Cloudflare(api_token=API_TOKEN)


def get_public_ip() -> str:
    with urllib.request.urlopen("https://checkip.amazonaws.com", timeout=10) as r:
        return r.read().decode().strip()


def get_current_record_ip() -> str:
    record = client.dns.records.get(dns_record_id=RECORD_ID, zone_id=ZONE_ID)
    return record.content


def update_record(ip: str) -> None:
    client.dns.records.update(
        dns_record_id=RECORD_ID,
        zone_id=ZONE_ID,
        name=DOMAIN,
        type="A",
        content=ip,
        ttl=60,
        proxied=False,
    )
    log.info("DNS updated: %s -> %s", DOMAIN, ip)


def main() -> None:
    log.info("DDNS started (interval=%ds, domain=%s)", INTERVAL, DOMAIN)
    while True:
        try:
            public_ip = get_public_ip()
            current_ip = get_current_record_ip()
            if public_ip != current_ip:
                log.info("IP changed: %s -> %s", current_ip, public_ip)
                update_record(public_ip)
            else:
                log.debug("IP unchanged: %s", public_ip)
        except Exception as e:
            log.error("Error: %s", e)
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
