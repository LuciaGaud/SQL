KM_PK IN (SELECT KM_PK FROM 
((DtbBooking JOIN DtbBookingConsolidation ON DtbBooking.KM_KB_Booking = DtbBookingConsolidation.KB_PK) JOIN JobHeader ON JobHeader.JH_ParentID = DtbBookingConsolidation.KB_ParentID) 
WHERE JobHeader.JH_GS_NKRepOps LIKE '%JOF%')