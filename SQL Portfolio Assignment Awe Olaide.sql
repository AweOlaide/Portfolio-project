-- JOIN OPERATOR

--1. List the top 5 product names and their corresponding categories where the product is still being sold.
SELECT TOP 5 P.Name AS ProductName, PC.Name AS CategoryName
FROM Production.Product P
JOIN Production.ProductSubcategory PSC ON P.ProductSubcategoryID = PSC.ProductSubcategoryID
JOIN Production.ProductCategory PC ON PSC.ProductCategoryID = PC.ProductCategoryID
WHERE P.DiscontinuedDate IS NULL
ORDER BY P.Name;

--2. Retrieve the top 3 customers by their total purchase amounts
SELECT TOP 3 C.FirstName + ' ' + C.LastName AS CustomerName, SUM(SOH.TotalDue) AS TotalPurchases
FROM Sales.Customer CU
JOIN Person.Person C ON CU.PersonID = C.BusinessEntityID
JOIN Sales.SalesOrderHeader SOH ON CU.CustomerID = SOH.CustomerID
GROUP BY C.FirstName, C.LastName
ORDER BY SUM(SOH.TotalDue) DESC;

--3. Get the names of salespeople who have made at least 10 sales and the total sales amount they have made.
SELECT P.FirstName + ' ' + P.LastName AS SalesPersonName, COUNT(SOH.SalesOrderID) AS TotalOrders, SUM(SOH.TotalDue) AS TotalSales
FROM Sales.SalesPerson SP
JOIN Person.Person P ON SP.BusinessEntityID = P.BusinessEntityID
JOIN Sales.SalesOrderHeader SOH ON SP.BusinessEntityID = SOH.SalesPersonID
GROUP BY P.FirstName, P.LastName
HAVING COUNT(SOH.SalesOrderID) >= 10
ORDER BY SUM(SOH.TotalDue) DESC;


--4. List employees who have been in their department for more than 5 years, along with the department name.
SELECT P.FirstName + ' ' + P.LastName AS EmployeeName, D.Name AS DepartmentName, DATEDIFF(YEAR, EDH.StartDate, GETDATE()) AS YearsInDepartment
FROM HumanResources.Employee E
JOIN Person.Person P ON E.BusinessEntityID = P.BusinessEntityID
JOIN HumanResources.EmployeeDepartmentHistory EDH ON E.BusinessEntityID = EDH.BusinessEntityID
JOIN HumanResources.Department D ON EDH.DepartmentID = D.DepartmentID
WHERE EDH.EndDate IS NULL AND DATEDIFF(YEAR, EDH.StartDate, GETDATE()) > 5;


--5. Retrieve the top 5 products with the highest total quantity ordered
SELECT TOP 5 P.Name AS ProductName, SUM(SOD.OrderQty) AS TotalQuantityOrdered
FROM Production.Product P
JOIN Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
GROUP BY P.Name
ORDER BY SUM(SOD.OrderQty) DESC;




--SUBQUERY
--1. Find products that have not been ordered yet
SELECT P.Name AS ProductName
FROM Production.Product P
WHERE P.ProductID NOT IN (
						SELECT SOD.ProductID 
						FROM Sales.SalesOrderDetail SOD);


--2. List customers who have placed orders worth more than the average order total.
SELECT C.FirstName + ' ' + C.LastName AS CustomerName
FROM Sales.Customer CU
JOIN Person.Person C ON CU.PersonID = C.BusinessEntityID
WHERE CU.CustomerID IN (
    SELECT SOH.CustomerID 
    FROM Sales.SalesOrderHeader SOH
    WHERE SOH.TotalDue > (SELECT AVG(TotalDue) FROM Sales.SalesOrderHeader));



--3. Retrieve the name of the department with the most employees.
SELECT D.Name AS DepartmentName
FROM HumanResources.Department D
WHERE D.DepartmentID = (
    SELECT TOP 1 EDH.DepartmentID
    FROM HumanResources.EmployeeDepartmentHistory EDH
    GROUP BY EDH.DepartmentID
    ORDER BY COUNT(EDH.BusinessEntityID) DESC);



--4. Find the salesperson who made the highest total sales.
SELECT P.FirstName + ' ' + P.LastName AS SalesPersonName
FROM Sales.SalesPerson SP
JOIN Person.Person P ON SP.BusinessEntityID = P.BusinessEntityID
WHERE SP.BusinessEntityID = (
    SELECT  SOH.SalesPersonID
    FROM Sales.SalesOrderHeader SOH
    GROUP BY SOH.SalesPersonID
    ORDER BY SUM(SOH.TotalDue) DESC);




--5. List products whose prices are above the average price in their subcategory.
SELECT P.Name AS ProductName, P.ListPrice
FROM Production.Product P
WHERE P.ListPrice > (
    SELECT AVG(P2.ListPrice)
    FROM Production.Product P2
    WHERE P2.ProductSubcategoryID = P.ProductSubcategoryID);




-- CTE

--1.  Get the top 5 highest-selling products.
WITH ProductSales AS (
    SELECT P.ProductID, P.Name, SUM(SOD.OrderQty) AS TotalQuantity
    FROM Production.Product P
    JOIN Sales.SalesOrderDetail SOD ON P.ProductID = SOD.ProductID
    GROUP BY P.ProductID, P.Name)
SELECT TOP 5 Name, TotalQuantity
FROM ProductSales
ORDER BY TotalQuantity DESC;


--2. Retrieve products with prices higher than the average price.
WITH AvgPrice AS (
    SELECT AVG(ListPrice) AS AveragePrice
    FROM Production.Product)
SELECT P.Name, P.ListPrice
FROM Production.Product P, AvgPrice
WHERE P.ListPrice > AvgPrice.AveragePrice;


--3. Find salespeople with total sales above the company average.
WITH SalesData AS (
    SELECT SOH.SalesPersonID, SUM(SOH.TotalDue) AS TotalSales
    FROM Sales.SalesOrderHeader SOH
    GROUP BY SOH.SalesPersonID),
	AvgSales AS (
    SELECT AVG(TotalSales) AS AverageSales
    FROM SalesData)
SELECT P.FirstName + ' ' + P.LastName AS SalesPersonName, SD.TotalSales
FROM SalesData SD
JOIN Person.Person P ON SD.SalesPersonID = P.BusinessEntityID, AvgSales
WHERE SD.TotalSales > AvgSales.AverageSales;



--4.List departments with more than 10 employees.
WITH DepartmentCounts AS (
    SELECT EDH.DepartmentID, COUNT(EDH.BusinessEntityID) AS EmployeeCount
    FROM HumanResources.EmployeeDepartmentHistory EDH
    WHERE EDH.EndDate IS NULL
    GROUP BY EDH.DepartmentID)
SELECT D.Name AS DepartmentName, DC.EmployeeCount
FROM DepartmentCounts DC
JOIN HumanResources.Department D ON DC.DepartmentID = D.DepartmentID
WHERE DC.EmployeeCount > 10;



--5.List customers with the highest number of orders.
WITH CustomerOrderCounts AS (
    SELECT SOH.CustomerID, COUNT(SOH.SalesOrderID) AS OrderCount
    FROM Sales.SalesOrderHeader SOH
    GROUP BY SOH.CustomerID)
SELECT C.FirstName + ' ' + C.LastName AS CustomerName, CO.OrderCount
FROM CustomerOrderCounts CO
JOIN Person.Person C ON CO.CustomerID = C.BusinessEntityID
ORDER BY CO.OrderCount DESC;
