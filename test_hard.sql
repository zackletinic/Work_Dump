-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);-- Complex query with multiple CTEs, joins, and data modifications
WITH customer_segments AS (
    SELECT 
        customer_id,
        CASE 
            WHEN total_spent >= 10000 THEN 'Premium'
            WHEN total_spent >= 5000 THEN 'Gold'
            WHEN total_spent >= 1000 THEN 'Silver'
            ELSE 'Bronze'
        END as segment,
        total_spent,
        last_purchase_date
    FROM (
        SELECT 
            customer_id,
            SUM(total_amount) as total_spent,
            MAX(order_date) as last_purchase_date
        FROM orders
        GROUP BY customer_id
    ) customer_totals
),
product_performance AS (
    SELECT 
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity) as total_quantity_sold,
        SUM(oi.quantity * oi.unit_price) as total_revenue,
        COUNT(DISTINCT o.customer_id) as unique_customers,
        AVG(r.rating) as avg_rating
    FROM 
        products p
    JOIN 
        order_items oi ON p.product_id = oi.product_id
    JOIN 
        orders o ON oi.order_id = o.order_id
    JOIN 
        categories c ON p.category_id = c.category_id
    LEFT JOIN 
        product_reviews r ON p.product_id = r.product_id
    GROUP BY 
        p.product_id, p.product_name, c.category_name
),
regional_sales AS (
    SELECT 
        r.region_name,
        c.category_name,
        DATE_TRUNC('MONTH', o.order_date) as sale_month,
        SUM(oi.quantity * oi.unit_price) as revenue,
        COUNT(DISTINCT o.customer_id) as customer_count,
        RANK() OVER (PARTITION BY r.region_name ORDER BY SUM(oi.quantity * oi.unit_price) DESC) as category_rank
    FROM 
        orders o
    JOIN 
        customers cu ON o.customer_id = cu.customer_id
    JOIN 
        regions r ON cu.region_id = r.region_id
    JOIN 
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN 
        categories c ON p.category_id = c.category_id
    GROUP BY 
        r.region_name, c.category_name, DATE_TRUNC('MONTH', o.order_date)
)
SELECT 
    rs.region_name,
    rs.category_name,
    rs.sale_month,
    rs.revenue,
    rs.customer_count,
    cs.segment as top_customer_segment,
    pp.avg_rating as category_avg_rating,
    ROUND(rs.revenue / LAG(rs.revenue) OVER (PARTITION BY rs.region_name, rs.category_name ORDER BY rs.sale_month) - 1, 2) as revenue_growth
FROM 
    regional_sales rs
JOIN 
    product_performance pp ON rs.category_name = pp.category_name
JOIN 
    customer_segments cs ON rs.customer_count = cs.customer_id
WHERE 
    rs.category_rank <= 5
    AND rs.sale_month >= DATE '2024-01-01'
ORDER BY 
    rs.region_name,
    rs.revenue DESC;

-- Update product prices based on performance
UPDATE products
SET unit_price = unit_price * 1.1
WHERE product_id IN (
    SELECT product_id
    FROM product_performance
    WHERE total_revenue > 100000
    AND avg_rating >= 4.5
);

-- Remove discontinued products with no recent sales
DELETE FROM products
WHERE product_id IN (
    SELECT p.product_id
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.product_id
    HAVING MAX(o.order_date) < DATE '2023-01-01' OR MAX(o.order_date) IS NULL
);