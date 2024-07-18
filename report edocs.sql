create function Report_GBDeclarationsLuciaDocuments(
	@CurrentCompany AS uniqueidentifier,
	@TransportMode AS char(3),
	@Origin AS varchar(5),
	@Destination AS varchar(5),
	@Loading AS varchar(5),
	@Arrival AS varchar(5),
	@CreateDateFrom AS smalldatetime,
	@CreateDateTo AS smalldatetime,
	@ImporterPk AS uniqueidentifier,
	@SupplierPk AS uniqueidentifier, 
	@BranchPk AS uniqueidentifier,
	@DepartureDateFrom AS smalldatetime,
	@DepartureDateTo AS smalldatetime,
	@ArrivalDateFrom AS smalldatetime,
	@ArrivalDateTo AS smalldatetime,
	@Route as varchar(3),
	@DeclarationType as varchar(3),
	@Badge as varchar(3),
	@Csp as varchar(5),
	@DeclarantType as varchar(3),
	@ApplicationCode as char(3),
	@MessageType as char(3) ='IMP',
	@CdsLocationOfGoods as varchar(15),
	@DocumentType as varchar(3)
)

	returns table --with schemabinding -- cannot have schema bindings, we want to use synonyms
	
	as

	return 

		select 
			JobDec.JE_PK,		-- passed through for Import report
			JobDec.JE_AddInfo , -- passed through for Import report
			JobDec.JobNumber,
			JobDec.CLREventTime as ClearanceDate,
			JobDec.CCCEventTime,  -- passed through for Import report
			JobDec.BilledAmount,
			JobDec.InvoicedAmount,
			JobDec.OutstandingAmount,
			JobDec.AllARInvoicesOutstandingAmount,
			JobDec.AllARInvoicesInvoicedAmount,

			JobDec.JE_GB,
			JobDec.JE_OH_Importer,
			JobDec.JE_OH_Supplier,

			JobDec.CreatedTime, 
			JobDec.PickupCode,
			JobDec.PickupName,
			JobDec.DeliveryCode,
			JobDec.DeliveryName,
			JobDec.DeliveryTransportCode, 
			JobDec.DeliveryTransportName, 
			JobDec.PickupTransportCode, 
			JobDec.PickupTransportName, 
			JobDec.DepotCode,
			JobDec.DepotName,
			JobDec.Forwarder, 
			JobDec.ForwarderName, 
			JobDec.Carrier , 
			JobDec.CarrierName , 
			JobDec.Containers,
			JobDec.MessageType,
			JobDec.ContainerMode,
			JobDec.ServiceLevelCode ,
			JobDec.ServiceLevelName ,
			JobDec.SupplierCode as Box2SupplierCode,
			JobDec.SupplierName as Box2SupplierName,
			JobDec.ImporterCode as Box8ImporterCode,
			JobDec.ImporterName as Box8ImporterName,
			JobDec.AllEntryNumbers, 
			JobDec.InternalStatusCode,
			JobDec.MasterBill,
			JobDec.JE_VesselName as Box21Vessel,
			JobDec.VoyageFlight,
			JobDec.PortOfLoading, 
			JobDec.DepartureDate,
			JobDec.PortofDischarge,
			JobDec.ArrivalDate,
			JobDec.HouseBill,
			JobDec.JE_RL_NKOrigin as Box15PortOfOrigin,
			JobDec.JE_DateAtOrigin as ETD,
			JobDec.JE_RL_NKFinalDestination as Box17PortOfDestination,
			JobDec.JE_DateAtFinalDestination ETA,
			JobDec.GoodsDescription,
			JobDec.JE_OwnerRef Box7DeclarantsReference,
			JobDec.JE_TotalNoOfPacks as Box6Packages,
			JobDec.TotalWeight, 
			JobDec.TotalWeightUQ, 
			JobDec.TotalVolume,
			JobDec.TotalVolumeUQ,
			JobDec.JE_ShipmentIncoTerm as Box20IncoTerm,
			JobDec.BranchCode,
			JobDec.BranchName,
			JobDec.CreatingUserCode,
			JobDec.BrokerUserCode,
			JobDec.CreatingUserName,
			JobDec.BrokerUserName,
			JobDec.MergeBy,
			JobDec.JE_IsPersonalEffects as IsTrainingEntry,
			JobDec.JE_PaymentMethod as Box48OtherDeferralType,
				
			CEI_Style  as Box1DeclarationType, 
			rtrim(JE_MessageSubType) + CEI_SubStyle as Box1EntryType,
			JE_TransportMode as  Box25TransportMode,
			CTStatusID.Value as CTStatusID,
			ICS.Value as ICS,
			SOE.Value as SOE,
			RouteOfEntry.Value as RouteOfEntry,
			IrcInventoryReturnCode.Value as IrcInventoryReturnCode,  -- passed through for Import report
			JE_TransportModeInland  as Box26MOT,
			JE_RN_NKTransportNationality  as Box21Nationality,
			MUCR.CE_EntryNum as MasterUCR,
			JobDec.JE_CustomsProfile  as Badge,
			gateway.Value as CSP,
			case when	CustomsWarehouseAddressSepcific.OH_Code is not null and CustomsWarehouseAddressSepcific.OK_CustomsRegNo is not null 
							then CustomsWarehouseAddressSepcific.OK_CustomsRegNo + ' ' + CustomsWarehouseAddressSepcific.OH_Code
				when	CustomsWarehouseGeneral.OK_CustomsRegNo is not null and CustomsWarehouseGeneral.OH_Code is not null 
							then CustomsWarehouseGeneral.OK_CustomsRegNo +  ' ' + CustomsWarehouseGeneral.OH_Code
				when	CustomsWarehouseAddressSepcific.OH_Code is not null and CustomsWarehouseAddressSepcific.OK_CustomsRegNo is null 
							then  CustomsWarehouseAddressSepcific.OH_Code
				when	CustomsWarehouseGeneral.OK_CustomsRegNo is null and CustomsWarehouseGeneral.OH_Code is not null 
							then CustomsWarehouseGeneral.OH_Code
			end as Box49Warehouse, 

			Box44SupervisingOffice.OH_Code as Box44SupervisingOffice, 
			LocationOfGoods  as Box30Location,
			ShedCode  as Box30Shed,
			ShedDescription as Box30ShedName,
			LCPInspect.ValueAsDateTime  LCPInspectionDate,
			LCPDepart.ValueAsDateTime  LCPDepartureDate,
			JE_EntryAuthorisationDate  TaxPoint,
			cast ( case RouteFRequested.Value  when 'Y' then 1 else 0 end as bit) as RouteFRequested,
			
			ShipmentTYpe.Value  as BasicOrHouse,
			JobDec.JE_DeclarantType as Box14RepresentationType,
			(select OH_Code from dbo.OrgHeader  inner join dbo.OrgAddress  on OH_PK = OA_OH where OA_PK = JobDec.JE_OA_DeclarantAddress ) as Box14Declarant,
			TransportChargesMethodOfPayment.Value  as Box29TransportChargesMOP,
			JobDec.JE_CustomsOffice  as OfficeOfExit, 
			JobDec.JE_DefermentAccountNumber as Box48OtherDeferralAccount, 
			JobDec.JE_IATALoadPort as Box61FARP,
			JobDec.JE_ApplicationCode,
			SUBSTRING(JE_LocationOtherInformation, 7, 15) as CdsLocationOfGoods,

			documentsdatabase.sm_DB,
			documentsdatabase.sc_dataType,
			documentsdatabase.sc_DocType, 
			documentsdatabase.sc_FileName, 
			documentsdatabase.SM_ParentFK,
			documentsdatabase.SC_SystemCreateUser,
			documentsdatabase.SC_SystemCreateTimeUtc

from dbo.Report_CommonDeclarations(@CurrentCompany,
	@MessageType,
	@TransportMode,
	@Origin ,
	@Destination ,
	@Loading,
	@Arrival,
	@CreateDateFrom ,
	@CreateDateTo ,
	@ImporterPk ,
	@SupplierPk,
	@BranchPk,
	@DepartureDateFrom ,
	@DepartureDateTo,
	@ArrivalDateFrom,
	@ArrivalDateTo	
	 )
	
	as JobDec
 
	left join dbo.CusEntryNum MUCR   on MUCR.CE_ParentId = JobDec.JE_PK  and MUCR.CE_EntryType = 'MUC'
	
	-- Get Box 49 warehouse in two different ways
	left outer join 
	(
			select   OK_CustomsRegNo, JE_PK as declarationPK , OH_Code
				  from dbo.JobDeclaration   
					inner join dbo.JobDocAddress  on JE_PK = E2_ParentID and e2_addressType = 'CWA'
					inner join dbo.OrgAddress  on E2_OA_Address = OA_PK
					inner join dbo.OrgHeader  on  OA_OH = OH_PK
					left outer join dbo.OrgCusCode  on  (OK_OH = OH_PK  and OK_CodeType = 'CCP'  
													AND
													(
														OK_OA_PremisesAddress is null -- this part varies 
													)
												)	
	) CustomsWarehouseGeneral on CustomsWarehouseGeneral.declarationPK = JobDec.JE_PK
	
	left outer join 
	(
			select   OK_CustomsRegNo, JE_PK as declarationPK , OH_Code
				  from dbo.JobDeclaration  
					inner join dbo.JobDocAddress  on JE_PK = E2_ParentID and e2_addressType = 'CWA'
					inner join dbo.OrgAddress  on E2_OA_Address = OA_PK
					inner join dbo.OrgHeader  on  OA_OH = OH_PK
					left outer  join dbo.OrgCusCode  on  (OK_OH = OH_PK  and OK_CodeType = 'CCP'  
													AND
													( 
														OK_OA_PremisesAddress = OA_PK -- this part varies 
													)
												)	
	) CustomsWarehouseAddressSepcific on CustomsWarehouseAddressSepcific.declarationPK = JobDec.JE_PK
	-- End box 49

	
	-- Join to JDA for supervising office SPOFF
	left outer join 
	(
		select OH_Code , E2_ParentID
			 from dbo.OrgHeader  inner join dbo.OrgAddress  on OH_PK = OA_OH 
						inner join dbo.JobDocAddress  on OA_PK = E2_OA_Address
						where  e2_addressType = 'SOF' 
	)   Box44SupervisingOffice  on Box44SupervisingOffice.E2_ParentID = jobDec.je_pk
	-- end SPOFF
		  
	left join
	(
		select JE_PK as JEPK, LTRIM(left(je_locationofgoods, 5)) as LocationOfGoods, 
				LTRIM(SUBSTRING(JE_SubLocationofgoods+'   ', 4,3)) as ShedCode, 
				JE_LocationOtherInformation,
				(
					SELECT TOP 1 ZZD_Description FROM dbo.ZZRefCusCodeListCombined 
					WHERE ZZD_CountryOrGrouping='GB' and ZZD_CodeType='FAC'
						AND LTRIM(JE_SubLocationofGoods) = ZZD_Code AND GETDATE() BETWEEN ZZD_StartDate AND ZZD_EndDate
				) as ShedDescription
				from dbo.JobDeclaration
	) jeInnerForBox30 on jeInnerForBox30.JEPK = JE_PK

	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(jobDec.JE_AddInfo, 'gateway') as gateway
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(jobDec.JE_AddInfo, 'CTStatusID') as CTStatusID 
	cross apply dbo.csfn_GetAddInfoValueFromCodeInlineAsDateTime(jobDec.JE_AddInfo, 'LCPDepart') as LCPDepart 
	cross apply dbo.csfn_GetAddInfoValueFromCodeInlineAsDateTime(jobDec.JE_AddInfo, 'LCPInspect') as LCPInspect 
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(jobDec.JE_AddInfo, 'RouteFrequested') as RouteFrequested 
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(jobDec.JE_AddInfo, 'ShipmentType') as ShipmentType

	left join dbo.CusEntryHeader on CH_JE = JobDec.JE_PK
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(CH_AddInfo, 'ImportClearanceStatusICS') as ICS
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(CH_AddInfo, 'StyleOfEntrySOE') as SOE
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(CH_AddInfo, 'RouteOfEntry') as RouteOfEntry
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(CH_AddInfo, 'IrcInventoryReturnCode') as IrcInventoryReturnCode

	left join dbo.CusEntryInstruction on CEI_JE = JE_PK
	left join
	(
		select JI_CEI, InvHeaderPk = max(JI_JZ)
		FROM dbo.JobComInvoiceLine
		where JI_CEI is not null
		GROUP BY JI_CEI
	) randomInvHeaderLinkForInstruction on JI_CEI = CEI_PK
	left join dbo.JobComInvoiceHeader randomInvHeaderForInstruction on JZ_PK = RandomInvHeaderLinkForInstruction.InvHeaderPk
	cross apply dbo.csfn_GetAddInfoValueFromCodeInline(randomInvHeaderForInstruction.JZ_AddInfo, 'TransportChargesMethodOfPayment') as TransportChargesMethodOfPayment
	 join
	(SELECT 
	sm_DB  as SM_DB,
	sc_dataType, 
	sc_DocType, 
	sc_FileName, 
	SM_ParentFK,
	SC_SystemCreateUser,
	SC_SystemCreateTimeUtc
	FROM StorageMain
	inner join JobDeclaration on sm_ParentFK = JE_PK
	inner join odysseyMEFTRN_SD001.dbo.StorageDocs on sc_SM = sm_PK
	GROUP BY 
            SM_DB , 
            sc_dataType, 
            sc_DocType, 
            sc_FileName, 
            SM_ParentFK,
			SC_SystemCreateUser,
			SC_SystemCreateTimeUtc
	) documentsdatabase on documentsdatabase.SM_ParentFK = JobDec.JE_PK

	where (@Route is null or @Route = '' or RouteOfEntry.Value = @Route)
	and   (@DeclarationType is null or @DeclarationType  = '' or @DeclarationType=CEI_Style)
	and   (@Badge is null or @Badge  = '' or @Badge=JobDec.JE_CustomsProfile) 
	and   (@Csp is null or @Csp  = '' or @Csp=gateway.Value) 
	and   (@DeclarantType is null or @DeclarantType  = '' or @DeclarantType= JobDec.JE_DeclarantType)
	and   (@ApplicationCode is null or @ApplicationCode = '' or @ApplicationCode = JobDec.JE_ApplicationCode)
	and   (@CdsLocationOfGoods is null or @CdsLocationOfGoods = '' or JE_LocationOtherInformation LIKE '%' + @CdsLocationOfGoods)
	and   (@DocumentType =documentsdatabase.sc_DocType)


