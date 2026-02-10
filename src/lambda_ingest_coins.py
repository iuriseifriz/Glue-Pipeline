import json
import requests
import boto3
from datetime import datetime, timezone

S3_BUCKET = "crypto-datalake-381492258425"
S3_PREFIX = "bronze/coins_market"

COINGECKO_URL = "https://api.coingecko.com/api/v3/coins/markets"

def lambda_handler(event, context):
    params = {
        "vs_currency": "usd",
        "order": "market_cap_desc",
        "per_page": 10,
        "page": 1,
        "sparkline": "false"
    }

    response = requests.get(COINGECKO_URL, params=params, timeout=10)
    response.raise_for_status()
    data = response.json()

    ingestion_time = datetime.now(timezone.utc)
    dt = ingestion_time.strftime("%Y-%m-%d")

    payload = {
        "source": "coingecko",
        "ingestion_timestamp": ingestion_time.isoformat(),
        "data": data
    }

    s3_key = f"{S3_PREFIX}/dt={dt}/data.json"

    s3 = boto3.client("s3")
    s3.put_object(
        Bucket=S3_BUCKET,
        Key=s3_key,
        Body=json.dumps(payload),
        ContentType="application/json"
    )

    return {
        "statusCode": 200,
        "message": f"Data written to s3://{S3_BUCKET}/{s3_key}"
    }
