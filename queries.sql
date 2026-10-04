SELECT Segment,
       COUNT(*) AS listings,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM listings), 1) AS share_pct,
       ROUND(AVG(CAST(price AS REAL)), 0) AS avg_price_eur,
       ROUND(AVG(CAST(NULLIF(review_scores_rating, '') AS REAL)), 2) AS avg_rating
FROM listings
GROUP BY Segment
ORDER BY listings DESC;

-- Query 2: hotel listings by district
SELECT neighbourhood_group_cleansed AS district,
       COUNT(*) AS hotel_listings,
       ROUND(AVG(CAST(price AS REAL)), 0) AS avg_hotel_price_eur
FROM listings
WHERE Segment = 'Hotel'
GROUP BY district
ORDER BY hotel_listings DESC;

-- Query 3: demand vs hotel supply by district
SELECT neighbourhood_group_cleansed AS district,
       SUM(CAST(estimated_occupancy_l365d AS INTEGER)) AS est_booked_nights,
       SUM(CAST(number_of_reviews_ltm AS INTEGER)) AS reviews_last_12m,
       COUNT(*) AS all_listings,
       SUM(CASE WHEN Segment = 'Hotel' THEN 1 ELSE 0 END) AS hotel_listings,
       ROUND(100.0 * SUM(CASE WHEN Segment = 'Hotel' THEN 1 ELSE 0 END) / COUNT(*), 1) AS hotel_share_pct
FROM listings
GROUP BY district
ORDER BY est_booked_nights DESC;

--Query 3b: demand share vs hotel share by district
WITH d AS (
  SELECT neighbourhood_group_cleansed AS district,
         SUM(CAST(estimated_occupancy_l365d AS INTEGER)) AS nights,
         SUM(CASE WHEN Segment = 'Hotel' THEN 1 ELSE 0 END) AS hotels
  FROM listings
  GROUP BY district
)
SELECT district,
       ROUND(100.0 * nights / (SELECT SUM(nights) FROM d), 1) AS demand_share_pct,
       ROUND(100.0 * hotels / (SELECT SUM(hotels) FROM d), 1) AS hotel_share_pct,
       ROUND(100.0 * nights / (SELECT SUM(nights) FROM d)
           - 100.0 * hotels / (SELECT SUM(hotels) FROM d), 1) AS gap_pts
FROM d
ORDER BY gap_pts DESC;

--Query 4: hotels vs apartments by district, incl. price per guest
SELECT neighbourhood_group_cleansed AS district,
       Segment,
       COUNT(*) AS listings,
       ROUND(AVG(CAST(price AS REAL)), 0) AS avg_price_eur,
       ROUND(AVG(CAST(price AS REAL) / NULLIF(CAST(accommodates AS REAL), 0)), 0) AS avg_price_per_guest_eur,
       ROUND(AVG(CAST(NULLIF(review_scores_rating, '') AS REAL)), 2) AS avg_rating
FROM listings
WHERE Segment IN ('Hotel', 'Apartment')
GROUP BY district, Segment
ORDER BY district, Segment;

--Query 5: largest hotel operators
SELECT host_id,
       host_name,
       COUNT(*) AS hotel_listings,
       COUNT(DISTINCT neighbourhood_group_cleansed) AS districts_covered,
       ROUND(AVG(CAST(price AS REAL)), 0) AS avg_price_eur,
       ROUND(AVG(CAST(NULLIF(review_scores_rating, '') AS REAL)), 2) AS avg_rating
FROM listings
WHERE Segment = 'Hotel'
GROUP BY host_id, host_name
ORDER BY hotel_listings DESC
LIMIT 15;

--Query 5b: hotel operators in the two opportunity districts
SELECT neighbourhood_group_cleansed AS district,
       host_name,
       COUNT(*) AS hotel_listings,
       ROUND(AVG(CAST(NULLIF(review_scores_rating, '') AS REAL)), 2) AS avg_rating
FROM listings
WHERE Segment = 'Hotel'
  AND neighbourhood_group_cleansed IN ('Pankow', 'Friedrichshain-Kreuzberg')
GROUP BY district, host_id, host_name
ORDER BY district, hotel_listings DESC;