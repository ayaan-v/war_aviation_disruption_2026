# Global Civil Aviation Disruption 2026 — Iran US Conflict

![Project Banner](https://img.shields.io/badge/Status-Completed-brightgreen)
![Python](https://img.shields.io/badge/Python-3.x-blue)
![MySQL](https://img.shields.io/badge/MySQL-8.0-orange)
![PowerBI](https://img.shields.io/badge/Power%20BI-Dashboard-yellow)

---

## Project Overview

This end-to-end data analyst portfolio project analyses the **real-world impact of the 2026 Iran-US Military Conflict on Global Civil Aviation Networks.**

When Iran closed its airspace in response to US military strikes in February 2026, the ripple effects were felt across the entire global aviation industry — from flight cancellations at Dubai International to billion-dollar losses for Asian carriers forced to reroute over the Indian Ocean.

This project simulates the role of a **Data Analyst at an aviation risk consultancy** tasked with quantifying the crisis impact across 6 dimensions: conflict events, airspace closures, airport disruptions, flight cancellations, flight reroutes and airline financial losses.

---

## Key Findings

| KPI | Value |
|---|---|
| Conflict Events Recorded | 28 |
| Countries with Airspace Closures | 24 |
| Airports Disrupted | 35 |
| Total Flight Cancellations | 50 |
| Total Flight Reroutes | 45 |
| Avg Delay Per Reroute | 65.5 minutes |
| Total Extra Distance Flown | 33,250 km |
| Total Daily Airline Losses | $48,840,000 |
| Estimated 8-Day Total Losses | $390,720,000 |
| Total Passengers Impacted Daily | 119,570 |

---

## Tools & Technologies

| Tool | Purpose |
|---|---|
| **Python** | Data cleaning, EDA, derived columns |
| **Pandas** | Data manipulation and analysis |
| **MySQL** | Relational database and SQL analysis |
| **Power BI** | Interactive 3-page dashboard |

---

## Dataset

6 custom-built CSV files simulating real crisis data:

| File | Rows | Description |
|---|---|---|
| `conflict_events.csv` | 28 | Military strikes and aviation impacts |
| `airspace_closures.csv` | 25 | FIR region closures with NOTAM references |
| `airport_disruptions.csv` | 35 | Airport level flight disruption data |
| `flight_cancellations.csv` | 50 | Individual flight cancellations by airline |
| `flight_reroutes.csv` | 45 | Diverted routes with extra costs |
| `airline_losses_estimate.csv` | 35 | Daily financial losses per airline |

**Total: 218 rows across 6 tables**

---

## Database Schema

6-table relational database designed in MySQL:

```
conflict_events ──────────────────────────────────┐
airspace_closures ─────────────────────────────── │
airport_disruptions ───── flight_cancellations ── │
flight_reroutes ─────── airline_losses_estimate ──┘
```

---

## Python — Data Cleaning & EDA

**Cleaning Steps:**
- Added surrogate primary keys to all 6 tables
- Converted date/time columns to proper data types
- Standardised IATA/ICAO codes to uppercase
- Encoded severity as ordered categorical
- Stripped whitespace from all text columns

**Derived Columns Added:**
- `closure_duration_hours` — duration of each airspace closure
- `total_disrupted_flights` — sum of cancelled, delayed and diverted
- `route` — origin → destination string
- `cost_per_km` — fuel cost efficiency per extra km
- `loss_per_passenger_usd` — financial loss per affected passenger

---

## SQL Analysis — 21 Queries

Covering every major SQL concept:

| Category | Queries |
|---|---|
| Basic SELECT, WHERE, GROUP BY | Q1 — Q10 |
| INNER JOIN | Q11 — Q13 |
| CTE — Common Table Expressions | Q14 — Q15 |
| Window Functions — RANK, DENSE_RANK, ROW_NUMBER, SUM OVER | Q16 — Q17 |
| CASE Statements | Q18 — Q19 |
| Date & String Functions | Q20 |
| UNION ALL — KPI Summary | Q21 |

**Sample Queries:**
```sql
-- Top Airlines by Daily Loss using Window Function
SELECT
    ROW_NUMBER() OVER (ORDER BY estimated_daily_loss_usd DESC) AS row_num,
    RANK() OVER (ORDER BY estimated_daily_loss_usd DESC) AS loss_rank,
    airline,
    country,
    FORMAT(estimated_daily_loss_usd, 0) AS daily_loss_usd
FROM airline_losses_estimate
ORDER BY loss_rank;
```

```sql
-- CTE - Top Airlines by Loss per Country
WITH country_losses AS (
    SELECT
        country, airline, estimated_daily_loss_usd,
        RANK() OVER (
            PARTITION BY country
            ORDER BY estimated_daily_loss_usd DESC
        ) AS rank_in_country
    FROM airline_losses_estimate
)
SELECT rank_in_country, country, airline,
       FORMAT(estimated_daily_loss_usd, 0) AS daily_loss_usd
FROM country_losses
WHERE rank_in_country <= 2
ORDER BY country, rank_in_country;
```

---

## Power BI Dashboard — 3 Pages

### Page 1 — Crisis Overview
- 6 KPI Cards — Conflict Events, Airports, Cancellations, Losses, Reroutes, Passengers
- Line Chart — Conflict Events by Date
- Donut Chart — Events by Severity

### Page 2 — Flight & Airport Impact
- Horizontal Bar Chart — Top 10 Disrupted Airports
- Column Chart — Cancellations by Day
- Treemap — Most Cancelled Routes
- Horizontal Bar Chart — Most Cancelled Airlines

### Page 3 — Financial Impact
- Horizontal Bar Chart — Top Airlines by Daily Loss
- Horizontal Bar Chart — Reroute Costs by Airline
- Funnel Chart — Country Level Financial Losses
- Pie Chart — Hardest Hit Countries by Loss

---

## How to Run This Project

### Python
```bash
pip install pandas numpy
python war_aviation_analysis.py
```

### MySQL
```sql
CREATE DATABASE war_aviation_disruption_2026;
USE war_aviation_disruption_2026;

```

### Power BI
- Open `Aviation_Disruption_2026.pbix` in Power BI Desktop
- Update MySQL connection to your local server if needed

---

## Business Insights

1. **Emirates suffered the highest daily loss** of $4.2M — highest among all 35 airlines
2. **UAE was the hardest hit country** with $6.68M in daily losses across 3 airlines
3. **March 1 2026 was the peak crisis day** with 19 flight cancellations in a single day
4. **DXB → IKA was the most cancelled route** with 6 cancellations — Dubai to Tehran
5. **Cathay Pacific spent the most on rerouting** — $210,600 in extra fuel costs
6. **Tehran FIR had the longest closure** — 171 hours of continuous airspace shutdown
7. **Top 3 airlines account for 20%** of all global aviation losses from this conflict
8. **119,570 passengers were impacted daily** — equivalent to a large city evacuating every day

---

## Author

**Ayaan Vadsaria**
- GitHub: [@ayaan-v](https://github.com/ayaan-v)

---

## License

This project is open source and available under the [MIT License](LICENSE).
