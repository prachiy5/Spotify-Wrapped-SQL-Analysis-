-- TEMP TABLE FOR STREAMING HISTORY DATA FOR 2023
SELECT 
    timestamp,
    CONVERT(DATE, timestamp) AS play_date, 
    YEAR(timestamp) AS year,
    MONTH(timestamp) AS month,
    CAST(play_duration AS BIGINT) AS play_duration, 
    track_name, 
    artist_name, 
    album_name
INTO #temp_streaming_history
FROM streaming_history
WHERE YEAR(timestamp) = 2023;



-- CHECKING DATE RANGE
SELECT MIN(play_date) AS start_date, MAX(play_date) AS end_date 
FROM #temp_streaming_history;



-- TOTAL TIME SPENT LISTENING TO MUSIC
SELECT SUM(play_duration)/60000 AS total_duration_in_mins 
FROM #temp_streaming_history;

-- TOP 5 ARTISTS BY NUMBER OF PLAYS
SELECT TOP 5 artist_name, COUNT(*) AS number_of_times_you_listened_to_this_artist  
FROM #temp_streaming_history
GROUP BY artist_name
ORDER BY 2 DESC;

-- TOP 5 ARTISTS BY TOTAL PLAY DURATION
SELECT TOP 5
    artist_name,
    SUM(play_duration) / 60000 AS duration_in_mins
FROM #temp_streaming_history
GROUP BY artist_name
ORDER BY duration_in_mins DESC;

-- TOP 5 MOST PLAYED SONGS BY NUMBER OF PLAYS
SELECT TOP 5 track_name, COUNT(*) AS number_of_times 
FROM #temp_streaming_history
GROUP BY track_name
ORDER BY 2 DESC;

-- TOP 5 MOST PLAYED SONGS BY TOTAL DURATION
SELECT TOP 5 track_name, SUM(play_duration)/60000 AS total_duration_in_mins
FROM #temp_streaming_history
GROUP BY track_name
ORDER BY 2 DESC;

-- TOP STREAMED ALBUMS BY NUMBER OF PLAYS
SELECT TOP 5 album_name, COUNT(*) AS number_of_times_streamed_album 
FROM #temp_streaming_history
GROUP BY album_name
ORDER BY 2 DESC;

-- TOP STREAMED ALBUMS BY TOTAL DURATION
SELECT TOP 5 album_name, SUM(play_duration)/60000 AS total_duration_in_mins
FROM #temp_streaming_history
GROUP BY album_name
ORDER BY 2 DESC;

-- SINGLE LONGEST TRACK BY PLAY DURATION
SELECT TOP 1
    track_name,
    artist_name,
    play_duration / 60000 AS play_duration_in_mins
FROM #temp_streaming_history
ORDER BY play_duration DESC;

-- MONTH WITH THE MOST MUSIC PLAYED (BY TOTAL DURATION)
WITH cte AS (
    SELECT month, SUM(play_duration)/60000 AS total_duration_in_minutes 
    FROM #temp_streaming_history
    GROUP BY month
)
SELECT 
    DATENAME(MONTH, DATEADD(MONTH, month - 1, '1900-01-01')) AS month_name, 
    total_duration_in_minutes 
FROM cte 
ORDER BY total_duration_in_minutes DESC;

-- TOP SONG FOR EACH MONTH
WITH MonthlyTopSongs AS (
    SELECT 
        month, 
        track_name, 
        SUM(play_duration) / 60000 AS total_duration_in_minutes,
        ROW_NUMBER() OVER (PARTITION BY month ORDER BY SUM(play_duration) DESC) AS song_rank
    FROM #temp_streaming_history
    GROUP BY month, track_name
)
SELECT 
    DATENAME(MONTH, DATEADD(MONTH, month - 1, '1900-01-01')) AS month_name,
    track_name AS top_song,
    total_duration_in_minutes
FROM MonthlyTopSongs
WHERE song_rank = 1
ORDER BY month;

-- TOP SONG FOR EACH SEASON
WITH SeasonalSongs AS (
    SELECT 
        CASE 
            WHEN MONTH(play_date) IN (3, 4, 5) THEN 'Spring'
            WHEN MONTH(play_date) IN (6, 7, 8) THEN 'Summer'
            WHEN MONTH(play_date) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END AS season,
        track_name AS top_song,
        SUM(play_duration) / 60000 AS total_duration_in_minutes
    FROM #temp_streaming_history
    GROUP BY 
        CASE 
            WHEN MONTH(play_date) IN (3, 4, 5) THEN 'Spring'
            WHEN MONTH(play_date) IN (6, 7, 8) THEN 'Summer'
            WHEN MONTH(play_date) IN (9, 10, 11) THEN 'Fall'
            ELSE 'Winter'
        END, 
        track_name
)
SELECT season, top_song, total_duration_in_minutes
FROM (
    SELECT 
        season, 
        top_song, 
        total_duration_in_minutes,
        ROW_NUMBER() OVER (PARTITION BY season ORDER BY total_duration_in_minutes DESC) AS song_rank
    FROM SeasonalSongs
) AS Ranked
WHERE song_rank = 1
ORDER BY 
    CASE season 
        WHEN 'Spring' THEN 1 
        WHEN 'Summer' THEN 2 
        WHEN 'Fall' THEN 3 
        WHEN 'Winter' THEN 4 
    END;

-- MOST MUSIC-FILLED DAY OF THE YEAR
SELECT top 1 play_date, SUM(play_duration)/60000 AS total_duration_in_minutes 
FROM #temp_streaming_history
GROUP BY play_date
ORDER BY 2 DESC;

-- MOST POPULAR TIME OF DAY FOR LISTENING (in UTC)
SELECT TOP 1 DATEPART(hour, timestamp) AS hour_of_day, SUM(play_duration)/60000 AS total_duration_in_minutes
FROM #temp_streaming_history
GROUP BY DATEPART(hour, timestamp)
ORDER BY 2 DESC;

-- TOTAL NUMBER OF UNIQUE ARTISTS LISTENED TO
SELECT COUNT(DISTINCT artist_name) AS number_of_unique_artists 
FROM #temp_streaming_history;

-- TOTAL NUMBER OF UNIQUE SONGS PLAYED
SELECT COUNT(DISTINCT track_name) AS unique_songs_you_played 
FROM #temp_streaming_history;

-- LONGEST LISTENING STREAK
WITH cte AS (
    SELECT play_date, DENSE_RANK() OVER (ORDER BY play_date) AS rn 
    FROM #temp_streaming_history
),
cte2 AS (
    SELECT play_date, DATEADD(DAY, -rn, play_date) AS gap 
    FROM cte
)
SELECT TOP 1
    MIN(play_date) AS streak_start_date,
    MAX(play_date) AS streak_end_date,
    DATEDIFF(DAY, MIN(play_date), MAX(play_date)) + 1 AS streak_length
FROM cte2
GROUP BY gap
ORDER BY streak_length DESC;

-- TOP SONG FOR EACH OF YOUR TOP 5 ARTISTS
WITH TopArtists AS (
    SELECT TOP 5
        artist_name,
        SUM(play_duration) / 60000 AS total_duration
    FROM #temp_streaming_history
    GROUP BY artist_name
    ORDER BY total_duration DESC
),
TopSongs AS (
    SELECT 
        t.artist_name, 
        t.track_name, 
        COUNT(*) AS number_of_plays,
        ROW_NUMBER() OVER (PARTITION BY t.artist_name ORDER BY COUNT(*) DESC) AS song_rank
    FROM #temp_streaming_history t
    INNER JOIN TopArtists ta ON t.artist_name = ta.artist_name
    GROUP BY t.artist_name, t.track_name
)
SELECT 
    ta.artist_name, 
    ts.track_name AS top_song, 
    ts.number_of_plays,
    ta.total_duration
FROM TopArtists ta
INNER JOIN TopSongs ts ON ta.artist_name = ts.artist_name
WHERE ts.song_rank = 1
ORDER BY ta.total_duration DESC;

-- TOTAL NUMBER OF SONGS SKIPPED OR PLAYED FOR LESS THAN 30 SECONDS
SELECT COUNT(*) AS num_of_songs 
FROM streaming_history
WHERE play_duration < 30000;



---

SELECT 
    COUNT(DISTINCT artist_name) AS unique_artists,
    COUNT(DISTINCT track_name) AS unique_songs,
    COUNT(DISTINCT album_name) AS unique_albums
FROM #temp_streaming_history;

---Which artist dominated your playlist each month

WITH cte AS (
    SELECT artist_name, 
    FORMAT(timestamp, 'MMM') AS month,
    SUM(play_duration)/60000 AS total_duration_in_minutes
    FROM #temp_streaming_history
    GROUP BY artist_name, FORMAT(timestamp, 'MMM')
),
cte2 AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY month ORDER BY total_duration_in_minutes DESC) AS rn
    FROM cte
)
SELECT artist_name, month, total_duration_in_minutes 
FROM cte2
WHERE rn = 1
ORDER BY month;
