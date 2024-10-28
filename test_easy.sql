SELECT 
    c.customer_id,
    c.customer_name,
    o.order_date,
    o.total_amount
FROM 
    customers c
JOIN 
    orders o ON c.customer_id = o.customer_id
WHERE 
    o.order_date >= DATE '2024-01-01'
ORDER BY 
    o.order_date DESC;