import argparse
import csv
import os
import time
from pathlib import Path
from urllib.request import Request, urlopen


def query(sql):
    request = Request(
        os.getenv("CLICKHOUSE_URL", "http://clickhouse:8123"),
        data=sql.encode(),
    )
    with urlopen(request, timeout=30) as response:
        return response.read().decode()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("csv", nargs="?", default="/data/demo.csv")
    parser.add_argument("--output", default="/results/max_by_state.csv")
    args = parser.parse_args()

    with open(args.csv, newline="", encoding="utf-8-sig") as source:
        count = sum(1 for _ in csv.DictReader(source))

    deadline = time.monotonic() + 180
    while True:
        actual_count = int(query("SELECT count() FROM fraud.transactions"))
        if actual_count == count:
            break
        if actual_count > count or time.monotonic() >= deadline:
            raise RuntimeError(f"ClickHouse rows: {actual_count}, CSV rows: {count}")
        time.sleep(1)

    sql = Path(__file__).with_name("sql").joinpath("02_max_by_state.sql").read_text()
    result = query(sql)
    Path(args.output).write_text(result)
    print(f"Saved {args.output}")


if __name__ == "__main__":
    main()
