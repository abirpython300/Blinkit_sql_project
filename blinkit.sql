use blinkit;
#No. of orders
select count(distinct Order_id) from blinkit_orders; #1062 data of unique orders are analzed.
#No. of customers
select count(distinct customer_id) from blinkit_orders; #2172 data of unique customers are analyzed
#No.of delivery partners
Select count(distinct delivery_partner_id) from blinkit_orders; #performance of 5000 different delivery partners are analyzed.
#No. of store_id
select count(distinct store_id) from blinkit_orders; #5000 unique stores
#No.of products
select count(distinct product_name) from blinkit_products; #data of 51 unque products are analyzed. 
#No. of product_category
select count(distinct category) from blinkit_products; #11 categories of products
#No. of marketing campaign
select count(distinct campaign_name) from marketing; #9 marketing campaigns
#No. of campaign channel
select count(distinct campaign_channel) from marketing; #4 campaign_channel
#1.What is the average delivery delay per delivery partner?
with slow_delivery_partner as (select distinct delivery_partner_id, avg(delivery_time_minutes) as avg_delivery_delay
from delivery
where delivery_time_minutes =30 
group by delivery_partner_id
order by avg_delivery_delay desc) #applicationofCTE
select count(*) as delivery_partners_with_maximum_avgdelaytime
from slow_Delivery_partner 
where avg_delivery_delay = (select max(avg_delivery_delay) from slow_delivery_partner); #applicationofsubquery
#1.1: Delivery partners with maximum delay
select distinct delivery_partner_id, avg(delivery_time_minutes) as avg_delivery_delay
from delivery
where delivery_time_minutes =30 
group by delivery_partner_id
order by avg_delivery_delay desc
#2.Which areas (by pincode) have the highest rate of delayed deliveries?

with customer_area as (
select a.order_id, c.customer_id, c.area 
from blinkit_orders as a join customer as c on a.customer_id=c.customer_id) #applicationofcte
select ca.area, count(ca.area), d.delivery_status
from customer_area as ca join delivery as d on ca.order_id=d.Order_id
where d.Delivery_status = 'Significantly delayed'
group by ca.area
order by count(ca.area) desc
limit 10; #usedthreetablestoextractdatathroughjoining

#3. What is the average delivery time vs. promised time per store?
select avg(Delivery_time_minutes) as avg_time
from delivery; #promised delivery time of blinkit is 10 minutes

#4.	What are the top reasons for delivery delays?
select Reasons_if_delayed, count(Reasons_if_delayed)
from delivery
where Reasons_if_delayed = 'Traffic';
#5.	Which products are frequently going below minimum stock levels?
SELECT 
    b.product_name,
    COUNT(i.product_id) AS times_below_min_stock
FROM  blinkit_products as b JOIN 
    inventory as i ON b.product_id = i.product_id
WHERE 
    i.stock_received < b.min_stock_level
GROUP BY 
    b.product_name
ORDER BY 
    times_below_min_stock DESC
    limit 10;

#6.	Which categories have the highest damaged stock rate?
select b.product_name, sum(i.Damaged_stock) as 
total_damaged_stock, sum(b.product_id) as total_stock, 
((sum(i.damaged_stock)/sum(b.product_id))*100) as damaged_stock_rate
from blinkit_products as b join inventory as i on b.product_id=i.Product_id
group by b.product_name
order by Damaged_stock_rate desc
limit 10;
#7.	Which products have the lowest margin but highest sales volume?
select product_name, sum(product_id) as sales_volume, min(margin_percentage) as minimum_margin
from blinkit_products
group by product_name
order by sales_volume desc
limit 10;
#8.	What is the total revenue per category?
select b.category,  round(sum(p.Unit_Price*p.quantity)) as total_revenue 
from blinkit_products as b join product_order as p on b.product_id=p.product_id
group by b.category
order by total_revenue desc; #call valuable_product_category_on_revenue

#9.	Which payment method is most commonly used?
select payment_method, count(Payment_method) as common_payment_method, round(sum(order_total)) as total_revenue_recevd
from blinkit_orders
group by Payment_method
order by common_payment_method desc;

#10.Which customers are contributing the highest lifetime value?
select customer_name, sum(order_total) as lifetime_customer_value
from blinkit_orders as b join customer as c on b.Customer_id=c.Customer_id 
group by customer_name
order by lifetime_customer_value desc
limit 10;

#11.Which customer segments have the highest average order value?
select c.customer_segment, round(avg(order_total) as average_order_value
from customer as c join blinkit_orders as b on c.Customer_id=b.Customer_id
group by c.Customer_segment
order by average_order_value desc; #call valuable_customer_segment

#12.	How many customers have churned?
select count(*) as churned_customers
from customer as c 
where not exists
 (select 1
 from blinkit_orders o
 where o.customer_id = c.customer_id
 ); 

#13.	Which areas have the most loyal customers (repeat orders)?
select c.area, count(b.customer_id) as repeat_orders
from customer as c join blinkit_orders as b on c. Customer_id = b.Customer_id
group by c.Area
order by repeat_orders desc
limit 10;
#14. What is the average rating per order of blinkit?
select avg(rating) average_rating
from feedback;
#15. What are the most frequent negative sentiment categories in feedback?
select feedback_category, count(sentiment) as frequent_negative_sentiment
from feedback
where sentiment = 'Negative'
group by feedback_category
order by frequent_negative_sentiment desc;

#16. How does sentiment correlate with delivery delay?
select count(sentiment)/count(delivery_status) as correlation
from feedback as f join delivery as d on f.order_id=d.Order_id
where f.sentiment = 'negative' and d.delivery_status = 'Significantly delayed' or 'slightly delayed';
#from the above correlation analysis it can be said that there is a perfect posituve correlation between 
#negative sentiment and delayed in delivery. 
#17. What is the average ROAS (Return on Ad Spend) per campaign channel?
select campaign_channel, avg(Roas) as Average_roas_per_channel 
from marketing
group by Campaign_Channel
order by Average_roas_per_channel desc; #call profitable_campaign_channel

#18. Which campaigns led to the most conversions per dollar spent?
select campaign_name, sum(conversions)/sum(spend) as conversions_per_inr_spent 
from marketing
group by Campaign_name
order by conversions_per_inr_spent asc; #call cost_effective_campaign

#19. Which target audience segments responded best to recent campaigns?
select Campaign_name, sum(conversions) as respons
from marketing 
where campaign_date between '2025-01-01' and '2025-05-21'
group by Campaign_name
order by respons desc; #call highly_potential_target_audience;
#20. Which brands have the lowest price-to-MRP difference?
select brand, round(sum(mrp-price)) as price_to_mrp
from blinkit_products
group by brand
order by price_to_mrp asc
limit 10;
#call profitable_brands;
#21. What is the top-selling products with maximum shelf life?
with top_performer as (select b.product_id, b.product_name, (p.quantity*p.unit_price) as top_selling_products
from product_order as p join blinkit_products as b on p.Product_id=b.product_id
group by b.product_id, b.product_name, top_selling_products)
select b.product_name, max(b.shelf_life_days), round(max(t.top_selling_products)),
rank () over (order by max(b.shelf_life_days) desc, max(t.top_selling_products) desc)  as most_durable_products
from top_performer as t join blinkit_products as b on t.Product_name=b.Product_name
group by b.product_name; #call get_durable_products_info


