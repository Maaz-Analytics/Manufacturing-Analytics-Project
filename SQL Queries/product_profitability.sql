
--total revenue
 select p.product_id,
 p.product_name ,
 SUM(sol.quantity*sol.unit_price_usd) as total_revenue
 from products as p 
 inner join sales_order_lines as sol 
 on p.product_id=sol.product_id
 group by p.product_id , p.product_name 
 order by total_revenue 

 --material cost

select p.product_id,p.product_name ,
sum(bom.qty_per_unit*rm.standard_cost_usd) as material_cost
from products as p 
left join bill_of_materials as bom 
on p.product_id=bom.product_id
left join raw_materials as rm 
on bom.material_id=rm.material_id
group by p.product_id , p.product_name
order by material_cost desc ;

--labor and overhead cost per unit

SELECT
    pr.product_id,
    p.product_name,
    SUM(pr.qty_produced) AS total_qty_produced,
    SUM(pr.labor_cost_usd) AS total_labor_cost_usd,
    SUM(pr.overhead_cost_usd) AS total_overhead_cost_usd,

    SUM(pr.labor_cost_usd)
        / NULLIF(SUM(pr.qty_produced), 0)
        AS labor_cost_per_unit,

    SUM(pr.overhead_cost_usd)
        / NULLIF(SUM(pr.qty_produced), 0)
        AS overhead_cost_per_unit,

    (
        SUM(pr.labor_cost_usd)
        + SUM(pr.overhead_cost_usd)
    ) / NULLIF(SUM(pr.qty_produced), 0)
        AS total_conversion_cost_per_unit

FROM production_runs AS pr
JOIN products AS p
    ON pr.product_id = p.product_id

GROUP BY
    pr.product_id,
    p.product_name

ORDER BY total_conversion_cost_per_unit DESC;

--product wise estimated profit margin
 
WITH ProductRevenue AS
(
    SELECT
        sol.product_id,
        SUM(sol.quantity)                       AS total_qty_sold,
        SUM(sol.quantity * sol.unit_price_usd)  AS total_revenue_usd
    FROM sales_order_lines AS sol
    JOIN sales_orders AS so
        ON sol.order_id = so.order_id
    WHERE so.order_status = 'Delivered'
    GROUP BY sol.product_id
),
ProductionTotals AS
(
    SELECT
        product_id,
        SUM(qty_produced)       AS total_qty_produced,
        SUM(labor_cost_usd)     AS total_labor_usd,
        SUM(overhead_cost_usd)  AS total_overhead_usd
    FROM production_runs
    GROUP BY product_id
),
MaterialUsageCost AS
(
    SELECT
        pr.product_id,
        SUM(mu.qty_used * rm.standard_cost_usd) AS total_material_usd
    FROM material_usage AS mu
    JOIN production_runs AS pr
        ON mu.run_id = pr.run_id
    JOIN raw_materials AS rm
        ON mu.material_id = rm.material_id
    GROUP BY pr.product_id
),
RecipeCost AS
(
    SELECT
        bom.product_id,
        SUM(bom.qty_per_unit * rm.standard_cost_usd) AS recipe_cost_per_unit
    FROM bill_of_materials AS bom
    JOIN raw_materials AS rm
        ON bom.material_id = rm.material_id
    GROUP BY bom.product_id
),
UnitCosts AS
(
    SELECT
        pt.product_id,
        muc.total_material_usd   / NULLIF(pt.total_qty_produced, 0) AS material_cost_per_unit,
        pt.total_labor_usd       / NULLIF(pt.total_qty_produced, 0) AS labor_cost_per_unit,
        pt.total_overhead_usd    / NULLIF(pt.total_qty_produced, 0) AS overhead_cost_per_unit,
        rc.recipe_cost_per_unit
    FROM ProductionTotals AS pt
    LEFT JOIN MaterialUsageCost AS muc ON pt.product_id = muc.product_id
    LEFT JOIN RecipeCost        AS rc  ON pt.product_id = rc.product_id
),
ProductCosts AS
(
    SELECT
        r.product_id,
        r.total_qty_sold,
        r.total_revenue_usd,
        r.total_qty_sold * u.material_cost_per_unit AS total_material_cost_usd,
        r.total_qty_sold * u.labor_cost_per_unit    AS total_labor_cost_usd,
        r.total_qty_sold * u.overhead_cost_per_unit AS total_overhead_cost_usd,
        r.total_qty_sold * u.recipe_cost_per_unit   AS total_recipe_material_usd
    FROM ProductRevenue AS r
    LEFT JOIN UnitCosts AS u
        ON r.product_id = u.product_id
)
SELECT
    p.product_id,
    p.product_name,
    p.status,
    c.total_qty_sold,
    ROUND(c.total_revenue_usd, 2)          AS revenue_usd,
    ROUND(c.total_material_cost_usd, 2)    AS material_cost_usd,
    ROUND(c.total_labor_cost_usd, 2)       AS labor_cost_usd,
    ROUND(c.total_overhead_cost_usd, 2)    AS overhead_cost_usd,
    ROUND(c.total_revenue_usd
          - c.total_material_cost_usd
          - c.total_labor_cost_usd
          - c.total_overhead_cost_usd, 2)  AS profit_usd,
    ROUND((c.total_revenue_usd
          - c.total_material_cost_usd
          - c.total_labor_cost_usd
          - c.total_overhead_cost_usd)
          / NULLIF(c.total_revenue_usd, 0) * 100, 2) AS margin_pct,
    ROUND((c.total_revenue_usd
          - c.total_recipe_material_usd
          - c.total_labor_cost_usd
          - c.total_overhead_cost_usd)
          / NULLIF(c.total_revenue_usd, 0) * 100, 2) AS margin_pct_recipe_basis
FROM ProductCosts AS c
JOIN products AS p
    ON c.product_id = p.product_id
ORDER BY margin_pct DESC; 


-- B5: High-Selling vs High-Profit Products

WITH ProductSales AS
(
    SELECT
        sol.product_id,
        SUM(sol.quantity) AS total_qty_sold,
        SUM(sol.quantity * sol.unit_price_usd) AS revenue_usd
    FROM sales_order_lines AS sol
    JOIN sales_orders AS so
        ON sol.order_id = so.order_id
    WHERE so.order_status = 'Delivered'
    GROUP BY sol.product_id
),
ProductionTotals AS
(
    SELECT
        product_id,
        SUM(qty_produced) AS total_qty_produced,
        SUM(labor_cost_usd) AS total_labor_usd,
        SUM(overhead_cost_usd) AS total_overhead_usd
    FROM production_runs
    GROUP BY product_id
),
MaterialUsageCost AS
(
    SELECT
        pr.product_id,
        SUM(mu.qty_used * rm.standard_cost_usd) AS total_material_usd
    FROM material_usage AS mu
    JOIN production_runs AS pr
        ON mu.run_id = pr.run_id
    JOIN raw_materials AS rm
        ON mu.material_id = rm.material_id
    GROUP BY pr.product_id
),
ProductProfitability AS
(
    SELECT
        ps.product_id,
        ps.total_qty_sold,
        ps.revenue_usd,
        ps.revenue_usd
          - (muc.total_material_usd / NULLIF(pt.total_qty_produced, 0)
             * ps.total_qty_sold)
          - (pt.total_labor_usd / NULLIF(pt.total_qty_produced, 0)
             * ps.total_qty_sold)
          - (pt.total_overhead_usd / NULLIF(pt.total_qty_produced, 0)
             * ps.total_qty_sold) AS estimated_profit_usd
    FROM ProductSales AS ps
    JOIN ProductionTotals AS pt
        ON ps.product_id = pt.product_id
    JOIN MaterialUsageCost AS muc
        ON ps.product_id = muc.product_id
)
SELECT
    p.product_id,
    p.product_name,
    pp.total_qty_sold,
    ROUND(pp.revenue_usd, 2) AS revenue_usd,
    ROUND(pp.estimated_profit_usd, 2) AS estimated_profit_usd,
    ROUND(
        pp.estimated_profit_usd / NULLIF(pp.revenue_usd, 0) * 100,
        2
    ) AS estimated_margin_pct,
    CASE
        WHEN pp.total_qty_sold >=
             (SELECT AVG(total_qty_sold) FROM ProductProfitability)
         AND pp.estimated_profit_usd / NULLIF(pp.revenue_usd, 0) * 100 >= 30
            THEN 'High Sales - High Margin'
        WHEN pp.total_qty_sold >=
             (SELECT AVG(total_qty_sold) FROM ProductProfitability)
         AND pp.estimated_profit_usd / NULLIF(pp.revenue_usd, 0) * 100 < 30
            THEN 'High Sales - Low Margin'
        WHEN pp.total_qty_sold <
             (SELECT AVG(total_qty_sold) FROM ProductProfitability)
         AND pp.estimated_profit_usd / NULLIF(pp.revenue_usd, 0) * 100 >= 30
            THEN 'Low Sales - High Margin'
        ELSE 'Low Sales - Low Margin'
    END AS product_category
FROM ProductProfitability AS pp
JOIN products AS p
    ON pp.product_id = p.product_id
ORDER BY pp.total_qty_sold DESC; 

-- B6: Discontinued Products with Sales

SELECT
    p.product_id,
    p.product_name,
    p.status,
    COALESCE(SUM(
        CASE
            WHEN so.order_status = 'Delivered'
            THEN sol.quantity
            ELSE 0
        END
    ), 0) AS total_qty_sold,
    COALESCE(SUM(
        CASE
            WHEN so.order_status = 'Delivered'
            THEN sol.quantity * sol.unit_price_usd
            ELSE 0
        END
    ), 0) AS total_revenue_usd,
    COUNT(DISTINCT
        CASE
            WHEN so.order_status = 'Delivered'
            THEN so.order_id
        END
    ) AS delivered_orders
FROM products AS p
LEFT JOIN sales_order_lines AS sol
    ON p.product_id = sol.product_id
LEFT JOIN sales_orders AS so
    ON sol.order_id = so.order_id
WHERE p.status = 'Discontinued'
GROUP BY
    p.product_id,
    p.product_name,
    p.status
ORDER BY total_qty_sold DESC;