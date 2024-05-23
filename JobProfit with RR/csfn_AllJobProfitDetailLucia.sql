CREATE FUNCTION csfn_AllJobProfitDetailLucia
(
	@CompanyPK AS uniqueidentifier,
	@TransactionFrom AS datetime,  --Never call these with null or empty values they are used in a between clause
	@TransactionTo AS datetime, 	--If you dont want to filter by them pass in a very small date for From and a really large one for to
	@JobType AS char(1),
	@OutstandingWIP AS char(1),
	@OutstandingACR AS char(1),
	@ChargeCode AS varchar(4000),
	@ChargeCodeNOTIN as varchar(4000), 
	@ChargeGroup AS varchar (4000),
	@SalesGroup AS uniqueidentifier,
	@ExpenseGroup AS uniqueidentifier,
	@TransactionBranch AS varchar(4000),
	@TransactionDepartment AS varchar(4000),
	@TransactionDebtor AS varchar(4000),
	@TransactionCreditor AS varchar(4000),
	@PostedOnly AS Char(1)  
)
RETURNS TABLE AS
RETURN

	(
	SELECT  
	JH_PK,
	JH_OA_AgentCollectAddr,
	JH_OA_LocalChargesAddr,
	JH_ParentID,
	JH_JobNum,
	JH_JobLocalReference,
	JH_Status,
	JH_SystemCreateTimeUtc,
	JH_A_JOP AS JH_A_JOP,
	JH_A_JCL AS JH_A_JCL,
	JH_RevenueRecognizedDate,
	JH_GB,
	JH_GE,
	JH_GS_NKRepOps,
	JH_GS_NKRepSales,
	JH_ProfitLossReasonCode,
	AL_JH,
	AL_PK,
	AL_AC,
	AC_ChargeType,
	AL_GE,
	AL_GB,
	AL_AH,
	AL_OH,
	AL_PostDate,
 	AL_ReverseDate,
	AL_LineType,
	AL_Desc,
	AL_RevRecognitionType,
	AL_LineAmount * CASE WHEN AL_LineType in ('REV', 'CST') OR AL_ReverseDate IS NULL OR AL_ReverseDate < @TransactionFrom OR AL_ReverseDate >= @TransactionTo THEN 1 ELSE -1 END AS AL_LineAmount,
	WIPAmount     * CASE WHEN AL_ReverseDate IS NULL OR AL_ReverseDate < @TransactionFrom OR AL_ReverseDate >= @TransactionTo THEN 1 ELSE -1 END AS WIPAmount,
	CSTAmount AS CSTAmount,
	ACRAmount     * CASE WHEN AL_ReverseDate IS NULL OR AL_ReverseDate < @TransactionFrom OR AL_ReverseDate >= @TransactionTo THEN 1 ELSE -1 END AS ACRAmount,
	REVAmount AS REVAmount,
	CASE WHEN AL_LineType in ('ACR', 'WIP') AND AL_PostDate >= @TransactionFrom AND AL_PostDate < @TransactionTo AND (AL_ReverseDate IS NULL OR AL_ReverseDate < @TransactionFrom OR AL_ReverseDate >= @TransactionTo) THEN AL_PostDate ELSE AL_ReverseDate END AS AL_RevenueRecognitionDate,
	CASE   
		WHEN AL_JH IS NULL THEN  
			'N'  
		ELSE  
			'Y'  
	END AS AL_LinesExistForCriteria,  

	JH_GC, 

	JHBranch.GB_Code AS JH_BranchCode,
	JHBranch.GB_PK AS JH_BranchCodePK,
	JHDept.GE_Code AS JH_DepartmentCode, 
	JHDept.GE_PK AS JH_DepartmentCodePK, 
	JHOperator.GS_PK AS JH_OperatorPK,
	JHOperator.GS_Code AS JH_OperatorInitials,
	JHSalesRep.GS_PK AS JH_SalesRepPK,
	JHSalesRep.GS_Code AS JH_SalesRepInitials,
	LocalClient.OH_Code AS JH_LocalClientCode, 
	LocalClient.OH_FullName AS JH_LocalClientName,
	LocalClient.OH_PK AS JH_OH_LocalCharges,
	AH_TransactionNum,
	CASE WHEN AL_LineType in ('ACR', 'WIP')
	THEN 
		ALOrg.OH_Code
	ELSE
		AHOrg.OH_Code	
	END AS AH_OrgCode,
	CASE WHEN AL_LineType in ('ACR', 'WIP')
	THEN
		ALOrg.OH_FullName 
	ELSE
		AHOrg.OH_FullName
	END AS AH_OrgName,
	AC_PK,
	AC_Code,
	AC_Desc,
	AC_ChargeGroup,
	AC_AR_SalesGroup,
	AC_AR_ExpenseGroup,
	ALBranch.GB_Code AS AL_BranchCode,
	ALDept.GE_Code AS AL_DepartmentCode,
 
	CASE WHEN AL_LineType in ('ACR', 'WIP') AND AL_PostDate >= @TransactionFrom AND AL_PostDate < @TransactionTo AND (AL_ReverseDate IS NULL OR AL_ReverseDate < @TransactionFrom OR AL_ReverseDate >= @TransactionTo) THEN AL_PostDate ELSE AL_ReverseDate END AS LineRecogDate,

  

	AL_LineAmount * CASE WHEN AL_LineType in ('REV', 'CST') OR AL_ReverseDate IS NULL OR AL_ReverseDate < @TransactionFrom OR AL_ReverseDate >= @TransactionTo THEN 1 ELSE -1 END AS JH_Profit
FROM 
	dbo.JobHeader 
	INNER JOIN dbo.GLBBranch JHBranch ON JH_GB = JHBranch.GB_PK 
	INNER JOIN dbo.GLBDepartment JHDept ON JH_GE = JHDept.GE_PK 
	LEFT JOIN dbo.GLBStaff JHOperator ON JH_GS_NKRepOps = JHOperator.GS_Code 
	LEFT JOIN dbo.GLBStaff JHSalesRep ON JH_GS_NKRepSales = JHSalesRep.GS_Code 
	LEFT JOIN dbo.OrgAddress As LocalClientAddress ON JH_OA_LocalChargesAddr = OA_PK 
	LEFT JOIN dbo.OrgHeader LocalClient ON LocalClientAddress.OA_OH = LocalClient.OH_PK 
	LEFT JOIN dbo.vw_ClassifiedTransactionLineAmountsIncludingCancelled ATLOutter on JH_PK = AL_JH 
	LEFT JOIN dbo.GLBBranch ALBranch ON AL_GB = ALBranch.GB_PK 
	LEFT JOIN dbo.GLBDepartment ALDept ON AL_GE = ALDept.GE_PK 
	LEFT JOIN dbo.OrgHeader ALOrg ON AL_OH = ALOrg.OH_PK 
	INNER JOIN dbo.AccChargeCode ACOutter ON AL_AC = AC_PK 
	LEFT JOIN dbo.AccTransactionheader ON AL_AH = AH_PK 
	LEFT JOIN dbo.OrgHeader AHOrg ON AH_OH = AHOrg.OH_PK 
	LEFT JOIN dbo.JobShipment ON JH_ParentID = JS_PK 

WHERE 
	JH_GC = @CompanyPK 
	AND (@OutstandingWIP = '' or (@OutstandingWIP = 'Y' and WIPAmount <> 0)) 
	AND (@OutstandingACR = '' or (@OutstandingACR = 'Y' and ACRAmount <> 0))
	AND  
	(
		(
			(
				AL_LineType in ('ACR', 'WIP') 
				AND
				(
					(  
						Al_ReverseDate >= @TransactionFrom AND Al_ReverseDate < @TransactionTo 
						AND (AL_PostDate < @TransactionFrom OR AL_PostDate >= @TransactionTo )
					)
					OR  
					(  
						AL_PostDate >= @TransactionFrom AND AL_PostDate < @TransactionTo AND  
						(
							AL_ReverseDate IS NULL 
							OR AL_ReverseDate < @TransactionFrom 
							OR AL_ReverseDate >= @TransactionTo
						)
					)
				)
			)
			OR
			(
				AL_LineType in ('REV', 'CST') 
				AND AL_ReverseDate >= @TransactionFrom AND AL_ReverseDate < @TransactionTo 
			)  
		) 
	)
	AND	(@ChargeCode = '' or charindex(CAST(AC_PK AS VARCHAR(50)),@ChargeCode) > 0) AND
	(@ChargeGroup IS NULL OR AC_ChargeGroup = @ChargeGroup)	AND
	(@TransactionBranch = '' or charindex(CAST(ALBranch.GB_PK AS VARCHAR(50)),@TransactionBranch) > 0) and
	(@TransactionDepartment = '' or charindex(CAST(ALDept.GE_PK AS VARCHAR(50)), @TransactionDepartment) > 0) and
	(@TransactionDebtor = ''   or (AL_LineType = 'REV' and charindex(CAST(AHOrg.OH_PK AS VARCHAR(50)), @TransactionDebtor) > 0) or (AL_LineType = 'WIP' and charindex(CAST(ALOrg.OH_PK AS VARCHAR(50)), @TransactionDebtor) > 0)) and
	(@TransactionCreditor = '' or (AL_LineType = 'CST' and charindex(CAST(AHOrg.OH_PK AS VARCHAR(50)), @TransactionCreditor) > 0) or (AL_LineType = 'ACR' and charindex(CAST(ALOrg.OH_PK AS VARCHAR(50)), @TransactionCreditor) > 0))AND
	(
		(JH_ParentTableCode in ('ET', 'WD') AND @JobType = 'W') OR
		(JH_ParentTableCode = 'JE' AND @JobType = 'D') OR
		(JH_ParentTableCode = 'JS' AND @JobType = 'S') OR
		(JH_ParentTableCode = 'JK' AND @JobType = 'L') OR
		(JH_ParentTableCode = 'JS' and JS_IsCFSRegistered = 1 and @JobType = 'L') OR
		(JH_ParentTableCode = 'JJ' and @JobType ='C') OR
		(JH_ParentTableCode = 'JM' and @JobType ='M') OR
		(@JobType in ('A', ''))
	) AND
	(@PostedOnly = '' OR (@PostedOnly = 'Y' AND AL_LIneType in ( 'REV', 'CST'))
	)

	


);