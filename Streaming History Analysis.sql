
--temp table
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





SELECT * FROM streaming_history;
--checking date range

select min(play_date) as start_date, max(play_date) as end_date from #temp_streaming_history


----How much time did you spend listening to music this year?

select sum(play_duration)/60000 as total_duration_in_mins from  #temp_streaming_history

--Who were your top 5 most listened-to artists this year?"
--Calculation: Group by artist_name, count rows or sum play_duration, and rank.

--by number of plays
select artist_name,count(*) number_of_times_you_listened_to_this_artist  from  #temp_streaming_history
group by artist_name
order by 2 desc

-- by play_duration

SELECT top 5
    artist_name,
    SUM(play_duration) / 60000 AS duration_in_mins
FROM  #temp_streaming_history
GROUP BY artist_name
ORDER BY duration_in_mins DESC;

--"What were your top 5 most played songs?"
--Calculation: Group by track_name, count rows or sum play_duration, and rank.

--by number_of_times
select top 1 track_name, count(*) as number_of_times from  #temp_streaming_history
group by track_name
order by 2 desc

--by total duration
select top 5 track_name, sum(play_duration)/60000 as  total_duration_in_mins
from  #temp_streaming_history
group by track_name
order by 2 desc

--"Which albums did you stream the most?"
--Calculation: Group by album_name, count rows or sum play_duration, and rank.

--by times
select album_name,count(*) as number_of_times_streamed_album 
from  #temp_streaming_history
group by album_name
order by 2 desc

--by duration

select album_name,sum(play_duration)/60000 as  total_duration_in_mins
from  #temp_streaming_history
group by album_name
order by 2 desc

--"What is the single longest track (by play duration) you listened to?"
--Calculation: Identify the maximum play_duration and corresponding track_name.

SELECT TOP 1
    track_name,
    artist_name,
    play_duration / 60000 AS play_duration_in_mins
FROM  #temp_streaming_history
ORDER BY play_duration DESC;

--"Which month did you listen to the most music?"(By Total Listening Duration (Most Accurate Interpretation))
--Calculation: Extract the month from play_date, group by month, and sum 

with cte as (select month, sum(play_duration)/60000 as total_duration_in_minutes from #temp_streaming_history
group by month)

select datename(month, dateadd(month,month-1,'1900-01-01')) as month_name, total_duration_in_minutes 
from cte 
order by total_duration_in_minutes desc


--top song per month

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

--- top song per season:

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



--"What was your most music-filled day of the year?"
--Calculation: Group by play_date and sum play_duration.

select play_date, sum(play_duration)/60000 as total_duration_in_minutes 
from #temp_streaming_history
group by play_date
order by 2 desc




--"What time of day do you listen to music the most?"
--Calculation: Extract the hour from timestamp, group by hour, and sum play_duration.

select datepart(hour,timestamp) as hour_of_day , sum(play_duration)/60000 as total_duration_in_minutes
from  #temp_streaming_history
group by datepart(hour,timestamp)
order by 2 desc

--"How many unique artists did you listen to this year?"
--Calculation: Count distinct artist_name.

select count(distinct artist_name) as number_of_unique_artists from  #temp_streaming_history

--"How many different songs did you play?"
--Calculation: Count distinct track_name.

select count(distinct track_name)as unique_songs_you_played from  #temp_streaming_history



--"Which artist or song dominated your listening streaks?"
--Calculation: Analyze consecutive days or repeated play of the same artist or track.

with cte as (
    select 
        play_date,
        track_name,
        row_number() over (partition by track_name order by play_date) as row_num
    from #temp_streaming_history
),
streaks as (
    select 
        track_name,
        play_date,
        datediff(day, row_num, play_date) as streak_group 
    from cte
)
select 
    track_name, 
    count(*) as streak_length
from streaks
group by track_name, streak_group
order by streak_length desc;




--How many songs did you skip or play for less than 30 seconds?"
select  count(*) as num_of_songs from streaming_history
where play_duration < 30000

--"Who dominated your playlist each month?"
--Calculation: Group by month and artist_name, then rank by play count or duration.

with cte as(select artist_name, 
format(timestamp, 'MMM') as month,
sum(play_duration)/60000 as total_duration_in_minutes
from #temp_streaming_history
group by artist_name, FORMAT(timestamp, 'MMM')
),

cte2 as(select *, dense_rank() over(partition by month order by total_duration_in_minutes desc) as rn
from cte)

select artist_name,month,total_duration_in_minutes from cte2
where rn=1
order by 
    month(try_convert(date, '2023-' + month + '-01')); -- Chronological month order

--"How many consecutive days did you listen to music?"
--Calculation: Analyze gaps in play_date to identify streaks.

WITH cte AS (
    SELECT 
         play_date, -- Extract only the date
        DENSE_RANK() OVER (ORDER BY play_date) AS rn -- Rank unique dates sequentially
    FROM #temp_streaming_history
),
cte2 AS (
    SELECT 
        play_date,
        DATEADD(DAY, -rn, play_date) AS gap -- Group consecutive days into streaks
    FROM cte
)
SELECT top 1
    MIN(play_date) AS streak_start_date, -- Start of the streak
    MAX(play_date) AS streak_end_date, -- End of the streak
    DATEDIFF(DAY, MIN(play_date), MAX(play_date)) + 1 AS streak_length -- Actual consecutive days
FROM cte2
GROUP BY gap
ORDER BY streak_length DESC; -- Longest streak at the top


--"How many unique artists, songs, and albums did you explore?"
--Calculation: Count distinct artist_name, track_name, and album_name

select  
    count(distinct artist_name) as unique_artists,
    count(distinct track_name) as unique_tracks,
    count(distinct album_name) as unique_albums
from #temp_streaming_history;

select count(track_name) from #temp_streaming_history




-- top songs for top artist

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
    artist_name, 
    track_name AS top_song, 
    number_of_plays
FROM TopSongs
WHERE song_rank = 1
ORDER BY number_of_plays desc;



---------------------------------

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
ORDER BY ta.total_duration DESC; -- P
