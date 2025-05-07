use ecomm;
-- Impute mean for the following columns, and round off to the nearest integer if required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear, DaySinceLastOrder.

SET @mean_WarehouseToHome = (SELECT ROUND(AVG(WarehouseToHome)) FROM customer_churn WHERE WarehouseToHome IS NOT NULL);
SET @mean_HourSpendOnApp = (SELECT ROUND(AVG(HourSpendOnApp)) FROM customer_churn WHERE HourSpendOnApp IS NOT NULL);
SET @mean_OrderAmountHike = (SELECT ROUND(AVG(OrderAmountHikeFromlastYear)) FROM customer_churn WHERE OrderAmountHikeFromlastYear IS NOT NULL);
SET @mean_DaySinceLastOrder = (SELECT ROUND(AVG(DaySinceLastOrder)) FROM customer_churn WHERE DaySinceLastOrder IS NOT NULL);


UPDATE customer_churn
SET WarehouseToHome = @mean_WarehouseToHome
WHERE WarehouseToHome IS NULL;

UPDATE customer_churn
SET HourSpendOnApp = @mean_HourSpendOnApp
WHERE HourSpendOnApp IS NULL;

UPDATE customer_churn 
SET OrderAmountHikeFromlastYear = @mean_OrderAmountHike
WHERE OrderAmountHikeFromlastYear IS NULL;

UPDATE customer_churn
SET DaySinceLastOrder = @mean_DaySinceLastOrder
WHERE DaySinceLastOrder IS NULL;

-- Impute mode for the following columns: Tenure, CouponUsed, OrderCount.
-- Used mostly used values and replacing it

SET @mode_Tenure = (
    SELECT Tenure FROM customer_churn 
    GROUP BY Tenure 
    ORDER BY COUNT(*) DESC 
    LIMIT 1
);

SET @mode_CouponUsed = (
    SELECT CouponUsed FROM customer_churn
    GROUP BY CouponUsed 
    ORDER BY COUNT(*) DESC 
    LIMIT 1
);

SET @mode_OrderCount = (
    SELECT OrderCount FROM customer_churn
    GROUP BY OrderCount 
    ORDER BY COUNT(*) DESC 
    LIMIT 1
);

UPDATE customer_churn
SET Tenure = @mode_Tenure
WHERE Tenure IS NULL;

UPDATE customer_churn 
SET CouponUsed = @mode_CouponUsed
WHERE CouponUsed IS NULL;

UPDATE customer_churn 
SET OrderCount = @mode_OrderCount
WHERE OrderCount IS NULL;

-- Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100

DELETE FROM customer_churn 
WHERE WarehouseToHome > 100;

-- Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure uniformity

UPDATE customer_churn  
SET PreferredLoginDevice = REPLACE(PreferredLoginDevice, 'Phone', 'Mobile Phone');

UPDATE customer_churn 
SET PreferedOrderCat = REPLACE(PreferedOrderCat, 'Mobile', 'Mobile Phone');

--  Standardize payment mode values: Replace "COD" with "Cash on Delivery" and "CC" with "Credit Card" in the PreferredPaymentMode column
UPDATE customer_churn  
SET PreferredPaymentMode = 
    CASE 
        WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
        WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
        ELSE PreferredPaymentMode
    END;

-- Rename the column "PreferedOrderCat" to "PreferredOrderCat"
ALTER TABLE customer_churn 
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(255);

-- Rename the column "HourSpendOnApp" to "HoursSpentOnApp".
ALTER TABLE customer_churn 
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp INT;

--  Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.
ALTER TABLE customer_churn 
ADD COLUMN ComplaintReceived VARCHAR(3);

UPDATE customer_churn
SET ComplaintReceived = 
    CASE 
        WHEN Complain = 1 THEN 'Yes'
        ELSE 'No'
    END;

 -- Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”
ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(10);

UPDATE customer_churn
SET ChurnStatus = 
    CASE 
        WHEN Churn = 1 THEN 'Churned'
        ELSE 'Active'
    END;

--  Drop the columns "Churn" and "Complain" from the table.
ALTER TABLE customer_churn
DROP COLUMN Churn;

-- Retrieve the count of churned and active customers from the dataset.

SELECT ChurnStatus, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

-- Display the average tenure and total cashback amount of customers who churned.
SELECT 
    AVG(Tenure) AS AverageTenure,
    SUM(CashbackAmount) AS TotalCashback
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- Determine the percentage of churned customers who complained.
SELECT 
    (COUNT(CASE WHEN Complain = 1 THEN 1 END) * 100.0 / COUNT(*)) AS ChurnedWithComplaintPercentage
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- Find the gender distribution of customers who complained

SELECT Gender, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE Complain = 1
GROUP BY Gender;

-- Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.
SELECT CityTier, COUNT(*) AS ChurnedCustomerCount
FROM customer_churn
WHERE ChurnStatus = 'Churned' 
AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCustomerCount DESC
LIMIT 1;

-- Identify the most preferred payment mode among active customers.
SELECT PreferredPaymentMode, COUNT(*) AS PaymentModeCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY PaymentModeCount DESC
LIMIT 1;

-- Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
SELECT SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM customer_churn
WHERE MaritalStatus = 'Single' 
AND PreferredOrderCat = 'Mobile Phone';

-- Find the average number of devices registered among customers who used UPI as their preferred payment mode.
SELECT ROUND(AVG(NumberOfDeviceRegistered)) AS AvgDevicesRegistered
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

--  Determine the city tier with the highest number of customers.
SELECT CityTier, COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY CityTier
ORDER BY CustomerCount DESC
LIMIT 1;

--  Identify the gender that utilized the highest number of coupons
SELECT Gender, SUM(CouponUsed) AS TotalCouponsUsed
FROM customer_churn
GROUP BY Gender
ORDER BY TotalCouponsUsed DESC
LIMIT 1;

-- List the number of customers and the maximum hours spent on the app in each preferred order category.
SELECT PreferredOrderCat, 
       COUNT(*) AS CustomerCount, 
       MAX(HoursSpentOnApp) AS MaxHoursSpent
FROM customer_churn
GROUP BY PreferredOrderCat;

-- Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.
SELECT SUM(OrderCount) AS TotalOrderCount
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card' 
AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- How many customers are there who spent only one hour on the app and days since their last order was more than 5?
SELECT COUNT(*) AS CustomerCount
FROM customer_churn
WHERE HoursSpentOnApp = 1
AND DaySinceLastOrder > 5;

-- What is the average satisfaction score of customers who have complained?
SELECT AVG(SatisfactionScore) AS AvgSatisfactionScore
FROM customer_churn
WHERE Complain = 1;

-- List the preferred order category among customers who used more than 5 coupons.
SELECT PreferredOrderCat, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY CustomerCount DESC;

--  List the top 3 preferred order categories with the highest average cashback amount.
SELECT PreferredOrderCat, 
       AVG(CashbackAmount) AS AvgCashback
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY AvgCashback DESC
LIMIT 3;

--  Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders
SELECT PreferredPaymentMode, COUNT(*) AS CustomerCount
FROM customer_churn
WHERE Tenure = 10
AND OrderCount > 500
GROUP BY PreferredPaymentMode;

-- Categorize customers based on their distance from the warehouse to home suchas 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display thechurn status breakdown for each distance category.
SELECT 
    CASE 
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM customer_churn
GROUP BY DistanceCategory, ChurnStatus
ORDER BY DistanceCategory, CustomerCount DESC;

-- List the customer’s order details who are married, live in City Tier-1, and their order counts are more than the average number of orders placed by all customers.
SELECT *
FROM customer_churn
WHERE MaritalStatus = 'Married'
AND CityTier = 1
AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);

-- Create a ‘customer_returns’ table in the ‘ecomm’ database and insert
CREATE TABLE customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT NOT NULL,
    ReturnDate DATE NOT NULL,
    RefundAmount DECIMAL(10,2) NOT NULL
);
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES 
    (1001, 50022, '2023-01-01', 2130),
    (1002, 50316, '2023-01-23', 2000),
    (1003, 51099, '2023-02-14', 2290),
    (1004, 52321, '2023-03-08', 2510),
    (1005, 52928, '2023-03-20', 3000),
    (1006, 53749, '2023-04-17', 1740),
    (1007, 54206, '2023-04-21', 3250),
    (1008, 54838, '2023-04-30', 1990);

-- Display the return details along with the customer details of those who have churned and have made complaints
SELECT 
    c.CustomerID, c.CityTier, c.MaritalStatus, 
    c.PreferredOrderCat, c.PreferredPaymentMode, 
    r.ReturnID, r.ReturnDate, r.RefundAmount
FROM ecomm.customer_churn c
JOIN ecomm.customer_returns r 
    ON c.CustomerID = r.CustomerID
WHERE c.ChurnStatus = 'Churned' 
AND c.Complain = 1;

Select * from customer_churn;
Select * from customer_returns;
