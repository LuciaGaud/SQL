CREATE FUNCTION csfn_TestFuncionLucia    
(    
 @CompanyPK as uniqueidentifier,    
 @TransactionFrom as datetime,  --Never call these with null or empty values they are used in a between clause    
 @TransactionTo as datetime,  --If you dont want to filter by them pass in a very small date for From and a really large one for to    
 @JobType as varchar(3)    

)  
RETURNS TABLE
AS
RETURN
SELECT 
	JH_PK,
	JH_OA_AgentCollectAddr,
	JH_OA_LocalChargesAddr,
	JH_ParentID,      
	JH_JobNum,
	JH_JobLocalReference,
	JH_Status,  
	JH_SystemCreateTimeUtc, 
	JH_A_JOP,
	JH_A_JCL,
	JH_GB, 
	JH_GE, 
	JH_GS_NKRepOps,
	JH_GS_NKRepSales,
	JH_ProfitLossReasonCode
FROM 
	dbo.JobHeader

WHERE JH_JobNum LIKE '%123%'