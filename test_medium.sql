-- Moderate complexity query with CTEs and multiple joins
WITH monthly_sales AS (
    SELECT 
        DATE_TRUNC('MONTH', order_date) as sale_month,
        product_id,
        SUM(quantity) as total_quantity,
        SUM(amount) as total_amount
    FROM orders
    GROUP BY 1, 2
),
top_products AS (
    SELECT 
        product_id,
        sale_month,
        total_quantity,
        RANK() OVER (PARTITION BY sale_month ORDER BY total_quantity DESC) as quantity_rank
    FROM monthly_sales
)
SELECT 
    p.product_name,
    c.category_name,
    tp.sale_month,
    tp.total_quantity,
    ms.total_amount,
    s.supplier_name
FROM 
    top_products tp
JOIN 
    products p ON tp.product_id = p.product_id
JOIN 
    categories c ON p.category_id = c.category_id
JOIN 
    monthly_sales ms ON tp.product_id = ms.product_id 
    AND tp.sale_month = ms.sale_month
JOIN 
    suppliers s ON p.supplier_id = s.supplier_id
WHERE 
    tp.quantity_rank <= 10
ORDER BY 
    tp.sale_month DESC,
    tp.quantity_rank;

UPDATE products 
SET stock_quantity = stock_quantity - 10
WHERE product_id IN (
    SELECT product_id 
    FROM top_products 
    WHERE quantity_rank = 1
);