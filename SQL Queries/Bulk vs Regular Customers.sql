--Order type

select order_id ,
    sum(quantity) as Total_quantity ,
    case when sum(quantity) >= 1000 then 'Bulk'
    else 'Regular'
    end as Order_type
from sales_order_lines
group by order_id  ;

--Average Discount Comparison

select sol.order_id , 
    sum(sol.quantity) as Total_quantity ,
    case when sum(sol.quantity) >= 1000 then 'Bulk'
    else 'Regular'
    end as Order_type ,
    round(AVG (sol.discount_pct),2) as avg_discount
from sales_order_lines as sol
left join sales_orders as so 
    on sol.order_id=so.order_id
where so.order_status='Delivered'
group by sol.order_id  ;
 
--Average unit selling price 

WITH OrderPrices AS
(
    SELECT
        sol.order_id,
        SUM(sol.quantity) AS total_quantity,
        CASE
            WHEN SUM(sol.quantity) >= 1000 THEN 'Bulk'
            ELSE 'Regular'
        END AS order_type,
        AVG(sol.unit_price_usd) AS avg_unit_price
    FROM sales_order_lines AS sol
    INNER JOIN sales_orders AS so
        ON sol.order_id = so.order_id
    WHERE so.order_status = 'Delivered'
    GROUP BY sol.order_id
)
SELECT
    order_type,
    ROUND(AVG(avg_unit_price), 2) AS average_unit_price_usd
FROM OrderPrices
GROUP BY order_type
ORDER BY average_unit_price_usd DESC;

--Bulk vs Regular Profit Margin 

WITH ProductionTotals AS
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
UnitCosts AS
(
    SELECT
        pt.product_id,
        muc.total_material_usd / NULLIF(pt.total_qty_produced, 0)
            AS material_cost_per_unit,
        pt.total_labor_usd / NULLIF(pt.total_qty_produced, 0)
            AS labor_cost_per_unit,
        pt.total_overhead_usd / NULLIF(pt.total_qty_produced, 0)
            AS overhead_cost_per_unit
    FROM ProductionTotals AS pt
    LEFT JOIN MaterialUsageCost AS muc
        ON pt.product_id = muc.product_id
),
OrderProductCosts AS
(
    SELECT
        sol.order_id,
        sol.product_id,
        SUM(sol.quantity) AS quantity_sold,
        SUM(sol.quantity * sol.unit_price_usd) AS revenue_usd,
        SUM(sol.quantity *
            (uc.material_cost_per_unit
             + uc.labor_cost_per_unit
             + uc.overhead_cost_per_unit)) AS estimated_cost_usd
    FROM sales_order_lines AS sol
    JOIN sales_orders AS so
        ON sol.order_id = so.order_id
    LEFT JOIN UnitCosts AS uc
        ON sol.product_id = uc.product_id
    WHERE so.order_status = 'Delivered'
    GROUP BY sol.order_id, sol.product_id
),
OrderTotals AS
(
    SELECT
        order_id,
        SUM(quantity_sold) AS total_quantity,
        SUM(revenue_usd) AS revenue_usd,
        SUM(estimated_cost_usd) AS estimated_cost_usd
    FROM OrderProductCosts
    GROUP BY order_id
),
ClassifiedOrders AS
(
    SELECT
        order_id,
        CASE
            WHEN total_quantity >= 1000 THEN 'Bulk'
            ELSE 'Regular'
        END AS order_type,
        revenue_usd,
        estimated_cost_usd
    FROM OrderTotals
)
SELECT
    order_type,
    ROUND(SUM(revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(estimated_cost_usd), 2) AS total_estimated_cost_usd,
    ROUND(SUM(revenue_usd) - SUM(estimated_cost_usd), 2)
        AS estimated_profit_usd,
    ROUND(
        (SUM(revenue_usd) - SUM(estimated_cost_usd))
        / NULLIF(SUM(revenue_usd), 0) * 100,
        2
    ) AS estimated_margin_pct
FROM ClassifiedOrders
GROUP BY order_type
ORDER BY estimated_margin_pct DESC;
 

-- Customers with Most Bulk orders and Their Profitability

WITH ProductionTotals AS
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
UnitCosts AS
(
    SELECT
        pt.product_id,
        (
            muc.total_material_usd
            / NULLIF(pt.total_qty_produced, 0)
        ) AS material_cost_per_unit,
        (
            pt.total_labor_usd
            / NULLIF(pt.total_qty_produced, 0)
        ) AS labor_cost_per_unit,
        (
            pt.total_overhead_usd
            / NULLIF(pt.total_qty_produced, 0)
        ) AS overhead_cost_per_unit
    FROM ProductionTotals AS pt
    LEFT JOIN MaterialUsageCost AS muc
        ON pt.product_id = muc.product_id
),
OrderTotals AS
(
    SELECT
        so.order_id,
        so.customer_id,
        SUM(sol.quantity) AS total_quantity,
        SUM(sol.quantity * sol.unit_price_usd) AS revenue_usd,
        SUM(
            sol.quantity *
            (
                uc.material_cost_per_unit
                + uc.labor_cost_per_unit
                + uc.overhead_cost_per_unit
            )
        ) AS estimated_cost_usd
    FROM sales_orders AS so
    JOIN sales_order_lines AS sol
        ON so.order_id = sol.order_id
    LEFT JOIN UnitCosts AS uc
        ON sol.product_id = uc.product_id
    WHERE so.order_status = 'Delivered'
    GROUP BY so.order_id, so.customer_id
),
BulkOrders AS
(
    SELECT *
    FROM OrderTotals
    WHERE total_quantity >= 1000
)
SELECT
    customer_id,
    COUNT(*) AS total_bulk_orders,
    SUM(total_quantity) AS total_units_sold,
    ROUND(SUM(revenue_usd), 2) AS total_revenue_usd,
    ROUND(SUM(estimated_cost_usd), 2) AS total_estimated_cost_usd,
    ROUND(
        SUM(revenue_usd) - SUM(estimated_cost_usd), 2
    ) AS estimated_profit_usd,
    ROUND(
        (
            SUM(revenue_usd) - SUM(estimated_cost_usd)
        ) / NULLIF(SUM(revenue_usd), 0) * 100,
        2
    ) AS estimated_margin_pct
FROM BulkOrders
GROUP BY customer_id
ORDER BY total_bulk_orders DESC, estimated_profit_usd DESC;