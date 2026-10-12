FROM python:3.12-slim
WORKDIR /app
ENV PYTHONUNBUFFERED=1
COPY requirements.txt requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
COPY common common
COPY __init__.py load_csv.py export_result.py hw2/
COPY sql hw2/sql
COPY data/demo.csv data/demo.csv
ENTRYPOINT ["python", "-m", "hw2.load_csv"]
