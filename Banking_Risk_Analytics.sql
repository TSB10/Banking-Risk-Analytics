CREATE DATABASE banking_analytics;
use banking_analytics;
SELECT 
    *
FROM
    transactions;
select * from customers;
SELECT 
    COUNT(*)
FROM
    customers;
 -- Total Loans   
SELECT 
    COUNT(loan_id)
FROM
    loans;
SELECT DISTINCT
    (COUNT(loan_type))
FROM
    loans;
-- Total Loan amount
SELECT 
    SUM(loan_amount) AS total_amount
FROM
    loans;
-- Total Outstanding amount
SELECT 
    SUM(outstanding_amount)
FROM
    loans;
-- Average loan amount
SELECT 
    AVG(loan_amount)
FROM
    loans;
-- Total number of defult loans 
SELECT 
    COUNT(loan_status)
FROM
    loans
WHERE
    loan_status = 'defaulted'
;
-- calculate the default rate
with loan_summary as( select count(*) as total_loan_application,
              sum(case
                      when loan_status="Defaulted" then 1
                      else 0
                      end ) as total_defaulters 
                      from loans
                      )
select total_loan_application, total_defaulters,
           round(total_defaulters *100/total_loan_application, 2) as default_rate
           from loan_summary
           ;
-- calculate the default amount

with loan_summary as (select count(*) as total_loan_application,
         sum( case
                   when loan_status="Defaulted" then 1
                   else 0
                   end) as default_loans,
             sum(loan_amount) as total_loan_amount,      
                   sum( case 
                    when loan_status="defaulted" then loan_amount
                    else 0
            end) as defaulted_amount
            from loans
)
select total_loan_application,
          default_loans, total_loan_amount,
          round(default_loans*100/total_loan_application, 2) as default_rate,
          defaulted_amount
          from loan_summary
          ;
 -- Default amount for each loan type
SELECT 
    loan_type,
    SUM(CASE
        WHEN loan_status = 'Defaulted' THEN loan_amount
        ELSE 0
    END) AS default_amount
FROM
    loans
GROUP BY loan_type
order by default_amount desc
;
 -- Branch wise Performance 
SELECT 
    b.branch_name,
    COUNT(c.customer_id) AS total_customer,
    SUM(l.loan_amount) AS total_loan,
    SUM(l.outstanding_amount) AS outstanding_amount,
    SUM(CASE
        WHEN l.loan_status = 'Defaulted' THEN loan_amount
        ELSE 0
    END) AS default_amount
FROM
    branches AS b
        JOIN
    customers AS c ON b.branch_id = c.branch_id
        JOIN
    loans AS l ON c.customer_id = l.customer_id
GROUP BY 1
ORDER BY 3 DESC
;
-- Performence by each branch	 
SELECT 
    b.branch_name,
    COUNT(c.customer_id) AS total_customer,
    COUNT(l.loan_id) AS total_number_of_loans,
    SUM(l.loan_amount) AS total_amount,
    SUM(l.outstanding_amount),
    SUM(CASE
        WHEN l.loan_status = 'defaulted' THEN loan_amount
        ELSE 0
    END) AS defaulted_amount
FROM
    branches AS b
        JOIN
    customers AS c ON b.branch_id = c.branch_id
        JOIN
    loans AS l ON l.customer_id = c.customer_id
GROUP BY branch_name
ORDER BY total_amount DESC
;
-- High-Risk Customers with their rank 
	
select c.customer_id,count(l.loan_id) as total_loans, sum(l.loan_amount)as total_loan_amount,
        sum(l.outstanding_amount) as total_outstanding_amount,
        row_number() over(
                  order by sum(l.outstanding_amount) desc) as cust_rank
	from customers as c
    join loans as l
    on l.customer_id=c.customer_id
    where l.risk_band in("High","Very High")
    group by 1
    order by cust_rank
    ;
-- Calculate default rate for each customer segment
SELECT 
    c.customer_segment,
    SUM(CASE
        WHEN l.loan_status = 'Defaulted' THEN 1
        ELSE 0
    END) AS defaulted_loans,
    ROUND(SUM(CASE
                WHEN l.loan_status = 'Defaulted' THEN 1
                ELSE 0
            END) * 100 / COUNT(l.loan_id),
            2) AS default_rate
FROM
    customers AS c
        JOIN
    loans AS l ON l.customer_id = c.customer_id
GROUP BY 1
ORDER BY defaulted_loans DESC
;
-- Find the top 3 customers in each city based on outstanding loan amount
 select * 
 from(
	  select c.city, c.customer_id, sum(l.outstanding_amount) as outstanding_amount,
      row_number() over(partition by city order by sum(l.outstanding_amount) desc) as rank_no
      from customers as c
      join loans as l
      on c.customer_id=l.customer_id
      group by 1,2) as rankrd_customer
      where rank_no<=3
      ;
  with ranked_customer as(
        select c.city as city_name , c.customer_id as customer_no , sum(l.outstanding_amount) as outstanding_amount,
      row_number() over(partition by city order by sum(l.outstanding_amount) desc) as rank_no
      from customers as c
      join loans as l
      on c.customer_id=l.customer_id
      group by 1,2)
select city_name, customer_no, outstanding_amount,rank_no
from ranked_customer
where rank_no<=3
; 

-- customers whose credit score is below the average credit score
 with credit_rating as(
        select avg(credit_score) as average_credit_score
        from customers
        )
select c.customer_id,c.city,c.branch_id,c.customer_segment,c.occupation,credit_score,cr.average_credit_score
from customers as c
cross join credit_rating as cr
where c.credit_score<cr.average_credit_score
order by c.credit_score desc 
;
-- Monthly Transaction Trend
SELECT 
    YEAR(transaction_date) AS transaction_year,
    MONTH(transaction_date) AS transaction_month,
    MONTHNAME(transaction_date) AS month_name,
    COUNT(transaction_id) AS total_transactions,
    ROUND(SUM(amount), 2) AS total_transaction_amount
FROM
    transactions
GROUP BY YEAR(transaction_date) , MONTH(transaction_date) , MONTHNAME(transaction_date)
ORDER BY transaction_year , transaction_month;
-- Transaction Performance by Channel
SELECT 
    channel,
    COUNT(transaction_id) AS total_transaction,
    SUM(amount) AS total_amount,
    AVG(amount) AS avg_amount
FROM
    transactions
GROUP BY channel
ORDER BY total_amount DESC
; 
-- Top 10 Customers by Total Transaction Amount
WITH customer_transactions AS (SELECT
        c.customer_id,c.city,c.occupation,c.customer_segment,
        COUNT(t.transaction_id) AS total_transactions,
        SUM(t.amount) AS total_transaction_amount
FROM customers c
JOIN transactions t
ON c.customer_id = t.customer_id
GROUP BY 
c.customer_id,c.city,c.occupation,c.customer_segment
),
ranked_customers AS ( SELECT
        customer_id,city,occupation,customer_segment,total_transactions,total_transaction_amount,
RANK() OVER (
            ORDER BY total_transaction_amount DESC) AS transaction_rank
			FROM customer_transactions
			         )
SELECT
    customer_id,city,occupation,customer_segment,total_transactions,
    ROUND(total_transaction_amount, 2) AS total_transaction_amount, transaction_rank
FROM ranked_customers
WHERE transaction_rank <= 10
ORDER BY transaction_rank
;










