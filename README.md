# US Household Income — Data Cleaning & Exploratory Data Analysis

## Overview:

Household income is one of the most relevant socioeconomic indicators for understanding inequality and wealth distribution in the United States. Using MySQL, I performed data cleaning and exploratory data analysis on a dataset with **32,533 geographic records** and **32,526 statistical records**, covering locations across all American states, with data on territorial area, mean income, and median income per census tract. After handling duplicates and inconsistencies, the analysis revealed important insights:

1. The states with the largest territorial area are not necessarily the ones with the highest average household income.
2. The area type (City, Town, Borough, CDP, Track, etc.) has a direct influence on the observed mean and median income.
3. There is significant income variation between cities and states, highlighting regional inequality within the US.

---

### Context and Objectives:

Understanding how household income is geographically distributed across the United States is essential for public policy, urban planning, and socioeconomic analysis. With raw data containing duplicates, typos, and inconsistent values, it is necessary to first ensure data quality before answering questions such as:

- Which states have the highest average household income?
- Is there a relationship between area type (City, Town, Borough) and income level?
- What are the wealthiest cities in the United States?
- How is territorial area (land and water) distributed across states?

---

### Methodology:

1. **Data Cleaning in SQL:**
   - Fixed the `id` column name affected by the UTF-8 BOM (Byte Order Mark) via `ALTER TABLE RENAME COLUMN`.
   - Removed duplicate records using `ROW_NUMBER()` and `PARTITION BY`.
   - Corrected typos in state names (`'georia'` → `'Georgia'`, `'alabama'` → `'Alabama'`).
   - Standardized categories in the `Type` column (`'Boroughs'` → `'Borough'`).
   - Fixed incorrect values in the `Place` column for Autauga County records.
   - Checked for null, empty, or zero values in the `ALand` and `AWater` columns.

2. **Exploratory Data Analysis (EDA) in SQL:**
   - Ranking of the top 10 states by land and water area.
   - Joined the geographic and statistical tables via `JOIN` on the census key (`id`).
   - Detected orphaned records between tables using `RIGHT JOIN`.
   - Ranking of the top 10 states by highest average household income.
   - Comparative analysis of mean and median income by area type, with a minimum sample filter (`HAVING > 100`).
   - Ranking of the wealthiest cities by State + City combination.

---

### Technical Skills:

**SQL (MySQL):** Window Functions (`ROW_NUMBER`), `PARTITION BY`, `JOIN` / `INNER JOIN` / `RIGHT JOIN`, Aggregate Functions (`AVG`, `SUM`, `COUNT`), `GROUP BY`, `HAVING`, `ROUND`, `ORDER BY`, `LIMIT`, Subqueries, `DELETE` with subquery, `UPDATE`, `ALTER TABLE`, `DISTINCT`, `NULL` handling.

---

### Results and Conclusions:

Data cleaning ensured dataset integrity by removing duplicates, fixing state name typos, and standardizing categories, making subsequent analyses reliable. The exploratory data analysis revealed the following insights:

- **Territorial area:** The largest states by land area were identified by summing `ALand`, with Texas and Alaska among the leaders, confirming well-known geographic data.

- **Income by state:** The top 10 states with the highest average household income were identified, allowing visualization of which regions concentrate the greatest per capita wealth in the US.

- **Area type and income:** Different location types show distinct income patterns. The analysis filtered only categories with more than 100 records to avoid small sample distortions, revealing significant differences between types such as City, Town, Track, and CDP.

- **Orphaned data:** The `RIGHT JOIN` check identified records in the statistics table with no match in the geographic table, highlighting inconsistencies in the original census data.

- **City ranking:** The city-level ranking revealed which specific locations have the highest mean and median incomes, enabling a granular analysis of wealth distribution.

---

### Next Steps:

1. Build an interactive dashboard (Power BI / Tableau) to visualize income distribution by state and city on geographic maps.
2. Create Python visualizations (Matplotlib, Seaborn) to explore distributions and correlations between income and territorial area.
3. Expand the analysis to include regional comparisons (Northeast, South, Midwest, West).
4. Deepen the analysis by income brackets to identify inequality patterns within each state.

---

### Author:

Project developed by **Giovany César** as part of the **MySQL for Data Analytics** course by Alex Freberg.
