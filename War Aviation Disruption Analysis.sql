-- Table 1: conflict_events
CREATE TABLE conflict_events (
    event_id         INT           NOT NULL AUTO_INCREMENT,
    date             DATE          NOT NULL,
    time_utc         TIME          NOT NULL,
    location         VARCHAR(200)  NOT NULL,
    latitude         DECIMAL(9,4)  NOT NULL,
    longitude        DECIMAL(9,4)  NOT NULL,
    event_type       VARCHAR(100)  NOT NULL,
    aviation_impact  VARCHAR(200)  NOT NULL,
    severity         VARCHAR(20)   NOT NULL,
    source           VARCHAR(200)  NOT NULL,
    PRIMARY KEY (event_id)
);

-- Table 2: airspace_closures
CREATE TABLE airspace_closures (
    closure_id             INT           NOT NULL AUTO_INCREMENT,
    country                VARCHAR(100)  NOT NULL,
    region                 VARCHAR(100)  NOT NULL,
    closure_start_time     DATETIME      NOT NULL,
    closure_end_time       DATETIME      NOT NULL,
    closure_reason         VARCHAR(200)  NOT NULL,
    authority              VARCHAR(100)  NOT NULL,
    NOTAM_reference        VARCHAR(50)   NOT NULL,
    closure_duration_hours DECIMAL(8,2)  NOT NULL,
    PRIMARY KEY (closure_id)
);

-- Table 3: airport_disruptions
CREATE TABLE airport_disruptions (
    airport_id              INT           NOT NULL AUTO_INCREMENT,
    airport                 VARCHAR(100)  NOT NULL,
    iata                    CHAR(3)       NOT NULL,
    icao                    CHAR(4)       NOT NULL,
    country                 VARCHAR(100)  NOT NULL,
    latitude                DECIMAL(9,4)  NOT NULL,
    longitude               DECIMAL(9,4)  NOT NULL,
    flights_cancelled       INT           NOT NULL DEFAULT 0,
    flights_delayed         INT           NOT NULL DEFAULT 0,
    flights_diverted        INT           NOT NULL DEFAULT 0,
    runway_status           VARCHAR(100)  NOT NULL,
    total_disrupted_flights INT           NOT NULL DEFAULT 0,
    PRIMARY KEY (airport_id)
);

-- Table 4: flight_cancellations
CREATE TABLE flight_cancellations (
    cancellation_id     INT           NOT NULL AUTO_INCREMENT,
    date                DATE          NOT NULL,
    airport             VARCHAR(100)  NOT NULL,
    country             VARCHAR(100)  NOT NULL,
    airline             VARCHAR(100)  NOT NULL,
    flight_number       VARCHAR(20)   NOT NULL,
    origin              CHAR(3)       NOT NULL,
    destination         CHAR(3)       NOT NULL,
    cancellation_reason VARCHAR(200)  NOT NULL,
    aircraft_type       VARCHAR(50)   NOT NULL,
    route               VARCHAR(20)   NOT NULL,
    PRIMARY KEY (cancellation_id)
);

-- Table 5: flight_reroutes
CREATE TABLE flight_reroutes (
    reroute_id               INT           NOT NULL AUTO_INCREMENT,
    flight_id                VARCHAR(30)   NOT NULL,
    airline                  VARCHAR(100)  NOT NULL,
    original_route           VARCHAR(200)  NOT NULL,
    diverted_route           VARCHAR(200)  NOT NULL,
    additional_distance_km   INT           NOT NULL DEFAULT 0,
    additional_fuel_cost_usd DECIMAL(12,2) NOT NULL DEFAULT 0,
    delay_minutes            INT           NOT NULL DEFAULT 0,
    cost_per_km              DECIMAL(8,2)  NOT NULL DEFAULT 0,
    PRIMARY KEY (reroute_id)
);

-- Table 6: airline_losses_estimate
CREATE TABLE airline_losses_estimate (
    loss_id                       INT           NOT NULL AUTO_INCREMENT,
    airline                       VARCHAR(100)  NOT NULL,
    country                       VARCHAR(100)  NOT NULL,
    estimated_daily_loss_usd      DECIMAL(14,2) NOT NULL DEFAULT 0,
    cancelled_flights             INT           NOT NULL DEFAULT 0,
    rerouted_flights              INT           NOT NULL DEFAULT 0,
    additional_fuel_cost_usd      DECIMAL(12,2) NOT NULL DEFAULT 0,
    passengers_impacted           INT           NOT NULL DEFAULT 0,
    loss_per_passenger_usd        DECIMAL(10,2) NOT NULL DEFAULT 0,
    loss_per_cancelled_flight_usd DECIMAL(12,2) NOT NULL DEFAULT 0,
    PRIMARY KEY (loss_id)
);

-- VERIFY ALL COLUMNS 
SHOW TABLES;

-- VERIFY ALL ROW COUNTS

SELECT 'conflict_events'        AS table_name, COUNT(*) AS total_rows FROM conflict_events
UNION ALL
SELECT 'airspace_closures',       COUNT(*) FROM airspace_closures
UNION ALL
SELECT 'airport_disruptions',     COUNT(*) FROM airport_disruptions
UNION ALL
SELECT 'flight_cancellations',    COUNT(*) FROM flight_cancellations
UNION ALL
SELECT 'flight_reroutes',         COUNT(*) FROM flight_reroutes
UNION ALL
SELECT 'airline_losses_estimate', COUNT(*) FROM airline_losses_estimate;

-- ANALYSIS

-- Q1 How many conflict events happened each day and what was the severity?
SELECT
    date,
    COUNT(event_id) AS total_events,
    SUM(CASE WHEN severity = 'CRITICAL' THEN 1 ELSE 0 END) AS critical_events,
    SUM(CASE WHEN severity = 'HIGH' THEN 1 ELSE 0 END) AS high_events,
    SUM(CASE WHEN severity = 'MEDIUM' THEN 1 ELSE 0 END) AS medium_events,
    SUM(CASE WHEN severity = 'LOW' THEN 1 ELSE 0 END) AS low_events
FROM conflict_events
GROUP BY date
ORDER BY date ASC;

-- Q2 Which country had the longest airspace closure?
SELECT
    country,
    COUNT(closure_id) AS regions_closed,
    ROUND(MAX(closure_duration_hours),2) AS longest_closure_hours,
    ROUND(MIN(closure_duration_hours),2) AS shortest_closure_hours,
    ROUND(AVG(closure_duration_hours),2) AS avg_closure_hours,
    ROUND(SUM(closure_duration_hours),2) AS total_closure_hours
FROM airspace_closures
GROUP BY country
ORDER BY longest_closure_hours DESC;

-- Q3 Top 10 Most Disrupted Airports
SELECT
    airport,
    iata,
    country,
    flights_cancelled,
    flights_delayed,
    flights_diverted,
    total_disrupted_flights,
    runway_status
FROM airport_disruptions
ORDER BY total_disrupted_flights DESC
LIMIT 10;

-- Q4 Which country had the most total disrupted flights?
SELECT
    country,
    COUNT(airport_id) AS airports_affected,
    SUM(flights_cancelled) AS cancelled_flights,
    SUM(flights_delayed) AS delayed_flights,
    SUM(flights_diverted) AS diverted_flights,
    SUM(total_disrupted_flights) AS disrupted_flights
FROM airport_disruptions
GROUP BY country
ORDER BY disrupted_flights DESC;

-- Q5 How did flight cancellations change day by day?
SELECT
    date,
    COUNT(cancellation_id) AS total_cancellations,
    COUNT(DISTINCT airline) AS airlines_affected,
    COUNT(DISTINCT route) AS routes_affected
FROM flight_cancellations
GROUP BY date
ORDER BY date;

-- Q6 Which airlines had the most flights cancelled?
SELECT
    airline,
    COUNT(cancellation_id) AS total_cancellations
FROM flight_cancellations
GROUP BY airline
ORDER BY total_cancellations DESC;

-- Q7 Which routes were cancelled the most? (TOP 10)
SELECT
    route,
    COUNT(cancellation_id)  AS total_cancellations
FROM flight_cancellations
GROUP BY route
ORDER BY total_cancellations DESC
LIMIT 10;

-- Q8 Which airlines spent the most on rerouting? (TOP 10)
SELECT
    airline,
    FORMAT(SUM(additional_fuel_cost_usd), 0) AS spent_most_usd
FROM flight_reroutes
GROUP BY airline
ORDER BY SUM(additional_fuel_cost_usd) DESC
LIMIT 10;

-- Q9 Which airlines suffered the highest daily losses? (TOP 10)
SELECT
    airline,
    FORMAT(estimated_daily_loss_usd, 0) AS daily_loss_usd
FROM airline_losses_estimate
ORDER BY estimated_daily_loss_usd DESC
LIMIT 10;

-- Q10 Which countries had the highest total airline losses?
SELECT
    country,
    COUNT(loss_id)                               AS airlines_affected,
    FORMAT(SUM(estimated_daily_loss_usd), 0)     AS total_daily_loss_usd,
    FORMAT(SUM(estimated_daily_loss_usd) * 8, 0) AS estimated_8day_loss_usd,
    SUM(passengers_impacted)                     AS total_passengers_impacted,
    SUM(cancelled_flights)                       AS total_cancelled_flights
FROM airline_losses_estimate
GROUP BY country
ORDER BY SUM(estimated_daily_loss_usd) DESC;


-- Q11 JOIN - Cancellations with Airport Disruption Details
SELECT
    a.date,
    a.airline,
    a.flight_number,
    a.route,
    a.cancellation_reason,
    b.total_disrupted_flights,
    b.runway_status
FROM flight_cancellations AS a
JOIN airport_disruptions AS b
    ON a.origin = b.iata
ORDER BY a.date, a.airline;

-- Q12 JOIN - Reroutes with Financial Losses
SELECT
    a.airline,
    b.passengers_impacted,
    a.original_route,
    a.diverted_route,
    a.additional_distance_km,
    FORMAT(a.additional_fuel_cost_usd, 0) AS reroute_fuel_cost,
    FORMAT(b.estimated_daily_loss_usd, 0) AS airline_daily_loss
FROM flight_reroutes AS a
JOIN airline_losses_estimate AS b
    ON a.airline = b.airline
ORDER BY a.additional_fuel_cost_usd DESC;

-- Q13 JOIN - Airport Disruptions with Airspace Closures
SELECT
    a.airport,
    a.iata,
    b.region,
    a.country,
    b.closure_duration_hours,
    a.flights_cancelled,
    a.flights_delayed,
    a.flights_diverted,
    a.total_disrupted_flights,
    a.runway_status,
    b.closure_reason
FROM airport_disruptions AS a
JOIN airspace_closures AS b
    ON a.country = b.country
ORDER BY a.total_disrupted_flights DESC;


-- Q14 CTE - Top Airlines by Loss per Country
WITH country_losses AS (
    SELECT
        country,
        airline,
        estimated_daily_loss_usd,
        RANK() OVER (
            PARTITION BY country
            ORDER BY estimated_daily_loss_usd DESC
        ) AS rank_in_country
    FROM airline_losses_estimate
)
SELECT
    rank_in_country,
    country,
    airline,
    FORMAT(estimated_daily_loss_usd, 0) AS daily_loss_usd
FROM country_losses
WHERE rank_in_country <= 2
ORDER BY country, rank_in_country;

-- Q15 CTE - Rank Airports by Disruption Level within each Country
WITH airport_ranking AS (
    SELECT
        country,
        airport,
        flights_cancelled,
        flights_delayed,
        flights_diverted,
        total_disrupted_flights,
        DENSE_RANK() OVER (
            PARTITION BY country
            ORDER BY total_disrupted_flights DESC
        ) AS disruption_rank
    FROM airport_disruptions
)
SELECT
    disruption_rank,
    country,
    airport,
    flights_cancelled,
    flights_delayed,
    flights_diverted,
    total_disrupted_flights
FROM airport_ranking
WHERE disruption_rank <= 2
ORDER BY country, disruption_rank;


-- Q16 Window Function - Rank Airlines by Daily Loss
SELECT
    ROW_NUMBER() OVER (
        ORDER BY estimated_daily_loss_usd DESC) AS row_num,
    RANK() OVER (
        ORDER BY estimated_daily_loss_usd DESC) AS loss_rank,
    airline,
    country,
    FORMAT(estimated_daily_loss_usd, 0) AS daily_loss_usd
FROM airline_losses_estimate
ORDER BY loss_rank;

-- Q17 Window Function - Running Total of Passengers Impacted
SELECT
    ROW_NUMBER() OVER (
        ORDER BY estimated_daily_loss_usd DESC) AS row_num,
    airline,
    country,
    passengers_impacted,
    SUM(passengers_impacted) OVER (
        ORDER BY estimated_daily_loss_usd DESC) AS running_total_passengers,
    ROUND(SUM(estimated_daily_loss_usd) OVER (
        ORDER BY estimated_daily_loss_usd DESC) * 100.0 /
    SUM(estimated_daily_loss_usd) OVER(), 2) AS cumulative_loss_percentage
FROM airline_losses_estimate
ORDER BY estimated_daily_loss_usd DESC;


-- Q18 CASE - Categorising Airports by Disruption Level
SELECT
    airport,
    country,
    CASE
        WHEN total_disrupted_flights >= 200 THEN 'CRITICAL'
        WHEN total_disrupted_flights >= 100 THEN 'HIGH'
        WHEN total_disrupted_flights >= 50  THEN 'MEDIUM'
        ELSE 'LOW'
    END	AS disruption_level,
    total_disrupted_flights,
    runway_status
FROM airport_disruptions
ORDER BY total_disrupted_flights DESC;

-- Q19 Subquery + CASE - Airlines Losing More Than Average Daily Loss
SELECT
    airline,
    country,
    FORMAT(estimated_daily_loss_usd, 0)              AS daily_loss_usd,
    passengers_impacted,
    CASE
        WHEN estimated_daily_loss_usd >= 3000000 THEN 'SEVERE'
        WHEN estimated_daily_loss_usd >= 2000000 THEN 'HIGH'
        WHEN estimated_daily_loss_usd >= 1000000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS loss_severity,
    FORMAT((SELECT AVG(estimated_daily_loss_usd)
            FROM airline_losses_estimate), 0) AS avg_loss_all_airlines
FROM airline_losses_estimate
WHERE estimated_daily_loss_usd > (
    SELECT AVG(estimated_daily_loss_usd)
    FROM airline_losses_estimate)
ORDER BY estimated_daily_loss_usd DESC;


-- Q20 Day by Day Timeline of Flight Cancellations
SELECT
    date,
    DAYNAME(date) AS day_name,
    MONTHNAME(date) AS month_name,
    DATEDIFF(date, '2026-02-28') AS days_since_conflict_start,
    airline,
    COUNT(cancellation_id) AS cancellations_by_airline,
    SUBSTRING(cancellation_reason, 1, 20) AS short_reason
FROM flight_cancellations
GROUP BY
    date,
    airline,
    destination,
    cancellation_reason
ORDER BY date;


-- FINAL KPI SUMMARY (KEY PERFORMANCE INDICATORS)
SELECT 'Total Conflict Events' AS kpi, FORMAT(COUNT(*), 0) AS value FROM conflict_events
UNION ALL
SELECT 'Critical Events', FORMAT(SUM(CASE WHEN severity = 'CRITICAL' THEN 1 ELSE 0 END), 0) FROM conflict_events
UNION ALL
SELECT 'High Severity Events', FORMAT(SUM(CASE WHEN severity = 'HIGH' THEN 1 ELSE 0 END), 0) FROM conflict_events
UNION ALL
SELECT 'Crisis Duration (days)', FORMAT(DATEDIFF(MAX(date), MIN(date)) + 1, 0) FROM conflict_events
UNION ALL
SELECT 'FIR Regions Closed', FORMAT(COUNT(*), 0) FROM airspace_closures
UNION ALL
SELECT 'Countries With Closures', FORMAT(COUNT(DISTINCT country), 0) FROM airspace_closures
UNION ALL
SELECT 'Avg Closure Duration (hrs)', FORMAT(ROUND(AVG(closure_duration_hours), 1), 1) FROM airspace_closures
UNION ALL
SELECT 'Max Closure Duration (hrs)', FORMAT(ROUND(MAX(closure_duration_hours), 1), 1) FROM airspace_closures
UNION ALL
SELECT 'Airports Disrupted', FORMAT(COUNT(*), 0) FROM airport_disruptions
UNION ALL
SELECT 'Total Flights Cancelled', FORMAT(COUNT(*), 0) FROM flight_cancellations
UNION ALL
SELECT 'Airlines Affected', FORMAT(COUNT(DISTINCT airline), 0) FROM flight_cancellations
UNION ALL
SELECT 'Routes Affected', FORMAT(COUNT(DISTINCT route), 0) FROM flight_cancellations
UNION ALL
SELECT 'Total Reroutes', FORMAT(COUNT(*), 0) FROM flight_reroutes
UNION ALL
SELECT 'Avg Delay Per Reroute (mins)', FORMAT(ROUND(AVG(delay_minutes), 1), 1) FROM flight_reroutes
UNION ALL
SELECT 'Total Extra Distance (km)', FORMAT(SUM(additional_distance_km), 0) FROM flight_reroutes
UNION ALL
SELECT 'Total Extra Fuel Cost (USD)', FORMAT(ROUND(SUM(additional_fuel_cost_usd), 0), 0) FROM flight_reroutes
UNION ALL
SELECT 'Total Daily Losses (USD)', FORMAT(ROUND(SUM(estimated_daily_loss_usd), 0), 0) FROM airline_losses_estimate
UNION ALL
SELECT 'Estimated 8 Day Losses (USD)', FORMAT(ROUND(SUM(estimated_daily_loss_usd) * 8, 0), 0) FROM airline_losses_estimate
UNION ALL
SELECT 'Total Passengers Impacted', FORMAT(SUM(passengers_impacted), 0) FROM airline_losses_estimate
UNION ALL
SELECT 'Avg Loss Per Passenger (USD)', FORMAT(ROUND(AVG(loss_per_passenger_usd), 2), 2) FROM airline_losses_estimate
UNION ALL
SELECT 'Highest Single Airline Loss', FORMAT(MAX(estimated_daily_loss_usd), 0) FROM airline_losses_estimate;
