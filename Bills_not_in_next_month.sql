--Removing Duplicates
WITH INVOICE_NEW_CLEAN  AS(
		  SELECT * 
		  FROM [Invoice_new_data].[dbo].[Sheet1$] 
		  

		  EXCEPT


		  SELECT VENDOR,COMPANY_NAME,ACCOUNT_NUMBER,
			     BILL_DATE,INVOICE_NUMBER,
				 SUB_ACCOUNT,ASSET,BILL_TYPE,
				 TOTAL_CHARGED
		  FROM [Invoice_new_data].[dbo].[Sheet1$]
		  GROUP BY VENDOR,COMPANY_NAME,
		 		   ACCOUNT_NUMBER,BILL_DATE,
				   INVOICE_NUMBER,SUB_ACCOUNT,
				   ASSET,BILL_TYPE,TOTAL_CHARGED
		  HAVING COUNT(*) > 1
		 )
--using rank to extract the bills which is not in the next month
, TEMPTABLE AS (
			SELECT *, rank - 1 AS prerank
			FROM (
					SELECT [VENDOR]
					  ,[COMPANY_NAME]
					  ,[ACCOUNT_NUMBER]
					  ,[BILL_DATE]
					  ,[INVOICE_NUMBER]
					  ,[SUB_ACCOUNT]
					  ,[ASSET]
					  ,[BILL_TYPE]
					  ,[TOTAL_CHARGED]
					  ,DENSE_RANK() OVER (PARTITION BY VENDOR,COMPANY_NAME,account_number,ASSET,BILL_TYPE ORDER BY BILL_DATE) AS rank
					 FROM INVOICE_NEW_CLEAN)AS T
						)

SELECT VENDOR, COMPANY_NAME,
	   ACCOUNT_NUMBER,BILL_DATE AS ACTUAL_BILL_DATE
	   ,INVOICE_NUMBER, SUB_ACCOUNT,
	   ASSET, BILL_TYPE, TOTAL_CHARGED,
	   	   --A key used to join data togther in BI
	   DATEADD(MONTH,+1, CONVERT(varchar,DD,1)) AS MONTH_KEY

FROM (
	--Self Joining the table to extract the needed data
		SELECT L.VENDOR 
			  ,L.COMPANY_NAME
			  ,L.ACCOUNT_NUMBER
			  ,L.BILL_DATE 
			  ,L.INVOICE_NUMBER
			  ,L.SUB_ACCOUNT
			  ,L.ASSET
			  ,L.BILL_TYPE
			  ,L.TOTAL_CHARGED
			  ,J.BILL_DATE AS NEXT_BILL_DATE
			  ,J.ACCOUNT_NUMBER AS NEXT_ACCOUNT_NUMBER
			  ,J.ASSET AS NEXT_ASSET
			  ,J.BILL_TYPE AS NEXT_BILL_TYPE
			  --making a date which groups all bills within the same month into first day of the month
			  ,CONCAT(MONTH(L.BILL_DATE) ,'/1/',YEAR(L.BILL_DATE)) AS DD

		from TEMPTABLE AS L
		left JOIN TEMPTABLE AS J ON
			L.RANK = J.prerank AND 
			L.ACCOUNT_NUMBER = J.ACCOUNT_NUMBER AND
			L.BILL_TYPE = J.BILL_TYPE AND 
			L.ASSET = J. ASSET) AS y
WHERE NEXT_BILL_DATE IS NULL
