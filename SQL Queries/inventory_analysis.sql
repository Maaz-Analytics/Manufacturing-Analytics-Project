select * from raw_materials 
select * from material_usage
select * from purchases
select * from stock_count
--Total purchased material quantity 

select p.material_id ,
sum(p.quantity) as total_purchased_quantity 
from purchases as p
group by p.material_id  

--Total used material quantity 

select mu.material_id ,
sum(mu.qty_used) total_used_material  
from material_usage as mu
group by mu.material_id  ;

--Expected stock 

with purchased as
(
select p.material_id ,
sum(p.quantity) as total_purchased_quantity 
from purchases as p
group by p.material_id 
 )  , 
 used as (
select mu.material_id ,
sum(mu.qty_used) total_used_material  
from material_usage as mu
group by mu.material_id )

select p.material_id,
p.total_purchased_quantity ,
u.total_used_material,
expected_stock = p.total_purchased_quantity-u.total_used_material
from purchased as p
left join used  as u
on p.material_id=u.material_id

--physical gap count of stock

with purchased as
(
select p.material_id ,
sum(p.quantity) as total_purchased_quantity 
from purchases as p
group by p.material_id 
 )  , 
 used as (
select mu.material_id ,
sum(mu.qty_used) total_used_material  
from material_usage as mu
group by mu.material_id )

select p.material_id,
p.total_purchased_quantity ,
u.total_used_material,sc.physical_qty ,
expected_stock = p.total_purchased_quantity-u.total_used_material,
stock_gap = sc.physical_qty - (p.total_purchased_quantity-u.total_used_material)  
from purchased as p
left join used  as u
on p.material_id=u.material_id 
left join stock_count as sc 
on p.material_id=sc.material_id

-- Standard Cost Valuation 

with purchased as
(
select p.material_id ,
sum(p.quantity) as total_purchased_quantity 
from purchases as p
group by p.material_id 
 )  , 
 used as (
select mu.material_id ,
sum(mu.qty_used) total_used_material  
from material_usage as mu
group by mu.material_id )

select p.material_id,
rm.material_name,
rm.unit,
round(p.total_purchased_quantity-u.total_used_material,2) as expected_stock,
round(rm.standard_cost_usd,2) standard_cost_usd,
stock_value =round( (p.total_purchased_quantity-u.total_used_material) * rm.standard_cost_usd,2)
from purchased as p
left join used  as u
on p.material_id=u.material_id
left join raw_materials as rm
on p.material_id=rm.material_id

--Average Actual purchase price

WITH purchased AS
(
    SELECT
        material_id,
        SUM(quantity) AS total_purchased_quantity,
        SUM(COALESCE(total_cost_usd, quantity * unit_cost_usd))
            AS total_purchase_cost
    FROM purchases
    GROUP BY material_id
),
used AS
(
    SELECT
        material_id,
        SUM(qty_used) AS total_used_quantity
    FROM material_usage
    GROUP BY material_id
),
expected_stock AS
(
    SELECT
        p.material_id,
        p.total_purchased_quantity,
        COALESCE(u.total_used_quantity, 0) AS total_used_quantity,
        p.total_purchased_quantity
            - COALESCE(u.total_used_quantity, 0) AS expected_stock
    FROM purchased p
    LEFT JOIN used u
        ON p.material_id = u.material_id
),
valuation AS
(
    SELECT
        rs.material_id,
        rs.material_name,
        rs.unit,
        es.expected_stock,
        rs.standard_cost_usd,

        es.expected_stock * rs.standard_cost_usd
            AS standard_stock_value_usd,

        p.total_purchased_quantity,
        p.total_purchase_cost,

        p.total_purchase_cost
            / NULLIF(p.total_purchased_quantity, 0)
            AS weighted_average_purchase_cost_usd

    FROM raw_materials rs
    LEFT JOIN expected_stock es
        ON rs.material_id = es.material_id
    LEFT JOIN purchased p
        ON rs.material_id = p.material_id
)
SELECT
    material_id,
    material_name,
    unit,
   round( expected_stock,2) as expected_stock ,
   round( standard_cost_usd,2) as standard_cost_usd,
   round( standard_stock_value_usd,2)as standard_stock_value_usd,
   round( weighted_average_purchase_cost_usd,2) as weighted_average_purchase_cost_usd,

   round (expected_stock * weighted_average_purchase_cost_usd,2)
        AS actual_cost_stock_value_usd,

   round( (expected_stock * weighted_average_purchase_cost_usd)
        - standard_stock_value_usd ,2)
        AS valuation_difference_usd

FROM valuation
ORDER BY ABS(
    (expected_stock * weighted_average_purchase_cost_usd)
        - standard_stock_value_usd
) DESC;

--purchase date

 DECLARE @as_of DATE = '2026-09-30';   -- stock count date

WITH purchased AS
(
    SELECT
        material_id,
        SUM(quantity)      AS total_purchased_quantity,
        MAX(purchase_date) AS last_purchase_date
    FROM purchases
    GROUP BY material_id
),
used AS
(
    SELECT
        mu.material_id,
        SUM(mu.qty_used) AS total_used_quantity,
        MAX(COALESCE(TRY_CONVERT(DATE, pr.run_date, 23),
                     TRY_CONVERT(DATE, pr.run_date, 103))) AS last_use_date
    FROM material_usage mu
    LEFT JOIN production_runs pr
        ON mu.run_id = pr.run_id
    GROUP BY mu.material_id
),
stock AS
(
    SELECT
        p.material_id,
        p.last_purchase_date,
        u.last_use_date,
        p.total_purchased_quantity
            - COALESCE(u.total_used_quantity, 0) AS expected_stock
    FROM purchased p
    LEFT JOIN used u
        ON p.material_id = u.material_id
)
SELECT
    rm.material_id,
    rm.material_name,
    s.last_purchase_date,
    DATEDIFF(DAY, s.last_purchase_date, @as_of) AS days_since_last_purchase,
    s.last_use_date,
    DATEDIFF(DAY, s.last_use_date, @as_of)      AS days_since_last_use,
    ROUND(s.expected_stock, 2)                  AS expected_stock,
    ROUND(s.expected_stock * rm.standard_cost_usd, 2) AS remaining_stock_value_usd
FROM raw_materials rm
LEFT JOIN stock s
    ON rm.material_id = s.material_id
ORDER BY days_since_last_use DESC;