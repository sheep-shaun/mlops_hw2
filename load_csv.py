import argparse
import csv
import json
import os
from datetime import datetime

from common.kafka_io import producer


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", nargs="?", default="/data/demo.csv")
    args = parser.parse_args()

    client = producer()
    topic = os.getenv("KAFKA_TRANSACTIONS_TOPIC", "transactions")
    errors = []

    def delivered(error, message):
        if error:
            errors.append(str(error))

    count = 0
    with open(args.csv, newline="", encoding="utf-8-sig") as source:
        for row in csv.DictReader(source):
            row.pop("target", None)
            row["transaction_time"] = datetime.fromisoformat(
                row["transaction_time"]
            ).isoformat(sep=" ")
            row["population_city"] = int(row["population_city"])
            for column in ("lat", "lon", "merchant_lat", "merchant_lon"):
                row[column] = float(row[column])
            value = json.dumps(row, allow_nan=False).encode()
            while True:
                try:
                    client.produce(
                        topic, key=row["us_state"], value=value, on_delivery=delivered
                    )
                    break
                except BufferError:
                    client.poll(0.1)
            client.poll(0)
            count += 1
            if errors:
                raise RuntimeError(errors[0])
    if client.flush(35) or errors:
        raise RuntimeError(f"Kafka delivery failed: {errors}")
    print(f"Sent {count} rows to {topic}")


if __name__ == "__main__":
    main()
