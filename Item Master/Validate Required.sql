PROCEDURE VALIDATE_REQUIRED IS 

    /*************************************************************************************************
     * Program Name : VALIDATE_REQUIRED
     * Language     : PL/SQL
     * Description  : VALIDATE MENDATORY FIELDS.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          20-May-2025     Initial Version
     ***************************************************************************************************/
	 
BEGIN

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'TRANSACTION_TYPE CAN NOT BE NULL'
WHERE TRANSACTION_TYPE  IS NULL 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'INVALID TRANSACTION_TYPE'
WHERE TRANSACTION_TYPE NOT IN ('CREATE','UPDATE') 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'SEGMENT1 CAN NOT BE NULL'
WHERE SEGMENT1 IS NULL 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'SEGMENT1 ALREADY EXISTS IN STGAING'
WHERE EXISTS
(SELECT 1 FROM 
 xxqgen_item_stg_ar STG
 WHERE UPPER(STG.SEGMENT1) = UPPER(SEGMENT1))
 AND REQUEST_ID = gn_request_id ;
 
UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'SEGMENT1 ALREADY EXISTS IN SYSTEM'
WHERE EXISTS
(SELECT 1 FROM 
 MTL_SYSTEM_ITEMS_B MSIB
 WHERE UPPER(MSIB.SEGMENT1) = UPPER(SEGMENT1) )
 AND REQUEST_ID = gn_request_id ;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'DESCRIPTION CAN NOT BE NULL'
WHERE DESCRIPTION  IS NULL 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'ORGANIZATION_NAME CAN NOT BE NULL'
WHERE ORGANIZATION_NAME IS NULL 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'TEMPLATE_NAME CAN NOT BE NULL'
WHERE TEMPLATE_NAME  IS NULL 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'INVALID TEMPLATE TYPE'
WHERE APPLY_TEMPLATE NOT IN ('ALL', 'NOT NULL', 'NULL') 
AND REQUEST_ID = gn_request_id;

UPDATE xxqgen_item_stg_ar
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'INVALID APPROVAL_STATUS'
WHERE APPROVAL_STATUS NOT IN ('A', 'S', 'D', 'R')
AND REQUEST_ID = gn_request_id;

EXCEPTION WHEN OTHERS 
THEN 
fnd_file.put_line (fnd_file.LOG,'ERROR IN VALIDATE REQUIRED '||SQLCODE||' '||SQLERRM ) ;
			
END VALIDATE_REQUIRED;