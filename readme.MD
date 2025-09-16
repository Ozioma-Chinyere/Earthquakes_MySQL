# 🌍 Earthquake Database SQL Project

This project creates, populates, and analyzes an **Earthquake Database** using MySQL.  
It demonstrates how to build a schema, create a table and a view, load raw data, and perform **exploratory data analysis (EDA)** with SQL queries.  
The dataset includes earthquake events, their causes, locations, magnitudes, depths, and related metadata.  

---

## 📂 Project Structure
The SQL script performs the following steps:

1. **Database & Table Creation**
   - Creates a database `earthquakes`
   - Creates a main table `earthquake_tb` with columns:
     - `earthquake_id` (Primary Key)
     - `occurred_on` (timestamp of earthquake)
     - `latitude`, `longitude`
     - `depth`, `magnitude`
     - `calculation_method`
     - `network_id`
     - `place`
     - `cause`

2. **Data Loading**
   - Loads earthquake data from CSV:
     ```sql
     LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/input_files/dbin_earthquake.csv'
     INTO TABLE earthquake_tb
     FIELDS TERMINATED BY ','
     OPTIONALLY ENCLOSED BY '"'
     LINES TERMINATED BY '\n'
     IGNORE 1 ROWS;
     ```

3. **Exploratory Data Analysis (EDA)**
   - Earthquake counts by **cause**
   - Places affected by **nuclear explosions**, **explosions**, and **natural earthquakes**
   - Frequency of earthquakes by **magnitude** and **depth**
   - Distribution of **calculation methods**
   - Outlier detection for depth and magnitude
   

4. **Views & Categorization**
   - Creates a view `earthquake_vw` with:
     - Extracted `year` and `month` from `occurred_on`
     - **Magnitude categories**:
       - Great (≥ 8.0)
       - Major (7.0–7.9)
       - Strong (6.0–6.9)
       - Moderate (5.0–5.9)
       - Light (4.0–4.9)
       - Minor (3.0–3.9)
       - Micro (< 3.0)
     - **Depth categories**:
       - Shallow (≤ 70 km)
       - Intermediate (>70–300 km)
       - Deep (> 300 km)


5. **Time-Series Analysis**
   - Earthquake distribution over **50 years**
   - Earthquake **yearly trends**, including:
     - Top 5 years with most earthquakes
     - Most devastating earthquakes (magnitude ≥ 9)
     - Analysis of **foreshocks** and **aftershocks**
   - Impact of major events:
     - **2004 Northern Sumatra (9.1)**
     - **2011 Honshu, Japan (9.1)**
   - Aftershock patterns
   - Month-by-month earthquake frequency


---

## 📈 **Key Insights**
- Most common cause: Natural earthquakes (Occurred 22942 times across 2934 locations).
- Explosions: Rare - Found 4 times and in 3 places; all shallow.
- Nuclear explosions: Found 173 times and in 18 places; all shallow.
- Major hotspots: Northern Sumatra, Honshu (Japan), Antofagasta (Chile).
- Aftershocks: Great earthquakes (> 8.0) generate significant aftershock activity.
- Years with the most earthquakes in descending order: 2011, 2007, 1995, 2004, 2010.
- No earthquake "season" — monthly spikes are tied to individual catastrophic events.
- The 2011 magnitude 9.1 earthquake in Honshu, Japan generated massive aftershock, causing the spike in 2011 count and March count.


---

## 🛠️ Requirements
- **MySQL Server 8.0+**
- CSV earthquake dataset (`dbin_earthquake.csv`) 
