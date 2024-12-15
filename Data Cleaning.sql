select * from streaming_history

--count of nulls for each column
SELECT 
    SUM(CASE WHEN timestamp IS NULL THEN 1 ELSE 0 END) AS timestamp_nulls,
    SUM(CASE WHEN play_duration IS NULL THEN 1 ELSE 0 END) AS play_duration_nulls,
    SUM(CASE WHEN track_name IS NULL THEN 1 ELSE 0 END) AS track_name_nulls,
    SUM(CASE WHEN artist_name IS NULL THEN 1 ELSE 0 END) AS artist_name_nulls,
    SUM(CASE WHEN album_name IS NULL THEN 1 ELSE 0 END) AS album_name_nulls
FROM streaming_history;

--rows with null values
SELECT *
FROM streaming_history
WHERE timestamp IS NULL 
   OR play_duration IS NULL 
   OR track_name IS NULL 
   OR artist_name IS NULL 
   OR album_name IS NULL;

-- delete the rows with null value:

DELETE FROM streaming_history
WHERE play_duration IS NULL 
   OR track_name IS NULL 
   OR artist_name IS NULL 
   OR album_name IS NULL;


 --checking data type

 SELECT DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'streaming_history'
  AND COLUMN_NAME = 'play_duration';

  --changing data type:
 ALTER TABLE streaming_history
ALTER COLUMN play_duration BIGINT;




