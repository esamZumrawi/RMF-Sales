
-- 1\ append all momthly sales tables together
USE rmf1920;
GO

IF OBJECT_ID('dbo.sales2025', 'U') IS NOT NULL
    DROP TABLE rmf1920.dbo.sales2025;

SELECT *
INTO rmf1920.dbo.sales2025
FROM (
    SELECT * FROM rmf1920.dbo.sales202501
    UNION ALL SELECT * FROM rmf1920.dbo.sales202502
    UNION ALL SELECT * FROM rmf1920.dbo.sales202503
    UNION ALL SELECT * FROM rmf1920.dbo.sales202504
    UNION ALL SELECT * FROM rmf1920.dbo.sales202505
    UNION ALL SELECT * FROM rmf1920.dbo.sales202506
    UNION ALL SELECT * FROM rmf1920.dbo.sales202507
    UNION ALL SELECT * FROM rmf1920.dbo.sales202508
    UNION ALL SELECT * FROM rmf1920.dbo.sales202509
    UNION ALL SELECT * FROM rmf1920.dbo.sales202510
    UNION ALL SELECT * FROM rmf1920.dbo.sales202511
    UNION ALL
    SELECT OrderID, CustomerID, OrderDate, ProductType, OrderValue
    FROM rmf1920.dbo.sales202512
) AS combined;

select * from rmf1920.dbo.sales2025;

--------------------------------------------------------------------------------------

--2\calculate recency, frequency, monetary ,r, f, m ranks
-- combine views with CTEs

IF OBJECT_ID('dbo.rmf_metrics', 'V') IS NOT NULL
    DROP VIEW dbo.rmf_metrics;
GO

CREATE VIEW dbo.rmf_metrics AS
WITH rfm AS (
    SELECT 
        CustomerID,
        MAX(OrderDate) AS last_order_date,
        DATEDIFF(DAY, MAX(OrderDate), '2026-03-26') AS recency,
        COUNT(*) AS frequency,
        SUM(OrderValue) AS monetary
    FROM dbo.sales2025
    GROUP BY CustomerID
)
SELECT *,
    ROW_NUMBER() OVER (ORDER BY recency ASC) AS r_rank,
    ROW_NUMBER() OVER (ORDER BY frequency DESC) AS f_rank,
    ROW_NUMBER() OVER (ORDER BY monetary DESC) AS m_rank
FROM rfm;

select * from rmf1920.dbo.rmf_metrics;

--------------------------------------------------------------------------------------

-- 3\ assing deciles (10= best, 1=worst)

IF OBJECT_ID('dbo.rfm_scores', 'V') IS NOT NULL
    DROP VIEW dbo.rfm_scores;
GO

CREATE VIEW dbo.rfm_scores AS
SELECT *,
    NTILE(10) OVER (ORDER BY r_rank DESC) AS r_score,
    NTILE(10) OVER (ORDER BY f_rank DESC) AS f_score,
    NTILE(10) OVER (ORDER BY m_rank DESC) AS m_score
FROM dbo.rmf_metrics;
select * from rmf1920.dbo.rfm_scores;

--------------------------------------------------------------------------------------

-- 4\ total score
IF OBJECT_ID('dbo.rfm_total_scores', 'V') IS NOT NULL
    DROP VIEW dbo.rfm_total_scores;
GO

CREATE VIEW dbo.rfm_total_scores AS
SELECT
    CustomerID,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score + f_score + m_score) AS rfm_total_score
FROM dbo.rfm_scores;
select * from rmf1920.dbo.rfm_total_scores;

--------------------------------------------------------------------------------------
USE rmf1920;
GO

IF OBJECT_ID('dbo.rfm_segments_final', 'U') IS NOT NULL
    DROP TABLE dbo.rfm_segments_final;

SELECT 
    CustomerID,
    recency,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    rfm_total_score,
    CASE 
        WHEN rfm_total_score >= 28 THEN 'Champions'
        WHEN rfm_total_score >= 24 THEN 'Loyal VIPs'
        WHEN rfm_total_score >= 20 THEN 'Potential Loyalists'
        WHEN rfm_total_score >= 16 THEN 'Promising'
        WHEN rfm_total_score >= 12 THEN 'Engaged'
        WHEN rfm_total_score >= 8 THEN 'Requires Attention'
        WHEN rfm_total_score >= 4 THEN 'At Risk'
        ELSE 'Lost/Inactive'
    END AS rfm_segment
INTO dbo.rfm_segments_final
FROM dbo.rfm_total_scores;

select * from rmf1920.dbo.rfm_segments_final;

--------------------------------------------------------------------------------------






