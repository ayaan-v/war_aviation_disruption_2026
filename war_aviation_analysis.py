# Global Civil Aviation Disruption 2026 — Iran–US Conflict
# Data Cleaning & Exploratory Data Analysis (EDA)
import pandas as pd
import numpy as np
import os

conflict_events       = pd.read_csv("conflict_events.csv")
airspace_closures     = pd.read_csv("airspace_closures.csv")
airport_disruptions   = pd.read_csv("airport_disruptions.csv")
flight_cancellations  = pd.read_csv("flight_cancellations.csv")
flight_reroutes       = pd.read_csv("flight_reroutes.csv")
airline_losses        = pd.read_csv("airline_losses_estimate.csv")

datasets = {
    "conflict_events":      conflict_events,
    "airspace_closures":    airspace_closures,
    "airport_disruptions":  airport_disruptions,
    "flight_cancellations": flight_cancellations,
    "flight_reroutes":      flight_reroutes,
    "airline_losses":       airline_losses,
}

for name, df in datasets.items():
    print(f"Loaded {name:<25} {df.shape[0]:>3} rows x{df.shape[1]} cols")


# SECTION 2 — DATA QUALITY CHECK
print("SECTION 2: DATA QUALITY CHECK")

for name, df in datasets.items():
    nulls = df.isnull().sum().sum()
    dupes = df.duplicated().sum()
    print(f"\n  [{name}]")
    print(f"Null values: {nulls}")
    print(f"Duplicate rows: {dupes}")
    if nulls == 0 and dupes == 0:
        print(f"Status: CLEAN — no nulls or duplicates are found")



# SECTION 3 — DATA CLEANING
print("\n SECTION 3: DATA CLEANING")

# 3.1 conflict_events
print("\n [3.1] conflict_events")

# Add surrogate PK
conflict_events.insert(0, "event_id", range(1, len(conflict_events) + 1))

# date and time into proper types
conflict_events["date"] = pd.to_datetime(conflict_events["date"]).dt.date
conflict_events["time_utc"] = pd.to_datetime(conflict_events["time_utc"], format="%H:%M:%S").dt.time

# Severity to uppercase and strip whitespace
conflict_events["severity"] = (
    conflict_events["severity"].str.strip().str.upper())

# Severity as ordered category for sorting/analysis
sev_order = ["LOW", "MEDIUM", "HIGH", "CRITICAL"]
conflict_events["severity"] = pd.Categorical(conflict_events["severity"], categories=sev_order, ordered=True)

# Strip whitespace from all string columns
str_cols = ["location", "event_type", "aviation_impact", "source"]
conflict_events[str_cols] = conflict_events[str_cols].apply(lambda col: col.str.strip())

print(f" Column (event_id) added")
print(f" date - datetime.date & time_utc - datetime.time")
print(f" severity - ordered categorical {sev_order}")
print(f" Severity distribution:\n{conflict_events['severity'].value_counts()}")

# 3.2 airspace_closures
print("\n  [3.2] airspace_closures")

airspace_closures.insert(0, "closure_id", range(1, len(airspace_closures) + 1))

# ISO datetime strings (UTC)
airspace_closures["closure_start_time"] = pd.to_datetime(airspace_closures["closure_start_time"], utc=True)
airspace_closures["closure_end_time"] = pd.to_datetime(airspace_closures["closure_end_time"], utc=True)

# Derived column: closure duration in hours
airspace_closures["closure_duration_hours"] = (
    (airspace_closures["closure_end_time"] - airspace_closures["closure_start_time"])
        .dt.total_seconds() / 3600)
print(airspace_closures.head().round(2))

# Strip whitespace from text columns
str_cols = ["country", "region", "closure_reason", "authority", "NOTAM_reference"]
airspace_closures[str_cols] = airspace_closures[str_cols].apply(lambda col: col.str.strip())

print(f"    Added Column (closure_id) added")
print(f"    closure_start/end_time - datetime (UTC-Coordinated Universal Time)")
print(f"    Derived column: closure_duration_hours to show gap length in hours")
print(f"    Duration range: {airspace_closures['closure_duration_hours'].min()}hours "f"- {airspace_closures['closure_duration_hours'].max()}hours")

# 3.3 airport_disruptions 
print("\n  [3.3] airport_disruptions")

airport_disruptions.insert(0, "airport_id", range(1, len(airport_disruptions) + 1))

# Standardise IATA/ICAO to uppercase - Shortforms for countires and airports
airport_disruptions["iata"] = airport_disruptions["iata"].str.strip().str.upper()
airport_disruptions["icao"] = airport_disruptions["icao"].str.strip().str.upper()

# Derived: total disrupted flights
airport_disruptions["total_disrupted_flights"] = (
    airport_disruptions["flights_cancelled"]
    + airport_disruptions["flights_delayed"]
    + airport_disruptions["flights_diverted"]
)

# Validate no negative flight counts
neg_check = (
    airport_disruptions[["flights_cancelled", "flights_delayed", "flights_diverted"]] < 0).sum().sum()

print(f"    New Column (airport_id) added")
print(f"    iata/icao → uppercase standardised")
print(f"    Derived column: total_disrupted_flights")
print(f"    Negative value check: {'PASSED (0 negatives)' if neg_check == 0 else f'FAILED ({neg_check} found)'}")
print(f"    Unique runway statuses: {airport_disruptions['runway_status'].nunique()}")

# 3.4 flight_cancellations 
print("\n  [3.4] flight_cancellations")

flight_cancellations.insert(0, "cancellation_id", range(1, len(flight_cancellations) + 1))

# Convert date to datetime.date
flight_cancellations["date"] = pd.to_datetime(flight_cancellations["date"]).dt.date

# Strip whitespace and uppercase IATA codes
flight_cancellations["origin"] = flight_cancellations["origin"].str.strip().str.upper()
flight_cancellations["destination"] = flight_cancellations["destination"].str.strip().str.upper()

# Strip whitespace from text columns
str_cols = ["airport", "country", "airline", "flight_number", "cancellation_reason", "aircraft_type"]
flight_cancellations[str_cols] = flight_cancellations[str_cols].apply(
    lambda col: col.str.strip())

# Derive: route column (origin > destination)
flight_cancellations["route"] = (
    flight_cancellations["origin"] + " > " + flight_cancellations["destination"])

print(f"    Added Column (cancellation_id) added")
print(f"    date - datetime.date")
print(f"    origin/destination - uppercase IATA")
print(f"    Derived column: route (origin > destination)")
print(f"    Date range: {min(flight_cancellations['date'])} to {max(flight_cancellations['date'])}")
print(f"    Unique airlines affected: {flight_cancellations['airline'].nunique()}")

# 3.5 flight_reroutes
print("\n  [3.5] flight_reroutes")

flight_reroutes.insert(0, "reroute_id", range(1, len(flight_reroutes) + 1))

# Strip whitespace from string columns
str_cols = ["flight_id", "airline", "original_route", "diverted_route"]
flight_reroutes[str_cols] = flight_reroutes[str_cols].apply(
    lambda col: col.str.strip())

# Validate numeric ranges to ensure no negative values for distance, fuel cost, or delay
neg_check = (
    flight_reroutes[["additional_distance_km",
                     "additional_fuel_cost_usd",
                     "delay_minutes"]] < 0
).sum().sum()

# Derived: cost per km
flight_reroutes["additional_cost_per_km"] = (
    flight_reroutes["additional_fuel_cost_usd"]
    / flight_reroutes["additional_distance_km"]
).round(2)

print(f"    Added Column (reroute_id) added")
print(f"    Negative value check: {'PASSED' if neg_check == 0 else 'FAILED'}")
print(f"    Derived column: additional_cost_per_km (fuel cost / distance)")
print(f"    Avg additional distance: {flight_reroutes['additional_distance_km'].mean():.0f} km")
print(f"    Avg additional fuel cost:{flight_reroutes['additional_fuel_cost_usd'].mean():,.0f}")
print(f"    Avg delay: {flight_reroutes['delay_minutes'].mean():.0f} mins")

# ── 3.6 airline_losses ───────────────────────────────────────────────────────
print("\n  [3.6] airline_losses_estimate")

airline_losses.insert(0, "loss_id", range(1, len(airline_losses) + 1))

# Strip whitespace
str_cols = ["airline", "country"]
airline_losses[str_cols] = airline_losses[str_cols].apply(
    lambda col: col.str.strip())

# Derived: loss per passenger
airline_losses["loss_per_passenger_usd"] = (
    airline_losses["estimated_daily_loss_usd"]
    / airline_losses["passengers_impacted"]
).round(2)

# Derived: loss per cancelled flight
airline_losses["loss_per_cancelled_flight_usd"] = (
    airline_losses["estimated_daily_loss_usd"]
    / airline_losses["cancelled_flights"]
).round(2)

print(f" Added Column (loss_id) added")
print(f" Derived column: loss_per_passenger_usd")
print(f" Derived column: loss_per_cancelled_flight_usd")
print(f" Total estimated daily losses: {airline_losses['estimated_daily_loss_usd'].sum():,.0f}")
print(f" Total passengers impacted: {airline_losses['passengers_impacted'].sum():,}")




# SECTION 4 — EXPLORATORY DATA ANALYSIS (EDA)

print(" SECTION 4: EXPLORATORY DATA ANALYSIS (EDA)")

# 4.1 Conflict Timeline 
print("\n  [4.1] Conflict Event Timeline")

events_per_day = (
    conflict_events.groupby("date")["event_id"]
    .count()
    .reset_index()
    .rename(columns={"event_id": "event_count"}))

print(events_per_day.to_string(index=False))

print(f"\n  Severity breakdown:")
print(conflict_events["severity"].value_counts().sort_index().to_string())

# 4.2 Airspace Closures Analysis 
print("\n  [4.2] Airspace Closures by Country")

closure_summary = (
    airspace_closures.groupby("country")
    .agg(
        regions_closed=("region", "count"),
        avg_duration_hours=("closure_duration_hours", "mean"),
        max_duration_hours=("closure_duration_hours", "max"),)
    .sort_values("avg_duration_hours", ascending=False)
    .round(2))

print(closure_summary.to_string())

total_closure_hours = airspace_closures["closure_duration_hours"].sum()
print(f"\n  Total airspace closure hours: {total_closure_hours:,.1f} hours")

# 4.3 Most Disrupted Airports 
print("\n  [4.3] Top 10 Most Disrupted Airports")
top_airports = (
    airport_disruptions[["airport", "iata", "country", "flights_cancelled", "flights_delayed",
    "flights_diverted", "total_disrupted_flights"]]
    .sort_values("total_disrupted_flights", ascending=False)
    .head(10))

print(top_airports.to_string(index=False))

# Country-level disruption summary
print("\n  Country-Level Disruption Summary:")
country_disruption = (
    airport_disruptions.groupby("country")
    .agg(
        airports_affected=("airport", "count"),
        total_cancelled=("flights_cancelled", "sum"),
        total_delayed=("flights_delayed", "sum"),
        total_diverted=("flights_diverted", "sum"),
        total_disrupted=("total_disrupted_flights", "sum"),
    )
    .sort_values("total_disrupted", ascending=False)
)
print(country_disruption.to_string())

# ── 4.4 Flight Cancellations Analysis ────────────────────────────────────────
print("\n  [4.4] Flight Cancellations Analysis")

# Cancellations by date
print("\n  Cancellations per day:")

daily_cancellations = (flight_cancellations.groupby("date")["cancellation_id"]
    .count()
    .reset_index()
    .rename(columns={"cancellation_id": "cancellations"})
)
print(daily_cancellations.to_string(index=False))

# Top airlines by cancellations
print("\n  Top airlines by cancellations:")

airline_cancellations = (
    flight_cancellations.groupby("airline")["cancellation_id"]
    .count()
    .sort_values(ascending=False)
    .reset_index()
    .rename(columns={"cancellation_id": "cancellations"})
)
print(airline_cancellations.to_string(index=False))

# Most common cancellation reasons
print("\n  Top 5 cancellation reasons:")

cancel_reasons = (
    flight_cancellations["cancellation_reason"]
    .value_counts()
    .head(5))

print(cancel_reasons.to_string())

# Most affected routes
print("\n  Most cancelled routes:")

top_routes = (
    flight_cancellations.groupby("route")["cancellation_id"]
    .count()
    .sort_values(ascending=False)
    .head(10)
    .reset_index()
    .rename(columns={"cancellation_id": "cancellations"}))

print(top_routes.to_string(index=False))

# 4.5 Flight Reroutes Analysis 
print("\n  [4.5] Flight Reroutes Analysis")

# By airline
print("\n  Reroutes by airline:")

reroute_by_airline = (
    flight_reroutes.groupby("airline")
    .agg(
        reroutes=("reroute_id", "count"),
        avg_extra_km=("additional_distance_km", "mean"),
        avg_extra_fuel_usd=("additional_fuel_cost_usd", "mean"),
        avg_delay_mins=("delay_minutes", "mean"),
        total_fuel_cost_usd=("additional_fuel_cost_usd", "sum"),
    )
    .sort_values("total_fuel_cost_usd", ascending=False)
    .round(2))

print(reroute_by_airline.to_string())

# Overall reroute statistics
print(f"\n  Overall reroute statistics:")
stats = flight_reroutes[["additional_distance_km",
                          "additional_fuel_cost_usd",
                          "delay_minutes"]].describe().round(2)
print(stats.to_string())

# 4.6 Airline Financial Losses
print("\n  [4.6] Airline Financial Losses")

# Top 10 airlines by daily loss
print("\n  Top 10 airlines by estimated daily loss:")
top_losses = (
    airline_losses[["airline", "country", "estimated_daily_loss_usd",
                    "cancelled_flights", "passengers_impacted",
                    "loss_per_passenger_usd"]]
    .sort_values("estimated_daily_loss_usd", ascending=False)
    .head(10)
)
print(top_losses.to_string(index=False))

# Country-level losses
print("\n  Country-level financial impact:")
country_losses = (
    airline_losses.groupby("country")
    .agg(
        airlines_affected=("airline", "count"),
        total_daily_loss_usd=("estimated_daily_loss_usd", "sum"),
        total_passengers_impacted=("passengers_impacted", "sum"),
        total_cancelled_flights=("cancelled_flights", "sum"),
    )
    .sort_values("total_daily_loss_usd", ascending=False)
)
print(country_losses.to_string())

# ── 4.7 Key Summary Statistics ───────────────────────────────────────────────
print("\n  [4.7] Key Summary Statistics (KPIs)")

total_cancellations      = len(flight_cancellations)
total_reroutes           = len(flight_reroutes)
total_daily_losses       = airline_losses["estimated_daily_loss_usd"].sum()
total_passengers         = airline_losses["passengers_impacted"].sum()
total_extra_km           = flight_reroutes["additional_distance_km"].sum()
total_extra_fuel         = flight_reroutes["additional_fuel_cost_usd"].sum()
avg_delay                = flight_reroutes["delay_minutes"].mean()
firs_closed              = len(airspace_closures)
countries_with_closures  = airspace_closures["country"].nunique()
airports_affected        = len(airport_disruptions)
conflict_event_count     = len(conflict_events)
crisis_days              = 8  # Feb 28 – Mar 7

print(f"    Total flight cancellations: {total_cancellations:,}")
print(f"    Total flight reroutes: {total_reroutes:,}")
print(f"    Total estimated daily losses: ${total_daily_losses:,.0f}")
print(f"    Total passengers impacted: {total_passengers:,}")
print(f"    Total additional distance flown due to reroutes: {total_extra_km:,.0f} km")
print(f"    Total additional fuel cost due to reroutes: ${total_extra_fuel:,.0f}")
print(f"    Average delay per rerouted flight: {avg_delay:.0f} minutes")
print(f"    Total FIRs closed: {firs_closed}")
print(f"    Countries with airspace closures: {countries_with_closures}")
print(f"    Airports affected by disruptions: {airports_affected}")
print(f"    Total conflict events recorded: {conflict_event_count}")
print(f"    Crisis duration: {crisis_days} days (Feb 28 - Mar 7)")  

#----------------

# SECTION 5 — SAVE CLEANED DATA

print(" SECTION 5: SAVING CLEANED DATASETS")

cleaned = {
    "conflict_events_clean.csv": conflict_events,
    "airspace_closures_clean.csv": airspace_closures,
    "airport_disruptions_clean.csv": airport_disruptions,
    "flight_cancellations_clean.csv": flight_cancellations,
    "flight_reroutes_clean.csv": flight_reroutes,
    "airline_losses_clean.csv": airline_losses,
}

for cleaned_dataset, df in cleaned.items():
    path = cleaned_dataset
    df.to_csv(path, index=False)
    print(f"  Saved - {path}  ({df.shape[0]} rows x {df.shape[1]} cols)")

print("\n  All cleaned files saved to:")

print(" PIPELINE COMPLETE")

