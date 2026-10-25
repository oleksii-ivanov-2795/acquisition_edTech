
import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

BASE_DIR = Path(__file__).resolve().parent.parent
DATA_DIR = BASE_DIR / "data"

load_dotenv(BASE_DIR / ".env")

engine = create_engine(os.getenv("DATABASE_URL"))

tables = [
    "marketing_spend",
    "users",
    "web_sessions",
    "events",
    "subscriptions",
    "payments",
]

with engine.begin() as connection:
    for table in tables:
        file_path = DATA_DIR / f"{table}.csv"

        df = pd.read_csv(file_path)

        df.to_sql(
            name=table,
            con=connection,
            schema="public",
            if_exists="append",
            index=False,
            chunksize=5000,
        )

        print(f"{table}: loaded {len(df)} rows")

engine.dispose()

print("All CSV files loaded successfully.")
