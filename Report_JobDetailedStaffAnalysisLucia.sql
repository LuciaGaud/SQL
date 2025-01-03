CREATE FUNCTION Report_JobDetailedStaffAnalysis
	(
		@JH_GC UNIQUEIDENTIFIER,
		@O8_Role CHAR(4),
		@GC_RN_NK AS CHAR(2),	
		@LocalClient char(1), 
		@UseAttributedTo char(1),
		@DateType CHAR(1),
		@Period1FromDate as DATETIME, 
		@Period1ToDate as DATETIME, 
		@ChargeCode as varchar(4000),
		@TransactionBranch as varchar(4000),
		@TransactionDepartment as varchar(4000),
		@JF_TransportMode as CHAR(3),
		@JF_Direction as CHAR(3), 
		@JH_GS_OpsRepList as nvarchar(4000), 
		@JH_GS_SalesRepList AS nvarchar(4000),
		@JH_GEList AS nvarchar(4000),
		@JH_GBList AS nvarchar(4000),
		@O8_GS_ResponsiblePersonList AS nvarchar(4000),
		@O8_GS_GEList AS nvarchar(4000),
		@JK_RL_NKPortForDirection AS CHAR(5), 
		@JK_OH_AgentForDirection as UNIQUEIDENTIFIER
	)
RETURNS TABLE
WITH SCHEMABINDING
AS 
RETURN 
SELECT
	GS_Code,  
	GS_FullName,
	OH_Code, 
	OH_FullName,
	JF_OH, 
	O8_GS_ResponsiblePerson,
	JH_RecordCountAIR, 
	JS_ActualChargeableAIR,
	AL_ProfitAIR,
	JH_RecordCountFCL,
	JS_JC_CountFCL,
	JS_JC_TEUFCL,
	AL_LineAmountFCL,
	JH_RecordCountLCL,
	JS_ActualChargeableLCLGRP, 
	JS_ActualChargeableLCLOTH,
	AL_LineAmountLCLGRP, 
	AL_LineAmountLCLOTH,
	JH_RecordCountOTH, 
	JS_ActualChargeableOTH,
	AL_LineAmountOTH,
	ISNULL(JH_RecordCountAIR,0) + ISNULL(JH_RecordCountOTH,0) + ISNULL(JH_RecordCountLCL,0) + ISNULL(JH_RecordCountFCL,0) as JobCountGrandTotal,
	ISNULL(AL_ProfitAIR,0) + ISNULL(AL_LineAmountOTH,0) + ISNULL(AL_LineAmountLCLOTH,0) + ISNULL(AL_LineAmountLCLGRP,0)+ ISNULL(Al_LineAmountFCL,0) as JobProfitGrandTotal
from 
	dbo.csfn_JobDetailedAnalysisClientStaffSummary 
		(
			@JH_GC,
			@O8_Role ,
			@GC_RN_NK ,
			@LocalClient, 
			@UseAttributedTo ,
			@DateType ,
			@Period1FromDate, 
			@Period1ToDate,
			@ChargeCode,
			@TransactionBranch,
			@TransactionDepartment,
			@JF_TransportMode,
			@JF_Direction, 
			@JH_GS_OpsRepList,
			@JH_GS_SalesRepList,
			@JH_GEList,
			@JH_GBList,
			@O8_GS_ResponsiblePersonList,
			@JK_RL_NKPortForDirection, 
			@JK_OH_AgentForDirection
		)
		INNER JOIN dbo.OrgHeader  on csfn_JobDetailedAnalysisClientStaffSummary.JF_OH = OH_PK 
		LEFT JOIN dbo.GLBStaff  on csfn_JobDetailedAnalysisClientStaffSummary.O8_GS_ResponsiblePerson = GS_PK 
WHERE
	(ISNULL(@O8_GS_GEList,'') = '' or charindex(CAST(GS_GE_HomeDepartment AS VARCHAR(36)), @O8_GS_GEList) > 0)