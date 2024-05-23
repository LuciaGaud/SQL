CREATE PROC Report_LocalCartageLegsByVehicleOrTransportCompanyLucia
	(
		@PickupTimeOutFrom	DATETIME			= NULL,
		@PickupTimeOutTo	DATETIME			= NULL,
		@DeliverTimeOutFrom	DATETIME			= NULL,
		@DeliverTimeOutTo	DATETIME			= NULL,
		@LegTypeMode		VARCHAR(3)			= '',
		@TransportCompany	UNIQUEIDENTIFIER	= NULL,
		@Vehicle			UNIQUEIDENTIFIER	= NULL,
		@JobLocalClient		UNIQUEIDENTIFIER	= NULL,
		@Chargeable			VARCHAR(3)			= '',
		@LocalCartageBranch	UNIQUEIDENTIFIER	= NULL,
		@JobHeaderFK		UNIQUEIDENTIFIER	= NULL,
		@CurrentCompanyPK	UNIQUEIDENTIFIER	= NULL,
		@DeliveryCompany	UNIQUEIDENTIFIER	= NULL,
		@ETAFrom			DATETIME			= NULL,
		@ETATo			DATETIME			= NULL,
		@ETA			DATETIME			= NULL,
		@CurrentCountry char(2) = 'GB'
	)		
AS
BEGIN 

SET NOCOUNT ON 

SELECT
--Job Details
	JJ_ConsignmentID,
	JobType,
	JJ_DropMode,
	JJ_RS_NKServiceLevel,
	JJ_GoodsDescription,
	JJ_Weight,
	JJ_WeightUQ,
	JJ_Volume,
	JJ_VolumeUQ,
	JJ_PK,
	JJ_ParentID,
	JJ_ParentTableCode,

	JobContainerCount,
	JobTEU,
	JobLegCount, 
	JobChargeableLegCount,
	--do we need these below?
	JobLegCountByOwnVehicles,
	JobLegCountByTransportCo,
	JobChargeableLegCountByOwnVehicles,
	JobChargeableLegCountByTransportCo,
	
--Leg Carrier Details
	LegMovedBy,
	StaffDriver,
	NonStaffDriver,
	TransportCo,
	ContractorTruck,
	VehicleCode,

--Leg Details	
	LegTypeMode, --CNT/LSE
	FromOrgType,
	WaitOrgType,
	ToOrgType,
	PickupOrganisation,
	WaitPointOrganisation,
	DeliverOrganisation,
	IsEmptyContainer,
	Volume,
	VolumeUnit,
	Weight,
	WeightUnit,
	JU_PlannedPickupTime,
	JU_EstimatedDeliveryTime,
	JU_PickupTimeIn,
	JU_PickupTimeOut,
	JU_DeliverTimeIn,
	JU_DeliverTimeOut,
        JU_LegNotes,
	LegTime,
	AdditionalService,
	LegTEU,

--Job Header Details
	BranchPK, 
	BranchCode,
	JobHeaderPK,
	DepartmentCode,
	HeaderLocalClientCode,
	HeaderLocalClientName,
	
--Job Total Charges
	JobWIP,
	JobREV,
	JobIncome,
	JobIncome/JobLegCountMin1																	AS JobIncomePerLeg,
	CASE WHEN IsChargeable = 'N' AND JobHasChargeableLegs = 'Y' THEN 0 ELSE JobIncome END
	/ JobChargeableLegCountOrJobLegCount														AS JobIncomePerChargeableLeg,

--Job Only Charges
	JobOnlyWIP,
	JobOnlyREV,
	JobOnlyIncome,
	JobOnlyIncome/JobLegCountMin1																AS JobOnlyIncomePerLeg,
	CASE WHEN IsChargeable = 'N' AND JobHasChargeableLegs = 'Y' THEN 0 ELSE JobOnlyIncome/JobChargeableLegCountOrJobLegCount END AS JobOnlyIncomePerChargeableLeg,

--Leg Only Charges
	IsChargeable,
	CASE WHEN IsChargeable = 'Y' THEN 1 ELSE 0 END												AS IsChargeableCount,
	LegOnlyWIP,
	LegOnlyREV,
	LegOnlyIncome,

--Combination of Charges (LegOnly+JobOnlyAVG)
	LegOnlyIncome + (JobOnlyIncome/JobLegCountMin1)												AS LegOnlyIncomeAndJobOnlyIncomePerLeg,
	LegOnlyIncome + (CASE WHEN IsChargeable = 'N' AND JobHasChargeableLegs = 'Y' THEN 0 ELSE JobOnlyIncome/JobChargeableLegCountOrJobLegCount END) AS LegOnlyIncomeAndJobOnlyIncomePerChargeableLeg,
	One,
--Container
	ContainerNumber,
	ContainerStatus,
--Shipment
	ShipmentNumber,
	GoodsDescription,
--JobConsolTransport
	ATA,
	ATD,
	ETD,
	ETA,
	Vessel

FROM
(
SELECT
--	*,
JU_PlannedPickupTime,
JU_EstimatedDeliveryTime,
JU_PickupTimeIn,
JU_PickupTimeOut,
JU_DeliverTimeIn,
JU_DeliverTimeOut,
JU_LegNotes,

	(datepart(dayofyear, JU_DeliverTimeOut)-1) * 24 + datepart(hour, JU_DeliverTimeOut) + (cast(datePart(minute, JU_DeliverTimeOut) as decimal) / 60) AS DELIVERHOUR,
	(datepart(dayofyear, JU_PickupTimeOut)-1) * 24 + datepart(hour, JU_PickupTimeOut) + (cast(datePart(minute, JU_PickupTimeOut) as decimal) / 60) AS PICKUPHOUR,

	((datepart(dayofyear, JU_DeliverTimeOut)-1) * 24 + datepart(hour, JU_DeliverTimeOut) + (cast(datePart(minute, JU_DeliverTimeOut) as decimal) / 60)) -
	((datepart(dayofyear, JU_PickupTimeOut)-1) * 24 + datepart(hour, JU_PickupTimeOut) + (cast(datePart(minute, JU_PickupTimeOut) as decimal) / 60))
	/*DeliverTimeOut - PickupTimeOut = */				AS LegTime,
	PickupDocAddress.E2_AddressType						AS FromOrgType,
	WaitPointDocAddress.E2_AddressType					AS WaitOrgType,
	DeliveryDocAddress.E2_AddressType					AS ToOrgType,
	JJ_E3_NKJobType										AS JobType,
	CASE
		WHEN JobContainerCount > 0 THEN 'CNT'
		ELSE 'LSE'
	End													AS LegTypeMode,
	Truck.RQ_ShortCode									AS VehicleCode,
	ContainerFile.JC_ContainerNum								AS ContainerNumber,
	ContainerFile.JC_ContainerStatus							AS ContainerStatus,
	MainConTrans.JW_ATD									AS ATD,						
	MainConTrans.JW_ATA									AS ATA,
	MainConTrans.JW_ETA									AS ETA,
	MainConTrans.JW_ETD									AS ETD,
	MainConTrans.JW_Vessel									AS Vessel,	
	Shipment.JS_UniqueConsignRef								AS ShipmentNumber,
	Shipment.JS_GoodsDescription								AS GoodsDescription,
	Driver.GS_FullName									AS StaffDriver,
	EY_DriversName										AS NonStaffDriver,
	TransportCo.OH_Code									AS TransportCo,
	EY_TruckRegistration								AS ContractorTruck,
	JU_IsEmptyContainer									AS IsEmptyContainer,
	JU_AdditionalService								AS AdditionalService,
	CASE
		WHEN PickupDocAddress.E2_CompanyName = ''
			THEN PickupOrgHeader.OH_Code 
		ELSE PickupDocAddress.E2_CompanyName
	END													AS PickupOrganisation,
	CASE 
		WHEN WaitPointDocAddress.E2_CompanyName = ''
			THEN WaitPointOrgHeader.OH_Code 
		ELSE WaitPointDocAddress.E2_CompanyName
	END													AS WaitPointOrganisation,
	CASE 
		WHEN DeliveryDocAddress.E2_CompanyName = ''
			THEN DeliveryOrgHeader.OH_Code 
		ELSE DeliveryDocAddress.E2_CompanyName
	END													AS DeliverOrganisation,
	JobContainerCount,
	JobTEU,
	COALESCE(JobLegCount,0)								AS JobLegCount,
	COALESCE(JobChargeableLegCount,0)					AS JobChargeableLegCount,
	COALESCE(JobLegCountByOwnVehicles,0)				AS JobLegCountByOwnVehicles,
	COALESCE(JobLegCountByTransportCo,0)				AS JobLegCountByTransportCo,
	COALESCE(JobChargeableLegCountByOwnVehicles,0)		AS JobChargeableLegCountByOwnVehicles,
	COALESCE(JobChargeableLegCountByTransportCo,0)		AS JobChargeableLegCountByTransportCo,
	JJ_ParentTableCode,
	CASE 
		WHEN EY_OH_TransportCo IS NOT NULL
			THEN TransportCo.OH_Code + ' (Transport Co)'
		WHEN EY_RQ_Truck IS NOT NULL
			THEN Truck.RQ_ShortCode + ' (Vehicle)'
		WHEN EY_RQ_Truck IS NULL AND EY_OH_TransportCo IS NULL
			THEN ' No Carrier'
	END													AS LegMovedBy,
	EW_BookedVolume										AS Volume,
	EW_VolumeUQ											AS VolumeUnit,
	EW_BookedWeight										AS Weight,
	EW_WeightUQ											AS WeightUnit,
	RC_TEU												AS LegTEU,
	JJ_PK,
	JJ_ParentID,
	GB_PK												AS BranchPK, 
	GB_Code												AS BranchCode,
	JH_PK												AS JobHeaderPK,
	GE_Code												AS DepartmentCode,
	LocalClient.OH_Code									AS HeaderLocalClientCode,
	LocalClient.OH_FullName									AS HeaderLocalClientName,
	JJ_ConsignmentID,
	JJ_DropMode,
	JJ_RS_NKServiceLevel,
	JJ_GoodsDescription,
	JJ_VolumeUQ,
	JJ_Weight,
	JJ_WeightUQ,
	JJ_Volume,
	
	1																					AS One,

	--UtilityColumns
	CASE WHEN COALESCE(JobLegCount, 0) < 1 THEN 1 ELSE JobLegCount END					AS JobLegCountMin1,
	CASE
		WHEN COALESCE(JobChargeableLegCount,0) < 1 THEN 
			CASE WHEN COALESCE(JobLegCount, 0) < 1 THEN 1 ELSE JobLegCount END
		ELSE JobChargeableLegCount 
	END																					AS JobChargeableLegCountOrJobLegCount,
	CASE
		WHEN COALESCE(LegOnlyCharges.TotalRevAmount + LegOnlyCharges.TotalWIPAmount, 0) <> 0 THEN 'Y'
		ELSE 'N'
	END																					AS IsChargeable,
	CASE
		WHEN COALESCE(JobChargeableLegCount,0) <> 0 THEN 'Y'
		ELSE 'N'
	END																					AS JobHasChargeableLegs,
	--End

	COALESCE(AllJobCharges.TotalWIPAmount, 0)											AS JobWIP,
	COALESCE(AllJobCharges.TotalREVAmount, 0)											AS JobREV,
	COALESCE(AllJobCharges.TotalWIPAmount + AllJobCharges.TotalRevAmount, 0)			AS JobIncome,
		
	COALESCE(JobOnlyCharges.TotalWIPAmount, 0)											AS JobOnlyWIP,
	COALESCE(JobOnlyCharges.TotalRevAmount, 0)											AS JobOnlyREV,
	COALESCE(JobOnlyCharges.TotalRevAmount + JobOnlyCharges.TotalWIPAmount, 0)			AS JobOnlyIncome,

	COALESCE(LegOnlyCharges.TotalWIPAmount, 0)											AS LegOnlyWIP,
	COALESCE(LegOnlyCharges.TotalRevAmount, 0)											AS LegOnlyREV,
	COALESCE(LegOnlyCharges.TotalRevAmount + LegOnlyCharges.TotalWIPAmount,0)			AS LegOnlyIncome
FROM
	JobContainerLegs 
	
	JOIN JobBookedCtgMove 							ON JU_EW = EW_PK
	JOIN JobCartage 								ON JJ_PK = EW_JJ AND JJ_IsCancelled = 0
	
	LEFT JOIN JobContainer ContainerFile   			ON ContainerFile.JC_PK = JobBookedCtgMove.EW_JC_Container
	LEFT JOIN RefContainer 						ON RC_PK = JC_RC

	LEFT JOIN GlbBranch 							ON GB_PK = JJ_GB
	LEFT JOIN JobHeader 							ON JH_ParentID = JJ_PK AND JH_GC = @CurrentCompanyPK AND JH_IsActive = 1
	LEFT JOIN GlbDepartment 						ON GE_PK = JH_GE

	LEFT JOIN OrgAddress LocalClientAddress 		ON LocalClientAddress.OA_PK = JH_OA_LocalChargesAddr
	LEFT JOIN OrgHeader LocalClient 				ON LocalClient.OH_PK = LocalClientAddress.OA_OH
	
	LEFT JOIN JobCartageRunSheet 					ON EY_PK = JU_EY_RunSheet 
	LEFT JOIN RefEquipment Truck 					ON Truck.RQ_PK = EY_RQ_Truck
	LEFT JOIN GlbStaff Driver 						ON Driver.GS_Code = EY_GS_NKTruckDriver
	LEFT JOIN OrgHeader TransportCo 				ON TransportCo.OH_PK = EY_OH_TransportCo

	LEFT JOIN JobDocAddress PickupDocAddress 		ON PickupDocAddress.E2_PK = JU_E2PickupAddressID
	LEFT JOIN OrgAddress PickupOrgAddress 			ON PickupOrgAddress.OA_PK = PickupDocAddress.E2_OA_Address
	LEFT JOIN OrgHeader PickupOrgHeader 			ON PickupOrgHEader.OH_PK = PickupOrgAddress.OA_OH

	LEFT JOIN JobDocAddress WaitPointDocAddress 	ON WaitPointDocAddress.E2_PK = JU_E2WaitPointAddressID
	LEFT JOIN OrgAddress WaitPointOrgAddress 		ON WaitPointOrgAddress.OA_PK = WaitPointDocAddress.E2_OA_Address
	LEFT JOIN OrgHeader WaitPointOrgHeader 		ON WaitPointOrgHEader.OH_PK = WaitPointOrgAddress.OA_OH

	LEFT JOIN JobDocAddress DeliveryDocAddress 	ON DeliveryDocAddress.E2_PK = JU_E2DeliveryAddressID
	LEFT JOIN OrgAddress DeliveryOrgAddress 		ON DeliveryOrgAddress.OA_PK = DeliveryDocAddress.E2_OA_Address
	LEFT JOIN OrgHeader DeliveryOrgHeader 			ON DeliveryOrgHEader.OH_PK = DeliveryOrgAddress.OA_OH
	LEFT JOIN JobShipment Shipment 				ON Shipment.JS_PK = JobCartage.JJ_ParentID
	LEFT JOIN JobConsol Consol				ON Consol.JK_PK = ContainerFile.JC_JK
	LEFT JOIN dbo.csfn_MainConsolTransport(@CurrentCountry) AS MainConTrans ON MainConTrans.JW_JK = Consol.JK_PK 
	LEFT JOIN JobSailing Sailing				ON Sailing.JX_PK = JobCartage.JJ_JX_Sailing	


	LEFT JOIN 
	(
		SELECT 
			EW_JJ,
			Count(*)			AS JobContainerCount, 
			SUM(RC_TEU)			AS JobTEU
		FROM 
			JobBookedCtgMove  
			INNER JOIN JobContainer ON JC_PK = EW_JC_Container
			INNER JOIN RefContainer  ON RC_PK = JC_RC
		GROUP BY EW_JJ
	) JCLContainerCount ON JCLContainerCount.EW_JJ = JJ_PK	
	LEFT JOIN
	(
		SELECT
			EW_JJ,
			Count(*)			AS JobLegCount
		FROM 
			JobContainerLegs 
			JOIN JobBookedCtgMove  ON JU_EW = EW_PK
		GROUP BY EW_JJ
	) JCL ON JCL.EW_JJ = JJ_PK

	LEFT JOIN
	(
		SELECT 
			EW_JJ,
			Count(*)			AS JobChargeableLegCount 
		FROM 
			JobContainerLegs 
			JOIN JobBookedCtgMove  ON JU_EW = EW_PK
		WHERE JU_PK IN ( --AutoRating attaches a Leg to each Charge
				SELECT EC_Value
				FROM JobChargeAttrib 
				WHERE EC_Name = 'CLG')
		GROUP BY EW_JJ
	) JCL1 ON JCL1.EW_JJ = JJ_PK
	
	LEFT JOIN
	(
		SELECT 
			EW_JJ,
			Count(*)			AS JobLegCountByOwnVehicles
		FROM 
			JobContainerLegs  
			JOIN JobBookedCtgMove  ON JU_EW = EW_PK
			LEFT JOIN JobCartageRunSheet  ON JU_EY_RunSheet = EY_PK
		WHERE 
			EY_RQ_Truck IS NOT NULL 
		GROUP BY EW_JJ
	) JCL2 ON JCL2.EW_JJ = JJ_PK

	LEFT JOIN
	(
		SELECT
			EW_JJ,
			Count(*)			AS JobLegCountByTransportCo
		FROM 
			JobContainerLegs  
			JOIN JobBookedCtgMove  ON JU_EW = EW_PK
			LEFT JOIN JobCartageRunSheet  ON JU_EY_RunSheet = EY_PK
		WHERE 
			EY_OH_TransportCo IS NOT NULL 
		GROUP BY EW_JJ
	) JCL3 ON JCL3.EW_JJ = JJ_PK

	LEFT JOIN
	(
		SELECT 
			EW_JJ, 
			Count(*)			AS JobChargeableLegCountByOwnVehicles 
		FROM 
			JobContainerLegs  
			JOIN JobBookedCtgMove  ON JU_EW = EW_PK
			LEFT JOIN JobCartageRunSheet  ON JU_EY_RunSheet = EY_PK
		WHERE 
			EY_RQ_Truck IS NOT NULL 
			AND
			JU_PK IN ( --AutoRating attaches a Leg to each Charge
				SELECT EC_Value
				FROM JobChargeAttrib 
				WHERE EC_Name = 'CLG') 
		GROUP BY EW_JJ
	) JCL4 ON JCL4.EW_JJ = JJ_PK

	LEFT JOIN
	(
		SELECT 
			EW_JJ,
			Count(*)			AS JobChargeableLegCountByTransportCo
		FROM 
			JobContainerLegs  
			JOIN JobBookedCtgMove  ON JU_EW = EW_PK
			LEFT JOIN JobCartageRunSheet  ON JU_EY_RunSheet = EY_PK
		WHERE 
			EY_OH_TransportCo IS NOT NULL
			AND
			JU_PK IN ( --AutoRating attaches a Leg to each Charge
				SELECT EC_Value
				FROM JobChargeAttrib 
				WHERE EC_Name = 'CLG') 
		GROUP BY EW_JJ
	) JCL5 ON JCL5.EW_JJ = JJ_PK

	LEFT JOIN
	(
		SELECT
			AL_JH							AS ALJH,
			COALESCE(SUM(REVAmount),0)		AS TotalRevAmount,
			AL_GB							AS ALGB,
			COALESCE(SUM(WIPAmount),0)		AS TotalWIPAmount
		FROM
			vw_ClassifiedTransactionLineAmounts 
			JOIN JobCharge  ON JR_AL_ARLine = AL_PK --use JR_AL_APLine for Costs and Accurals
		GROUP BY AL_JH, AL_GB
	)
	AllJobCharges ON ALJH = JH_PK

	LEFT JOIN
	(
		SELECT
			EC_Value						AS LegPK,
			AL_JH							AS ALJH,
			COALESCE(SUM(REVAmount),0)		AS TotalRevAmount,
			AL_GB							AS ALGB,
			COALESCE(SUM(WIPAmount),0)		AS TotalWIPAmount
		FROM
			vw_ClassifiedTransactionLineAmounts 
			JOIN JobCharge  ON JR_AL_ARLine = AL_PK --use JR_AL_APLine for Costs and Accurals
			LEFT JOIN JobChargeAttrib  ON EC_Name = 'CLG' AND EC_JR = JR_PK --Include Job Level Charges
		GROUP BY AL_JH, AL_GB, EC_Value
	)
	LegOnlyCharges ON LegOnlyCharges.LegPK = JU_PK AND LegOnlyCharges.ALJH = JH_PK

	LEFT JOIN
	(
		SELECT
			EC_Value						AS LegPK,
			AL_JH							AS ALJH,
			COALESCE(SUM(REVAmount),0)		AS TotalRevAmount,
			AL_GB							AS ALGB,
			COALESCE(SUM(WIPAmount),0)		AS TotalWIPAmount
		FROM
			vw_ClassifiedTransactionLineAmounts 
			JOIN JobCharge  ON JR_AL_ARLine = AL_PK --use JR_AL_APLine for Costs and Accurals
			LEFT JOIN JobChargeAttrib  ON EC_Name = 'CLG' AND EC_JR = JR_PK --Include Job Level Charges
		GROUP BY AL_JH, AL_GB, EC_Value
	)
	JobOnlyCharges ON JobOnlyCharges.LegPK IS NULL AND JobOnlyCharges.ALJH = JH_PK

WHERE 
	(((@PickupTimeOutFrom = '' OR JU_PickupTimeOut >= @PickupTimeOutFrom) AND (@PickupTimeOutTo = '' OR JU_PickupTimeOut <= @PickupTimeOutTo)) AND
	((@DeliverTimeOutFrom = '' OR JU_DeliverTimeOut >= @DeliverTimeOutFrom) AND (@DeliverTimeOutTo = '' OR JU_DeliverTimeOut <= @DeliverTimeOutTo)) AND
	((@ETAFrom = '' OR MainConTrans.JW_ETA >= @ETAFrom) AND (@ETATo = '' OR MainConTrans.JW_ETA <= @ETATo)))
AND
	(@Vehicle IS NULL OR @Vehicle = EY_RQ_Truck)
AND 
	(@TransportCompany IS NULL OR @TransportCompany = EY_OH_TransportCo)
AND
	(@JobLocalClient IS NULL OR @JobLocalClient = LocalClient.OH_PK)
AND
	(@LocalCartageBranch IS NULL OR @LocalCartageBranch = GB_PK)
AND	
	(@DeliveryCompany IS NULL OR @DeliveryCompany = DeliveryOrgHeader.OH_PK)
) innerSelect
END