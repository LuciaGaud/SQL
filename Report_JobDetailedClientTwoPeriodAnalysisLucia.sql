CREATE FUNCTION Report_JobDetailedClientTwoPeriodAnalysisLucia
(
	@JH_GC UNIQUEIDENTIFIER
	,@GC_RN_NK CHAR(2)
	,@period1From Datetime 
	,@period1To Datetime
	,@period2From Datetime 
	,@period2To Datetime
	,@UseLocalClient CHAR(1)
	,@UseInvoiceDates CHAR(1)
	,@AC_PK UNIQUEIDENTIFIER
	,@AC_ChargeGroupInclude UNIQUEIDENTIFIER
	,@AC_ChargeGroupExclude UNIQUEIDENTIFIER
	,@AL_GB UNIQUEIDENTIFIER
	,@AL_GE UNIQUEIDENTIFIER
	,@JH_GS_SalesRep UNIQUEIDENTIFIER
	,@JH_GS_OpsRep UNIQUEIDENTIFIER
	,@JH_GB UNIQUEIDENTIFIER
	,@JH_GE UNIQUEIDENTIFIER
	,@JK_Agent UNIQUEIDENTIFIER
	,@JK_TransportMode CHAR(3)
	,@JK_ConsolMode CHAR(3)
	,@JK_RL_NKPortForDirection CHAR(5)
	,@JK_RN CHAR(2)
	,@JS_TransportMode CHAR(3)
	,@JS_Direction CHAR(3)
	,@JK_RL_NKPortForConsolAgent CHAR(5)
    ,@MaxPercentage FLOAT
)
RETURNS TABLE
AS
RETURN 
SELECT
	OrgHeaderClient.OH_Code as OH_CodeClient, 
	OrgHeaderClient.OH_FullName as OH_FullNameClient,
	JS_OH_Client,
	JH_RecordCountAIRPeriod1,
	JS_ActualChargeableAIRPeriod1,  
	AL_ProfitAIRPeriod1,  
	RevenueAIRPeriod1,  
	JH_RecordCountFCLPeriod1,  
	JS_JC_TEUFCLPeriod1,  
	AL_LineAmountFCLPeriod1,  
	RevenueFCLPeriod1,  
	JH_RecordCountLCLPeriod1,  
	JS_ActualChargeableLCLGRPPeriod1,  
	JS_ActualChargeableLCLOTHPeriod1,
	AL_LineAmountLCLGRPPeriod1,  
	AL_LineAmountLCLOTHPeriod1,  
	RevenueLCLGRPPeriod1,  
	RevenueLCLOTHPeriod1,  
	JH_RecordCountOTHPeriod1,  
	JS_ActualChargeableOTHPeriod1,  
	AL_LineAmountOTHPeriod1,  
	RevenueOTHPeriod1,  
	JH_RecordCountAIRPeriod2,  
	JS_ActualChargeableAIRPeriod2,  
	AL_ProfitAIRPeriod2,  
	RevenueAIRPeriod2,  
	JH_RecordCountFCLPeriod2,  
	JS_JC_TEUFCLPeriod2,  
	AL_LineAmountFCLPeriod2,  
	RevenueFCLPeriod2,  
	JH_RecordCountLCLPeriod2,  
	JS_ActualChargeableLCLGRPPeriod2,  
	JS_ActualChargeableLCLOTHPeriod2,  
	AL_LineAmountLCLGRPPeriod2,  
	AL_LineAmountLCLOTHPeriod2,  
	RevenueLCLGRPPeriod2,  
	RevenueLCLOTHPeriod2,  
	JH_RecordCountOTHPeriod2,  
	JS_ActualChargeableOTHPeriod2,  
	AL_LineAmountOTHPeriod2,  
	RevenueOTHPeriod2,
CAST(
            (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0))
            AS FLOAT
        ) AS Period1,
CAST(
            (ISNULL(Al_LineAmountFCLPeriod2, 0) + ISNULL(AL_LineAmountLCLGRPPeriod2, 0) + ISNULL(AL_LineAmountLCLOTHPeriod2, 0) 
               + ISNULL(AL_LineAmountOTHPeriod2, 0) + ISNULL(AL_ProfitAIRPeriod2, 0))
            AS FLOAT
        ) AS Period2,
-- New Column: ActualPercentage
CASE 
    WHEN 
        (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0)) != 0 
    THEN 
        CAST(
               (ISNULL(Al_LineAmountFCLPeriod2, 0) + ISNULL(AL_LineAmountLCLGRPPeriod2, 0) + ISNULL(AL_LineAmountLCLOTHPeriod2, 0) 
               + ISNULL(AL_LineAmountOTHPeriod2, 0) + ISNULL(AL_ProfitAIRPeriod2, 0))
            - (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0))
            AS FLOAT
        ) 
        / CAST(
            (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0))
            AS FLOAT
        )
    ELSE 
        NULL 
END AS ActualPercentage



FROM
	dbo.csfn_JobDetailedAnalysisClientTwoPeriodSummary 
		(
			@JH_GC 
			,@GC_RN_NK 
			,@period1From  
			,@period1To 
			,@period2From  
			,@period2To 
			,@UseLocalClient 
			,@UseInvoiceDates 
			,@AC_PK
			,@AC_ChargeGroupInclude
			,@AC_ChargeGroupExclude 
			,@AL_GB 
			,@AL_GE 
			,@JH_GS_SalesRep
			,@JH_GS_OpsRep
			,@JH_GB
			,@JH_GE
			,@JK_Agent 
			,@JK_TransportMode
			,@JK_ConsolMode 
			,@JK_RL_NKPortForDirection
			,@JK_RN
			,@JS_TransportMode
			,@JS_Direction
			,@JK_RL_NKPortForConsolAgent
		)
	INNER JOIN dbo.OrgHeader OrgHeaderClient  
		ON csfn_JobDetailedAnalysisClientTwoPeriodSummary.JS_OH_Client = OrgHeaderClient.OH_PK

-- Filter only rows where ActualPercentage < -MaxPercentage
WHERE 
    CASE 
        WHEN 
                    (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0)) != 0 
        THEN 
CAST(
            (ISNULL(Al_LineAmountFCLPeriod2, 0) + ISNULL(AL_LineAmountLCLGRPPeriod2, 0) + ISNULL(AL_LineAmountLCLOTHPeriod2, 0) 
               + ISNULL(AL_LineAmountOTHPeriod2, 0) + ISNULL(AL_ProfitAIRPeriod2, 0))
            - (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0))
            AS FLOAT
        ) 
        / CAST(
          (ISNULL(Al_LineAmountFCLPeriod1, 0) + ISNULL(AL_LineAmountLCLGRPPeriod1, 0) + ISNULL(AL_LineAmountLCLOTHPeriod1, 0) 
               + ISNULL(AL_LineAmountOTHPeriod1, 0) + ISNULL(AL_ProfitAIRPeriod1, 0))
            AS FLOAT
        )
        ELSE NULL 
    END < CAST((@MaxPercentage / 100.0) * -1 AS FLOAT);