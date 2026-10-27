# Manufacturing Analytics Project

An end-to-end analytics project for a fictional paints and coatings manufacturer. It turns raw operational data (sales, production, inventory and costs) into three Power BI dashboards and a written report with specific business recommendations.

**Dataset period:** 1 January 2024 – 30 September 2026 | **Currency:** USD | **Data:** synthetic (fictional company)

**Tools:** SQL Server (SSMS) · Power Query · Power BI · DAX

---

## Key Findings

- **Sales and profit:** Delivered revenue is **$10.69M** across 378,231 units, with estimated profit of **$2.53M** (**23.63%** margin).
- **A loss-making product:** Industrial Thinner is the **third-largest product by revenue ($1.59M) but has a negative estimated margin (-0.92%, about -$14.6K)**.
- **Other weak margins:** Wall Primer (14.74%) and Wall Putty (10.13%) are well below the 23.63% average. Together with Industrial Thinner, these three products bring in about **$3.7M** of revenue.
- **Inventory gaps:** Five materials have physical stock below the expected amount, led by **M04 (-2.1%)**, **M09 (-1.5%)** and **M03 (-1.2%)**. The other ten materials match within rounding.
- **Cost structure:** Material is **89%** of total production cost ($8.69M for 402,738 units, or **$21.57 per unit**). Monthly cost per unit stayed in a narrow band, **$21.07 to $22.03**, so savings will come mainly from material purchase prices.
- **Waste:** The unit-weighted scrap rate is **2.47%**.
- **Bulk pricing:** Average realized price is about **$29 per unit on regular orders and $24 on bulk orders**, which needs a product-mix check before any discount decision.

---

## Business Questions

1. How does revenue change over time and by product?
2. Which products have the weakest estimated margins?
3. What is the gap between expected and physical inventory, material by material?
4. Do bulk orders get lower realized prices than regular orders?
5. What drives production cost, and is cost per unit stable over time?

---

## Dashboards

### 1. Executive Overview: Sales and Profitability
Revenue, estimated profit, margin and units sold. Products are ranked by revenue and colored by margin, and a headline updates automatically to name the loss-making product.

Sales and Profitability

Problem: A paints manufacturer wanted to know which products make money and which don't, so it could fix pricing and costs where margins are weak.
Finding: Industrial Thinner is the third-largest product by revenue ($1.59M) but has a negative estimated margin (-0.92%). Wall Primer (14.74%) and Wall Putty (10.13%) are also well below the 23.63% average.
Recommendation: Review pricing and costs on these three products, which bring in about $3.7M in revenue, starting with Industrial Thinner.

![Executive Overview](Dashboard%20Images/executive-overview.png)

### 2. Production and Inventory
Production volume and monthly trend, expected versus physical stock by material, and a stock gap % chart. A dynamic headline states the total gap and the worst material.

Production and Inventory

Problem: The business wanted to know whether the raw materials on the shelf match what its purchase and usage records say should be there.
Finding: Five of the 15 materials have less physical stock than expected, led by M04 (-2.1%), M09 (-1.5%) and M03 (-1.2%). The other ten match.
Recommendation: Recount and review usage records for M04, M09 and M03 first, to find whether the gaps come from waste, counting errors, or unrecorded usage.

![Production and Inventory](Dashboard%20Images/production-inventory.png)

### 3. Product and Cost Analysis
Total production cost, cost per unit, material share of cost, and scrap %. A monthly cost-per-unit trend, a cost breakdown (material, labor, overhead) and cost per unit by product show what drives cost.

Product and Cost Analysis

Problem: The business wanted to know what drives the cost of making its products, and whether that cost is rising.
Finding: Material is 89% of the $8.69M production cost, and cost per unit stayed steady between $21.07 and $22.03 for the whole period.
Recommendation: Because unit cost is stable, savings will come from material purchase prices, so review supplier pricing, starting with the most expensive products: Epoxy Floor Coating ($45.74 per unit), Anti-Corrosion Paint ($30.70) and Exterior Weatherproof Paint ($30.31).

![Product and Cost Analysis](Dashboard%20Images/product-cost-analysis.png)

Every page has a Year slicer, and the headlines recalculate with the filters, so the written message cannot go out of date.

---

## Business Recommendations

1. **Review pricing and costs on Industrial Thinner, Wall Primer and Wall Putty.** Check discounts, material consumption, scrap and the allocation period before changing prices.
2. **Focus cost control on material purchase prices.** Material is 89% of cost and unit cost is stable, so start with supplier pricing for the highest-cost products: Epoxy Floor Coating ($45.74 per unit), Anti-Corrosion Paint ($30.70) and Exterior Weatherproof Paint ($30.31).
3. **Recount and review usage records for M04, M09 and M03,** the materials with the largest stock gaps.
4. **Evaluate bulk discounts using contribution, not price alone,** by comparing realized price, product mix and cost per unit.
5. **Use one costing definition across all reports.** Keep batch totals separate from per-unit values, and name measures by their unit.

---

## Method

- **Data preparation (Power Query):** standardized text, set data types, parsed dates.
- **SQL analysis:** delivered revenue by year and product, material cost, monthly and yearly sales, bulk versus regular pricing.
- **Data model:** order headers to lines, products to sales and production runs, production runs to material usage, raw materials to purchases and stock counts, and a date table linked to the order, production and stock-count dates.
- **DAX:** estimated cost per unit, COGS, profit, margin, stock gap, scrap %, and dynamic titles.
- **Costing:** estimated material cost = quantity used × standard cost. Labor and overhead are batch totals from production runs. COGS = delivered units × product-level cost per unit.

### Data quality check

While building the cost page, profit briefly showed $3.07M instead of $2.53M. The cause was a measure named `Total labor` that already held labor cost per unit, and a second measure divided it by units again, so labor almost disappeared from cost. After fixing it, all three pages reconciled to the source-data estimates. The takeaway: name measures by their unit and grain, and check totals across pages.

---

## Limitations

- The dataset is synthetic and represents a fictional manufacturer.
- Revenue and profit use delivered orders. The 2026 figures cover January to September only.
- Material costs use standard costs, so actual purchase prices may differ.
- Inventory reconciliation assumes zero opening stock. Quantities are material- and unit-specific, and the all-materials stock total mixes units, so it is indicative only.
- Estimated profit is not net profit, because freight, utilities, taxes and other expenses are not in the data.
- Total production cost covers all units made, while COGS covers delivered units only, so the two totals differ by design.

---

## Project Structure

```
Manufacturing-Analytics-Project/
├── Dashboard Images/
├── SQL Queries/
├── Dataset/
├── Manufacturing Analytics Project Report.pdf
├── Manufacturing Analytics.pbix
└── README.md
```

---

**Skills shown:** data preparation, SQL analysis, data modeling, DAX, dashboard design, reconciling numbers across reports, and communicating findings as business recommendations.
# Manufacturing-Analytics-Project
End-to-end analytics for a paint manufacturer : SQL , Power Query , DAX and 3 Power BI dashboards 
