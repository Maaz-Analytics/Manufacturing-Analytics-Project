# Data Dictionary: Inventory and Cost Analysis for a Manufacturer

**Company (fictional):** a mid-size paints and coatings manufacturer selling to customers in 8 countries.
**Period covered:** 1 Jan 2024 to 30 Sep 2026. **Currency:** USD.
**Data is synthetic.** It is built to behave like real operations: seasonality, bulk discounts, supplier price differences, a discontinued product, and some messy records.

## How the tables connect

```
suppliers --< purchases >-- raw_materials --< bill_of_materials >-- products
                                  |                                     |
                            material_usage >-- production_runs >--------+
                                                                        |
customers --< sales_orders --< sales_order_lines >----------------------+
raw_materials -- stock_count
```

`--<` means one-to-many (one row on the left, many on the right).

## Tables

| File | One row is... | Columns |
|---|---|---|
| suppliers.csv | a supplier | supplier_id, supplier_name, country, lead_time_days |
| raw_materials.csv | a raw material or packaging item | material_id, material_name, unit, category, standard_cost_usd |
| products.csv | a finished product | product_id, product_name, category, pack_size, list_price_2024_usd, status |
| bill_of_materials.csv | how much of one material goes into one unit of a product | product_id, material_id, qty_per_unit |
| customers.csv | a customer | customer_id, customer_name, customer_type, country, signup_date, credit_days |
| sales_orders.csv | an order header | order_id, order_date, customer_id, credit_days, order_status |
| sales_order_lines.csv | a product line on an order | line_id, order_id, product_id, quantity, list_price_usd, discount_pct, unit_price_usd |
| purchases.csv | a purchase of raw material | purchase_id, purchase_date, material_id, supplier_id, quantity, unit_cost_usd, total_cost_usd |
| production_runs.csv | one production batch | run_id, run_date, product_id, qty_produced, labor_cost_usd, overhead_cost_usd, scrap_pct |
| material_usage.csv | material actually consumed in a batch | usage_id, run_id, material_id, qty_used |
| stock_count.csv | warehouse physical count on 30 Sep 2026 | material_id, count_date, physical_qty, unit |

## Notes on meaning

- **Stock on hand** is not stored directly. Opening stock was zero on 1 Jan 2024, so stock = total purchased - total used. `stock_count.csv` is the physical count to check that against.
- **list_price_usd** is the price before discount. **unit_price_usd** is what the customer paid after `discount_pct`. Prices go up about 3% each January.
- **order_status** can be Delivered, Cancelled or Returned. Think about which of these should count as real sales.
- **material_usage** includes scrap, so it is slightly more than the bill of materials alone would suggest.
- **labor_cost_usd and overhead_cost_usd** are totals for the whole batch, not per unit.
- **products.status** shows whether a product is still made.
- Some records are messy on purpose. Finding and fixing them is part of the project (Step 3).

## Suggested business questions this data can answer

1. How much raw material stock is sitting unused, how old is it, and what is it worth in USD?
2. Which products sell a lot but earn little margin, and which sell a lot and earn well?
3. Do bulk customers pay a lower price, and do those orders still make a profit?
4. How are sales changing from year to year, and which products or customers explain it?
