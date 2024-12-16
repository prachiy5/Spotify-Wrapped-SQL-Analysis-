# 🎵 Spotify Wrapped SQL Analysis  

This project replicates the **Spotify Wrapped experience** by analyzing personal streaming history data using **SQL**. The analysis uncovers top songs, artists, albums, listening trends, and patterns for the year **2023**.

---

## 📋 Project Overview  

I requested my **Spotify Extended Streaming History**, which contained listening data spanning from **July 2022 to February 2024**. However, for this analysis, I focused solely on the data for **January 1, 2023, to December 31, 2023**, to evaluate my music habits over one full year.  

---

## 🛠️ Data Preparation  

### 🔍 Missing Data  
Upon thorough inspection, I noticed **388 missing rows** in the dataset. After researching, I found that:  

- Missing information can occur due to **technical glitches** during Spotify's data collection.  
- Known issues can cause incomplete records, such as missing identifiers or delayed updates.  

Since the missing values were consistent across all relevant columns, I decided to **remove those rows**, ensuring they **did not impact the accuracy** of my analysis.  

### 🔧 Data Cleaning  
Before importing the data into **SQL Server**, I:  
- **Removed unnecessary columns** that were not relevant for my analysis.  
- Focused on the required fields:  
  - `timestamp`  
  - `track_name`  
  - `artist_name`  
  - `album_name`  
  - `play_duration`
    
**Note:** The `play_duration` field in the dataset is recorded in **milliseconds**. To calculate the duration in **minutes**, I divided the `play_duration` by **60000** (1 minute = 60,000 milliseconds) in all relevant queries.

---

## 📊 Analysis and Insights  

This project uses SQL queries to answer the following questions:  

1. **How much time did you spend listening to music in 2023?**
```sql
SELECT SUM(play_duration)/60000 AS total_duration_in_mins 
FROM #temp_streaming_history;
```
| Total Duration (in mins) | 
|--------------------------|
| 18,521                   | 

---

3. **Who were your top 5 most listened-to artists?**
  **by number of plays**
```sql
SELECT TOP 5 artist_name, COUNT(*) AS number_of_times_you_listened_to_this_artist  
FROM #temp_streaming_history
GROUP BY artist_name
ORDER BY 2 DESC;
```
| Artist Name     | Number of Times You Listened to This Artist |
|------------------|--------------------------------------------|
| Pritam          | 296                                        |
| Eminem          | 247                                        |
| Prateek Kuhad   | 229                                        |
| Atif Aslam      | 226                                        |
| A.R. Rahman     | 210                                        |

**by duration**
```sql
SELECT TOP 5
    artist_name,
    SUM(play_duration) / 60000 AS duration_in_mins
FROM #temp_streaming_history
GROUP BY artist_name
ORDER BY duration_in_mins DESC;
```
| Artist Name     | Duration (in Minutes) |
|------------------|-----------------------|
| Eminem          | 862                   |
| Pritam          | 682                   |
| Taylor Swift    | 507                   |
| A.R. Rahman     | 497                   |
| Atif Aslam      | 481                   |

---

5. **What were your top 5 most played songs (by plays and duration)?**
   **by number of plays**
```sql
SELECT TOP 5 track_name, COUNT(*) AS number_of_times 
FROM #temp_streaming_history
GROUP BY track_name
ORDER BY 2 DESC;
```
| Track Name                                             | Number of Times |
|--------------------------------------------------------|-----------------|
| Tere Bina                                             | 38              |
| Kahaan Ho Tum                                         | 36              |
| Mere Liye Tum Kaafi Ho                                | 34              |
| Tu Hi Hai                                             | 32              |
| Sooraj Ki Baahon Mein                                 | 31              |

**by duration**
```sql
SELECT TOP 5 track_name, SUM(play_duration)/60000 AS total_duration_in_mins
FROM #temp_streaming_history
GROUP BY track_name
ORDER BY 2 DESC;
```
| Track Name   | Total Duration (in Minutes) |
|--------------|-----------------------------|
| Hey Ya !     | 95                          |
| Tere Bina    | 87                          |
| Mulaqat      | 82                          |
| Aise Kyun    | 77                          |
| Co2          | 70                          |

---

7. **Which albums did you stream the most?**
**by number of plays**
```sql
SELECT album_name, COUNT(*) AS number_of_times_streamed_album 
FROM #temp_streaming_history
GROUP BY album_name
ORDER BY 2 DESC;
```
| Album Name                                               | Number of Times Streamed Album |
|----------------------------------------------------------|---------------------------------|
| Midnights                                                | 92                              |
| Zindagi Na Milegi Dobara                                 | 69                              |
| Mismatched: Season 1                                     | 67                              |
| Love, Sex and Murder?                                    | 59                              |
| Genesis 1:1                                              | 57                              |

**by duration**
```sql
SELECT album_name, SUM(play_duration)/60000 AS total_duration_in_mins
FROM #temp_streaming_history
GROUP BY album_name
ORDER BY 2 DESC;
``` 
9. **What was the single longest track you listened to?**
  ```sql
SELECT TOP 1
    track_name,
    artist_name,
    play_duration / 60000 AS play_duration_in_mins
FROM #temp_streaming_history
ORDER BY play_duration DESC;
```
| Album Name              | Total Duration (in Minutes) |
|--------------------------|-----------------------------|
| Midnights               | 218                         |
| Curtain Call 2          | 201                         |
| Aalas Ka Pedh           | 144                         |
| Love, Sex and Murder?   | 141                         |
| Zindagi Na Milegi Dobara | 141                        |

---

11. **Which month did you listen to the most music?**
```sql
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
```
| Month Name  | Total Duration (in Minutes) |
|-------------|-----------------------------|
| November    | 2797                        |
| October     | 2464                        |
| December    | 2240                        |
| May         | 1928                        |
| April       | 1896                        |
| September   | 1823                        |
| February    | 1547                        |
| August      | 1012                        |
| March       | 1012                        |
| July        | 806                         |
| January     | 585                         |
| June        | 406                         |
---
13. **What were the top songs for each month and season?**
**top song for each month**
```sql
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
```
| Month Name  | Top Song                                    | Total Duration (in Minutes) |
|-------------|---------------------------------------------|-----------------------------|
| January     | Iktara - MTV Unplugged Version             | 9                           |
| February    | Sanchariyagu Nee (From "Love Mocktail 2")  | 17                          |
| March       | Adiye                                      | 45                          |
| April       | Mera Yaar                                  | 17                          |
| May         | If the World Was Ending                    | 26                          |
| June        | Munjaane Manjalli                          | 11                          |
| July        | California Love - Original Version         | 17                          |
| August      | Jeena Jeena                                | 15                          |
| September   | Luka Chuppi                                | 24                          |
| October     | Tera Mera Rishta                           | 40                          |
| November    | Mulaqat                                    | 60                          |
| December    | Jahan Mein Aesa Kaun Hai                   | 43                          |

**top songs for each season**
```sql
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
```
| Season  | Top Song                  | Total Duration (in Minutes) |
|---------|---------------------------|-----------------------------|
| Spring  | Adiye                    | 45                           |
| Summer  | Nas Is Like              | 17                           |
| Fall    | Mulaqat                  | 64                           |
| Winter  | Jahan Mein Aesa Kaun Hai | 43                           |
---

15. **What was your most music-filled day?**
  ```sql
SELECT play_date, SUM(play_duration)/60000 AS total_duration_in_minutes 
FROM #temp_streaming_history
GROUP BY play_date
ORDER BY 2 DESC;
```
| Play Date   | Total Duration (in Minutes) |
|-------------|-----------------------------|
| 2023-05-10  | 525                         |
---

17. **What time of day did you listen to music the most?**
```sql
SELECT DATEPART(hour, timestamp) AS hour_of_day, SUM(play_duration)/60000 AS total_duration_in_minutes
FROM #temp_streaming_history
GROUP BY DATEPART(hour, timestamp)
ORDER BY 2 DESC;
```
| Hour of Day | Total Duration (in Minutes) |
|-------------|-----------------------------|
| 11          | 1621                        |

---
19. **How many unique artists, songs, and albums did you explore?**
  ```sql
SELECT 
    COUNT(DISTINCT artist_name) AS unique_artists,
    COUNT(DISTINCT track_name) AS unique_songs,
    COUNT(DISTINCT album_name) AS unique_albums
FROM #temp_streaming_history;
```
| Unique Artists | Unique Songs | Unique Albums |
|----------------|--------------|---------------|
| 1032           | 3094         | 2308          |

---


23. **How many consecutive days did you listen to music?**
```sql
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
```
| Streak Start Date | Streak End Date | Streak Length (in Days) |
|-------------------|-----------------|-------------------------|
| 2023-10-27        | 2023-11-28      | 33                      |

---
 
25. **How many songs did you skip or play for less than 30 seconds?**
  ```sql
SELECT COUNT(*) AS num_of_songs 
FROM streaming_history
WHERE play_duration < 30000;
```
| Number of Songs |
|-----------------|
| 8398           |

---

27. **Which artist dominated your playlist each month?**
```sql
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
```
| Artist Name   | Month | Total Duration (in Minutes) |
|---------------|-------|-----------------------------|
| Maroon 5      | Apr   | 130                         |
| Atif Aslam    | Aug   | 155                         |
| Eminem        | Dec   | 219                         |
| Eminem        | Feb   | 227                         |
| Taylor Swift  | Jan   | 50                          |
| Taylor Swift  | Jul   | 89                          |
| Taylor Swift  | Jun   | 117                         |
| Eminem        | Mar   | 136                         |
| Eminem        | May   | 154                         |
| Pritam        | Nov   | 197                         |
| Pritam        | Oct   | 99                          |
| Taylor Swift  | Sep   | 143                         |

---

29. **What were the top songs for your top artists?**
```sql
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

```
| Artist Name   | Top Song              | Number of Plays | Total Duration (in Minutes) |
|---------------|-----------------------|-----------------|-----------------------------|
| Eminem        | Sing For The Moment  | 13              | 862                         |
| Pritam        | Tu Chahiye           | 22              | 682                         |
| Taylor Swift  | Anti-Hero            | 14              | 507                         |
| A.R. Rahman   | Nazar Laaye - Reprise| 19              | 497                         |
| Atif Aslam    | Jeena Jeena          | 23              | 481                         |

---

## 💻 SQL Queries  

All SQL queries are included in the **`spotify_wrapped_analysis.sql`** file.  

**Key Highlights**:  
- **Temporary table** creation to filter 2023 data.  
- Use of **window functions** (`ROW_NUMBER`, `DENSE_RANK`) for ranking and streak analysis.  
- Queries to calculate **monthly trends**, **seasonal top songs**, and **longest listening streaks**.  

---

## 📈 Key Features  

- **Top Songs and Artists**: Identify most-played songs and artists based on play count and duration.  
- **Monthly and Seasonal Insights**: Discover listening trends over the year.  
- **Listening Streaks**: Find the longest consecutive days you listened to music.  
- **Unique Exploration**: Quantify how many new artists, songs, and albums you explored.  
- **Listening Hours**: Pinpoint the time of day when you listened to music the most.  

---

## 🛠️ Tools Used  

- **Spotify Extended History Data**  
- **SQL Server**  
  

---

## 📊 Results  

This analysis successfully mimics a personalized **Spotify Wrapped** experience by uncovering meaningful patterns and habits in my music streaming history for **2023**.  

---

## 📁 File Structure  

- **`spotify_wrapped_analysis.sql`**: Contains all SQL queries used for the analysis.  
- **Data Preparation Steps**: Documented through comments within the SQL file.  


---

  

