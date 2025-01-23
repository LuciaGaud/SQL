CREATE FUNCTION Report_JobProfitBrokerageFromScratch
(
    @JH_GC UNIQUEIDENTIFIER,
    @JH_FromRevenueRecognizedDate DATETIME = NULL,   -- First date range start
    @JH_ToRevenueRecognizedDate DATETIME = NULL,     -- First date range end
    @JH_FromRevenueRecognizedDate2 DATETIME = NULL,  -- Second date range start
    @JH_ToRevenueRecognizedDate2 DATETIME = NULL,    -- Second date range end
    @JH_DepartmentPKList NVARCHAR(3899) = NULL
)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        COALESCE(A.JH_LocalClientCode, B.JH_LocalClientCode) AS JH_LocalClientCode,
        COALESCE(A.JH_LocalClientName, B.JH_LocalClientName) AS JH_LocalClientName,
        ISNULL(A.WIPAmount, 0)  AS A_WIPAmount,
        ISNULL(B.WIPAmount, 0)  AS B_WIPAmount,
        ISNULL(A.CSTAmount, 0)  AS A_CSTAmount,
        ISNULL(B.CSTAmount, 0)  AS B_CSTAmount,
        ISNULL(A.ACRAmount, 0)  AS A_ACRAmount,
        ISNULL(B.ACRAmount, 0)  AS B_ACRAmount,
        ISNULL(A.REVAmount, 0)  AS A_REVAmount,
        ISNULL(B.REVAmount, 0)  AS B_REVAmount,
        ISNULL(A.JH_Profit, 0)  AS A_JH_Profit,
        ISNULL(B.JH_Profit, 0)  AS B_JH_Profit,
        @JH_DepartmentPKList AS DepartmentList -- New field added
    FROM
    (
        -- First date range data
        SELECT 
            LocalClient.OH_Code AS JH_LocalClientCode,
            LocalClient.OH_FullName AS JH_LocalClientName,
            SUM(WIPAmount) AS WIPAmount,
            SUM(CSTAmount) AS CSTAmount,
            SUM(ACRAmount) AS ACRAmount,
            SUM(REVAmount) AS REVAmount,
            SUM(AL_LineAmount) AS JH_Profit
        FROM  
            JobDeclaration
        INNER JOIN 
            JobHeader ON JE_PK = JH_ParentID 
        LEFT JOIN 
            OrgAddress AS LocalClientAddress ON JH_OA_LocalChargesAddr = LocalClientAddress.OA_PK
        LEFT JOIN 
            OrgHeader AS LocalClient ON LocalClientAddress.OA_OH = LocalClient.OH_PK 
        OUTER APPLY 
            dbo.csfn_TransactionLinesForPeriod(@JH_FromRevenueRecognizedDate, DATEADD(DAY, 1, @JH_ToRevenueRecognizedDate), 'N', 'N', JH_PK) --because the fime is 00:00 so it does not inlcude the last day
                     
        GROUP BY 
            LocalClient.OH_Code,
            LocalClient.OH_FullName
       /* HAVING 
        SUM(AL_LineAmount) > 0 */
    ) AS A
    FULL OUTER JOIN
    (
        -- Second date range data
        SELECT 
            LocalClient.OH_Code AS JH_LocalClientCode,
            LocalClient.OH_FullName AS JH_LocalClientName,
            SUM(WIPAmount) AS WIPAmount,
            SUM(CSTAmount) AS CSTAmount,
            SUM(ACRAmount) AS ACRAmount,
            SUM(REVAmount) AS REVAmount,
            SUM(AL_LineAmount) AS JH_Profit,
            @JH_DepartmentPKList AS DepartmentList -- New field added
        FROM  
            JobDeclaration
        INNER JOIN 
            JobHeader ON JE_PK = JH_ParentID 
        LEFT JOIN 
            OrgAddress AS LocalClientAddress ON JH_OA_LocalChargesAddr = LocalClientAddress.OA_PK
        LEFT JOIN 
            OrgHeader AS LocalClient ON LocalClientAddress.OA_OH = LocalClient.OH_PK 
        OUTER APPLY 
            dbo.csfn_TransactionLinesForPeriod(@JH_FromRevenueRecognizedDate2, DATEADD(DAY, 1, @JH_ToRevenueRecognizedDate2), 'N', 'N', JH_PK) --because the fime is 00:00 so it does not inlcude the last day

        GROUP BY 
            LocalClient.OH_Code,
            LocalClient.OH_FullName
    ) AS B
    ON A.JH_LocalClientCode = B.JH_LocalClientCode
    WHERE
    A.REVAmount >0 
);
