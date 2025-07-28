CREATE OR REPLACE PACKAGE BODY XXQGEN_REQ_DATA_LOAD_PKG_AR
AS

    /*************************************************************************************************
     *                 Copy Rights Reserved Â© QGEN- 2024
     *
     * $Header: @(#)
     * Program Name : XXQGEN_REQ_DATA_LOAD_PKG_AR.pkb
     * Language     : PL/SQL
     * Description  : IMPORT REQUISITION
     * History      :
     *
     * WHO                Version #    WHEN             WHAT
     * ===============    =========    =============    ==================================================
     * ANKESH RANA        1.1         23-FEB-2025      Initial Version
     ***************************************************************************************************/
     
    /*************************************************************************************************
     * Program Name : SUBMIT_REPORT
     * Language     : PL/SQL
     * Description  : SUBMIT REPORT FOR PROCESSED DATA.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.1        23-FEB-2025     Initial Version
     ***************************************************************************************************/


PROCEDURE SUBMIT_REPORT
   AS
      lc_approval_status   VARCHAR2 (100) := 'INCOMPLETE';
      ln_request          NUMBER;
      ln_interval         NUMBER := 5;
      ln_max_wait         NUMBER := 60;
      lc_phase            VARCHAR2 (3000);
      lc_status           VARCHAR2 (3000);
      lc_dev_phase        VARCHAR2 (3000);
      lc_dev_status       VARCHAR2 (3000);
      lc_message          VARCHAR2 (3000);
      lc_conc_status      BOOLEAN;
      l_layout            BOOLEAN;

      
      BEGIN
      fnd_global.apps_initialize (gn_user_id, gn_resp_id, gn_resp_appl_id);
      
      mo_global.init ('PO');
      
      fnd_request.set_org_id (gn_org_id);
      
        l_layout := apps.fnd_request.add_layout(
                            template_appl_name => 'PO',
                            template_code      => 'XXQGEN_REQ_IMPT_RPT_AR',
                            template_language  => 'en',
                            template_territory => 'US',
                            output_format      => 'EXCEL');

      
      ln_request :=
         fnd_request.submit_request (application   => 'PO',
                                     program       => 'XXQGEN_REQ_IMPT_RPT_AR',
                                     argument1     => gn_request_id
                                     );
                                     
      COMMIT;
      
      fnd_file.put_line (   fnd_file.LOG,'REQUEST TO PRINT REPORT .' || gn_request_id);


   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
               'ERROR IN SUBMIT_REPORT : '
            || SQLCODE
            || '-'
            || SQLERRM);
   END SUBMIT_REPORT;


    /*************************************************************************************************
     * Program Name : UPDATE_STATUS
     * Language     : PL/SQL
     * Description  : UPDATE STATUS OF PROCESSED DATA.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/

PROCEDURE UPDATE_STATUS IS


CURSOR CUR_DATA IS 

SELECT PRHA.SEGMENT1 
, PRHA.REQUISITION_HEADER_ID
 , PRHA.ATTRIBUTE7 
 , PRHA.ATTRIBUTE8 
 , PRLA.REQUISITION_LINE_ID
  ,PRLA.ATTRIBUTE7 LINE7
  , PRLA.ATTRIBUTE8  LINE8
  ,  PRDA.DISTRIBUTION_ID
FROM PO_REQUISITION_HEADERS_ALL PRHA
, PO_REQUISITION_LINES_ALL PRLA
, PO_REQ_DISTRIBUTIONS_ALL PRDA
WHERE 1=1
AND PRHA.REQUISITION_HEADER_ID = PRLA.REQUISITION_HEADER_ID
AND PRLA.REQUISITION_LINE_ID = PRDA.REQUISITION_LINE_ID
AND PRHA.ATTRIBUTE7 = gn_request_id ;

BEGIN

FOR REC IN CUR_DATA LOOP

UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
SET PROCESS_FLAG = 'P'
, SEGMENT1 = REC.SEGMENT1
, REQUISITION_HEADER_ID  = REC.REQUISITION_HEADER_ID
WHERE RECORD_ID = REC.ATTRIBUTE8
AND REQUEST_ID = REC.ATTRIBUTE7 ;

UPDATE XXQGEN_PO_REQ_LINES_STG_AR
SET PROCESS_FLAG = 'P'
, REQUISITION_LINE_ID  = REC.REQUISITION_LINE_ID
, DISTRIBUTION_ID = REC.DISTRIBUTION_ID
WHERE RECORD_ID = REC.LINE8
AND  REQUEST_ID = REC.LINE7 ;

END LOOP ;
EXCEPTION
WHEN OTHERS THEN
fnd_file.put_line(fnd_file.log,'ERROR IN UPDATE_STATUS'||SQLCODE||' '||SQLERRM);
END UPDATE_STATUS;


    /*************************************************************************************************
     * Program Name : SUBMIT_REQUISITION
     * Language     : PL/SQL
     * Description  : SUBMIT REQUISITION IMPORT PROGRAM.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/


PROCEDURE SUBMIT_REQUISITION 
   AS
      lc_approval_status   VARCHAR2 (100) := 'INCOMPLETE';
      ln_request          NUMBER;
      ln_interval         NUMBER := 5;
      ln_max_wait         NUMBER := 60;
      lc_phase            VARCHAR2 (3000);
      lc_status           VARCHAR2 (3000);
      lc_dev_phase        VARCHAR2 (3000);
      lc_dev_status       VARCHAR2 (3000);
      lc_message          VARCHAR2 (3000);
      lc_conc_status      BOOLEAN;
      
      BEGIN
      fnd_global.apps_initialize (gn_user_id, gn_resp_id, gn_resp_appl_id);
      
      mo_global.init ('PO');
      
      fnd_request.set_org_id (gn_org_id);
      
      ln_request :=
         fnd_request.submit_request (application   => 'PO',
                                     program       => 'REQIMPORT',
                                     argument1     => '',
                                     argument2     => gn_request_id,
                                     argument3     => 'ALL',
                                     argument4     => NULL,
                                     argument5     => 'N',
                                     argument6     => 'N');
                                     
      COMMIT;
      
      fnd_file.put_line (   fnd_file.LOG,'UPLOAD REQUISITION DATA START.' || gn_request_id);

      IF ln_request = 0
      THEN
         fnd_file.put_line ( fnd_file.LOG, 'UPLOAD REQUISITION DATA NOT SUBMITTED.'|| gn_request_id);
      ELSIF ln_request > 0
      THEN
         --  gn_submit_request_id := ln_request;
         LOOP
            lc_conc_status :=
               fnd_concurrent.wait_for_request (request_id   => ln_request,
                                                INTERVAL     => ln_interval,
                                                max_wait     => ln_max_wait,
                                                phase        => lc_phase,
                                                status       => lc_status,
                                                dev_phase    => lc_dev_phase,
                                                dev_status   => lc_dev_status,
                                                MESSAGE      => lc_message);
                                                
            EXIT WHEN UPPER (lc_phase) = 'COMPLETED' OR UPPER (lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
      
         END LOOP;
      
      END IF;

      fnd_file.put_line (fnd_file.LOG,
                         'UPLOAD REQUISITION DATA COMPLETED');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
               'ERROR IN  REQUISITION  SUBMIT PROCESS : '
            || SQLCODE
            || '-'
            || SQLERRM);

   END submit_requisition;


    /*************************************************************************************************
     * Program Name : INTERFACE_DATA
     * Language     : PL/SQL
     * Description  : INSERT VALID DATA INTO INTERFACE TABLE.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/


PROCEDURE INTERFACE_DATA 
IS 

      CURSOR CUR_PROCESS
      IS
      
        SELECT HDR.RECORD_ID,
       HDR.REQUEST_ID,
       HDR.CREATED_BY,
       HDR.CREATION_DATE,
       HDR.LAST_UPDATED_BY,
       HDR.PROCESS_FLAG,
       HDR.REQUISITION_HEADER_ID,
       HDR.REQUISITION_NUMBER,
       HDR.PREPARER_ID,
       HDR.ORG_ID,
       HDR.AUTHORIZATION_STATUS,
       HDR.DESCRIPTION,
       HDR.REQUISITION_TYPE,
       LINE.RECORD_ID LINE_RECORD_ID,
       LINE.REQUISITION_LINE_ID,
       LINE.LINE_NUM,
       LINE.LINE_TYPE_ID,
       LINE.ITEM_ID,
       LINE.ITEM_DESCRIPTION,
       LINE.CATEGORY_ID,
       LINE.UOM,
       LINE.QUANTITY,
       LINE.UNIT_PRICE,
       LINE.TO_PERSON_ID,
       LINE.NEED_BY_DATE,
       LINE.ORGANIZATION_ID,
       LINE.LOCATION_ID,
       LINE.VENDOR_ID,
       LINE.SUPPLIER,
       LINE.VENDOR_SITE_ID,
       LINE.CONTACT,
       LINE.DESTINATION_TYPE,
       LINE.SOURCE,
       LINE.DISTRIBUTION_ID,
       LINE.CODE_COMBINATION_ID,
       LINE.CHARGE_ACCOUNT

  FROM XXQGEN_PO_REQ_HEADERS_STG_AR hdr, XXQGEN_PO_REQ_LINES_STG_AR line
 WHERE     1 = 1
       AND hdr.requisition_number = line.requisition_number
       AND hdr.process_flag = 'V'
       AND line.process_flag = 'V' 
       AND HDR.REQUEST_ID  = gn_request_id ;
       
      TYPE process_data_type IS TABLE OF CUR_PROCESS%ROWTYPE
                                    INDEX BY PLS_INTEGER;

      process_tbl   process_data_type;
      
      BEGIN 
       
      OPEN CUR_PROCESS;

      LOOP
         FETCH CUR_PROCESS
         BULK COLLECT INTO process_tbl
         LIMIT gn_limit;

         FOR i IN 1 .. process_tbl.COUNT loop
         BEGIN

        INSERT INTO po_requisitions_interface_all (
                                           TRANSACTION_ID,
                                           BATCH_ID,
                                           INTERFACE_SOURCE_CODE,
                                           CREATION_DATE,
                                           CREATED_BY,
                                           SOURCE_TYPE_CODE,
                                           REQUISITION_HEADER_ID,
                                           REQUISITION_LINE_ID,
                                           REQ_DISTRIBUTION_ID,
                                           REQUISITION_TYPE,
                                           DESTINATION_TYPE_CODE, 
                                           ITEM_DESCRIPTION,
                                           QUANTITY,
                                           UNIT_PRICE,
                                           AUTHORIZATION_STATUS,
                                           PREPARER_ID,
                                           HEADER_DESCRIPTION,
                                           ITEM_ID,
                                           CHARGE_ACCOUNT_ID,
                                           CATEGORY_ID,
                                           UNIT_OF_MEASURE,
                                           LINE_TYPE_ID,
                                           DESTINATION_ORGANIZATION_ID,
                                           DELIVER_TO_LOCATION_ID,
                                           DELIVER_TO_REQUESTOR_ID,
                                           SUGGESTED_VENDOR_ID,
                                           SUGGESTED_VENDOR_SITE_ID,
                                           SUGGESTED_VENDOR_CONTACT,
                                           NEED_BY_DATE,
                                           ORG_ID,
                                           REQ_DIST_SEQUENCE_ID,
                                           HEADER_ATTRIBUTE7,
                                           LINE_ATTRIBUTE7,
                                           HEADER_ATTRIBUTE8,
                                           LINE_ATTRIBUTE8
)
     VALUES (
            po_headers_interface_s.NEXTVAL ,
             gn_request_id ,
              'IMPORT_REQ' ,
             sysdate,
             GN_USER_ID,
             process_tbl (i).SOURCE,
             process_tbl (i).REQUISITION_HEADER_ID,
             process_tbl (i).REQUISITION_LINE_ID,
             process_tbl (i).distribution_id,
             process_tbl (i).REQUISITION_TYPE,
             process_tbl (i).DESTINATION_TYPE,
             process_tbl (i).ITEM_DESCRIPTION,
             process_tbl (i).QUANTITY,
             process_tbl (i).UNIT_PRICE,
             process_tbl (i).AUTHORIZATION_STATUS,
             process_tbl (i).PREPARER_ID,
             process_tbl (i).DESCRIPTION,
             process_tbl (i).ITEM_ID,
             process_tbl (i).CODE_COMBINATION_ID, 
             process_tbl (i).CATEGORY_ID,
             process_tbl (i).UOM,
             process_tbl (i).LINE_TYPE_ID,
             process_tbl (i).ORGANIZATION_ID,
             process_tbl (i).LOCATION_ID,
             process_tbl (i).to_person_id,
             process_tbl (i).VENDOR_ID,
             process_tbl (i).VENDOR_SITE_ID,
             process_tbl (i).CONTACT,
             process_tbl (i).NEED_BY_DATE,
             process_tbl (i).ORG_ID,
             po_req_dist_interface_s.NEXTVAL,
             process_tbl (i).REQUEST_ID,
             process_tbl (i).REQUEST_ID,
             process_tbl (i).RECORD_ID,
             process_tbl (i).LINE_RECORD_ID
            );
            
        EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line (fnd_file.LOG,'ERROR IN PROCESS_DATA : ' || SQLCODE || ',' || SQLERRM);        
        END ;
        end loop ;
                 
                 EXIT WHEN process_tbl.COUNT = 0;
       
       END LOOP;
        
        COMMIT ;
        CLOSE  CUR_PROCESS ;

        
        EXCEPTION WHEN OTHERS 
        THEN
         fnd_file.put_line (
            fnd_file.LOG,
            'ERROR IN REQ INTERFACE : ' || SQLCODE || ',' || SQLERRM);
      END INTERFACE_DATA;
      
      
    /*************************************************************************************************
     * Program Name : VALIDATE_DATA
     * Language     : PL/SQL
     * Description  : VALIDATE DATA INTO STAGING TABLE.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/
      
            

   PROCEDURE VALIDATE_DATA
   IS
      ---- CURSOR 1---
      
      CURSOR CUR_REQ_HDR
      IS
         SELECT *
           FROM XXQGEN_PO_REQ_HEADERS_STG_AR
          WHERE PROCESS_FLAG = 'N' 
          AND REQUEST_ID = gn_request_id ;

      TYPE REQ_HDR_data_type IS TABLE OF CUR_REQ_HDR%ROWTYPE
                                   INDEX BY PLS_INTEGER;

      REQ_HDR_tbl    REQ_HDR_data_type;
      
      

      ----CURSOR 2---
      
      CURSOR CUR_REQ_LINE( P_SEGMENT1 VARCHAR2)
      IS
         SELECT *
           FROM XXQGEN_PO_REQ_LINES_STG_AR
          WHERE PROCESS_FLAG = 'N'
          AND REQUEST_ID = gn_request_id
          AND REQUISITION_NUMBER = P_SEGMENT1 ;

      TYPE REQ_LINE_data_type IS TABLE OF CUR_REQ_LINE%ROWTYPE
                                    INDEX BY PLS_INTEGER;

      REQ_LINE_tbl   REQ_LINE_data_type;
  


    --ln_error_count NUMBER := 0;
   
    --ln_total_lines NUMBER := 0;

-- OPEN HEADER LEVEL CURSOR --

 BEGIN

 
      OPEN CUR_REQ_HDR;

      LOOP
         FETCH CUR_REQ_HDR
         BULK COLLECT INTO REQ_HDR_tbl
         LIMIT gn_limit;

         EXIT WHEN REQ_HDR_tbl.COUNT = 0;

         FOR i IN 1 .. REQ_HDR_tbl.COUNT
         LOOP
            REQ_HDR_tbl (i).PROCESS_FLAG := 'V';
            REQ_HDR_tbl (i).ERROR_MESSAGE := NULL;

            --- OPERATING UNIT ---
            
               BEGIN
                  SELECT ORGANIZATION_ID
                    INTO REQ_HDR_tbl (i).ORG_ID
                    FROM HR_OPERATING_UNITS
                   WHERE UPPER (NAME) =
                            UPPER (REQ_HDR_tbl (i).OPERATING_UNIT);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
                     REQ_HDR_tbl (i).ERROR_MESSAGE :=
                        'ERROR IN FETCHING ORG ID';
               END;
 

            --- PREPARER ---
            
               BEGIN
                  SELECT PERSON_ID
                    INTO REQ_HDR_tbl (i).PREPARER_ID
                    FROM PER_ALL_PEOPLE_F
                   WHERE UPPER (FULL_NAME) = UPPER (REQ_HDR_tbl (i).PREPARER)
                         AND SYSDATE BETWEEN EFFECTIVE_START_DATE
                                         AND EFFECTIVE_END_DATE
                         AND (CURRENT_EMPLOYEE_FLAG = 'Y'
                              OR CURRENT_NPW_FLAG = 'Y');
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
                     REQ_HDR_tbl (i).ERROR_MESSAGE :=
                        'ERROR IN FETCHING PREPARER';
               END;

            --- REQUISITION_TYPE ---

            ln_count NUMBER := 0 ;
            
			BEGIN
                  SELECT COUNT (*)
                    INTO ln_count
                    FROM PO_DOCUMENT_TYPES_ALL_VL
                   WHERE 1 = 1
                         AND LOWER (DOCUMENT_SUBTYPE) =
                                LOWER (REQ_HDR_tbl (i).requisition_type)
                         AND DOCUMENT_TYPE_CODE = 'REQUISITION'
                         AND ORG_ID = gn_org_id;

                  IF ln_count = 0
                  THEN
                     REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
                     REQ_HDR_tbl (i).ERROR_MESSAGE :=
                        REQ_HDR_tbl (i).ERROR_MESSAGE
                        || 'INVALID REQUISITION TYPE - ';
                  END IF;
               END;
            
            
             --VALIDATE  REQ STATUS
             
            ln_count NUMBER := 0 ;

            BEGIN
                SELECT COUNT (*)
                INTO ln_count
                FROM PO_LOOKUP_CODES
                WHERE 1 = 1
                AND LOWER (LOOKUP_CODE) =
                LOWER (REQ_HDR_tbl (i).AUTHORIZATION_STATUS)
                AND enabled_flag = 'Y'
                AND LOOKUP_TYPE = 'AUTHORIZATION STATUS';

                  IF ln_count = 0
                  THEN
                  REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
                  REQ_HDR_tbl (i).ERROR_MESSAGE :=
                  REQ_HDR_tbl (i).ERROR_MESSAGE || 'INVALID STATUS - ';
                  END IF;
            END;
            
    /*        
        -- If header has an error then all lines mark as an error --
            
        IF REQ_HDR_tbl(i).PROCESS_FLAG = 'E' THEN
        UPDATE XXQGEN_PO_REQ_LINES_STG_AR
        SET PROCESS_FLAG = 'E',
        ERROR_MESSAGE = 'HEADER ERROR: ' || REQ_HDR_tbl(i).ERROR_MESSAGE
        WHERE REQUISITION_NUMBER = REQ_HDR_tbl(i).REQUISITION_NUMBER;
        END IF;
	*/
    
	--- OPEN LINE LEVEL CURSOR ---
      
      OPEN CUR_REQ_LINE (REQ_HDR_tbl (i).REQUISITION_NUMBER);


        LOOP
         FETCH CUR_REQ_LINE
         BULK COLLECT INTO REQ_LINE_tbl
         LIMIT gn_limit;

         EXIT WHEN REQ_LINE_tbl.COUNT = 0;

    FOR i IN 1 .. REQ_LINE_tbl.COUNT
    LOOP
	BEGIN
            REQ_LINE_tbl (i).PROCESS_FLAG := 'V';
            REQ_LINE_tbl (i).ERROR_MESSAGE := NULL;
                    

         
        --- VALIDATE CATEGORY ---
            
        BEGIN
            SELECT CATEGORY_ID
            INTO REQ_LINE_tbl (i).CATEGORY_ID
            FROM MTL_CATEGORIES
            WHERE UPPER(REQ_LINE_tbl (i).CATEGORY) =UPPER(SEGMENT1 || '.' || SEGMENT2)
            AND ENABLED_FLAG ='Y' AND WEB_STATUS ='Y';
            EXCEPTION
            WHEN OTHERS
            THEN
            REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
            REQ_LINE_tbl (i).ERROR_MESSAGE := REQ_LINE_tbl (i).ERROR_MESSAGE||'-'||'ERROR IN FETCHING CATEGORY';
        END;     
               

        --- VALIDATE REQUESTER ---
        
        BEGIN
			SELECT PERSON_ID INTO REQ_LINE_tbl(i).TO_PERSON_ID
			FROM PER_ALL_PEOPLE_F
			WHERE UPPER(FULL_NAME) = UPPER(REQ_LINE_tbl(i).REQUESTER)
			AND SYSDATE BETWEEN EFFECTIVE_START_DATE AND EFFECTIVE_END_DATE
			AND (CURRENT_EMPLOYEE_FLAG = 'Y' OR CURRENT_NPW_FLAG = 'Y');
        
			EXCEPTION 
			WHEN OTHERS THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING REQUESTER' ;
        END ;
        
        
        --- VALIDATE LINE TYPE ---
        

        BEGIN
			SELECT LINE_TYPE_ID INTO REQ_LINE_tbl(i).LINE_TYPE_ID
			FROM PO_LINE_TYPES
			WHERE UPPER(LINE_TYPE) = UPPER(REQ_LINE_tbl(i).LINE_TYPE) ;
                
			EXCEPTION 
			WHEN OTHERS THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING LINE TYPE' ;
        END ;
        

        
    --- ORGANIZATION ---
        
	BEGIN
        BEGIN
			BEGIN
			SELECT ORGANIZATION_ID INTO REQ_LINE_tbl(i).ORGANIZATION_ID
			FROM ORG_ORGANIZATION_DEFINITIONS 
			WHERE UPPER(ORGANIZATION_NAME) = UPPER(REQ_LINE_tbl(i).ORGANIZATION) ;
			EXCEPTION 
			WHEN OTHERS THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'INVALID ORGANIZATION' ;
			END ;
		
	--- VALIDATE ITEM ---
         
		SELECT INVENTORY_ITEM_ID
		INTO REQ_LINE_tbl (i).ITEM_ID
		FROM MTL_SYSTEM_ITEMS_B MSIB
		WHERE UPPER (MSIB.SEGMENT1) = UPPER (REQ_LINE_tbl (i).ITEM_NUMBER) 
		EXCEPTION
		WHEN OTHERS
		THEN
		REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
		REQ_LINE_tbl (i).ERROR_MESSAGE := REQ_LINE_tbl (i).ERROR_MESSAGE ||'-'||'INVALID ITEM';
		END;
		 
	--- VALIDATE ITEM FOR PARTICULAR ORGANIZATION ---
	 
		SELECT INVENTORY_ITEM_ID
		INTO REQ_LINE_tbl (i).ITEM_ID
		FROM MTL_SYSTEM_ITEMS_B MSIB
		WHERE UPPER (REQ_LINE_tbl (i).ITEM_NUMBER) =UPPER (MSIB.SEGMENT1)
		AND MSIB.ORGANIZATION_ID  = REQ_LINE_tbl (i).ORGANIZATION_ID;
		EXCEPTION
		WHEN OTHERS
		THEN
		REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
		REQ_LINE_tbl (i).ERROR_MESSAGE := REQ_LINE_tbl (i).ERROR_MESSAGE ||'-'||'INVALID ITEM FOR THIS ORGANIZATION';
    END;
        
        
        --- VALIDATE LOCATION ---
      
        BEGIN
			SELECT LOCATION_ID INTO REQ_LINE_tbl(i).LOCATION_ID
			FROM HR_LOCATIONS 
			WHERE UPPER(LOCATION_CODE) = UPPER(REQ_LINE_tbl(i).LOCATION) ;
        
			EXCEPTION 
			WHEN OTHERS THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING LOCATION' ;
        END ;
                      
                    
                    
        --VALIDATION DESTINATION TYPE
		
		 ln_count NUMBER := 0 ;

     
		BEGIN
			SELECT COUNT (*)
            INTO ln_count
            FROM po_lookup_codes
			WHERE LOWER (LOOKUP_CODE) =
			LOWER (REQ_LINE_tbl (i).DESTINATION_TYPE)
			AND enabled_flag = 'Y'
			AND LOOKUP_TYPE = 'DESTINATION TYPE';
			
			IF ln_count = 0
            THEN
            REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
            REQ_LINE_tbl (i).ERROR_MESSAGE :=
            REQ_LINE_tbl (i).ERROR_MESSAGE
            || 'INVALID DESTINATION TYPE - ';
            END IF;
		END;


    --- VALIDATE SUPPLIER ---

	BEGIN
		BEGIN
			BEGIN
			SELECT VENDOR_ID INTO REQ_LINE_tbl(i).VENDOR_ID
			FROM AP_SUPPLIERS 
			WHERE UPPER(VENDOR_NAME) = UPPER(REQ_LINE_tbl(i).SUPPLIER) ;
        
			EXCEPTION 
			WHEN OTHERS THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'INVALID SUPPLIER' ;
			END ;
         
		
	--- VALIDATE SITE ---
	   
	    
        SELECT VENDOR_SITE_ID INTO  REQ_LINE_tbl(i).VENDOR_SITE_ID
        FROM AP_SUPPLIER_SITES_ALL 
        WHERE UPPER(VENDOR_SITE_CODE) =  UPPER(REQ_LINE_tbl(i).SITE) 
        --AND ORG_ID = REQ_HDR_tbl (i).ORG_ID 
        --AND UPPER(VENDOR_ID) = UPPER( REQ_LINE_tbl(i).VENDOR_ID);

		EXCEPTION 
        WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'INVALID SUPPLIER SITE' ;
		END ;
		
	--- SITE FOR PARTICULAR SUPPLIER ---
		
		SELECT VENDOR_SITE_ID INTO  REQ_LINE_tbl(i).VENDOR_SITE_ID
		FROM AP_SUPPLIER_SITES_ALL 
		WHERE UPPER(VENDOR_SITE_CODE) =  UPPER(REQ_LINE_tbl(i).SITE) 
		AND ORG_ID = REQ_HDR_tbl (i).ORG_ID 
		AND VENDOR_ID = REQ_LINE_tbl(i).VENDOR_ID ;

		EXCEPTION 
		WHEN OTHERS THEN
		REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
		REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'INVALID SITE FOR THIS SUPPLIER' ;
	END ;
		
		--- SOURCE ---
		
		BEGIN
		
			LN_COUNT = 0 ;
		
			SELECT COUNT(*) 
			INTO LN_COUNT
			FROM PO_LOOKUP_CODES
			WHERE LOOKUP_CODE = REQ_LINE_tbl(i).SOURCE
			AND ENABLED_FLAG = 'Y'
			AND LOOKUP_TYPE = 'VENDOR TYPE' ;
		
			IF LN_COUNT = 0
			THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'INVALID SOURCE' ;
			END IF ;
		END ;
        
		
		
        --- CHARGE ACCOUNT ---
         
		BEGIN     
			SELECT gcc.CHART_OF_ACCOUNTS_ID 
			INTO REQ_LINE_tbl(i).CHARGE_ACCOUNT_ID
			FROM hr_operating_units hou,
                xle_entity_profiles xlef,
                GL_LEDGERS gll,
                gl_code_combinations gcc
			WHERE     hou.DEFAULT_LEGAL_CONTEXT_ID = xlef.LEGAL_ENTITY_ID
                AND hou.SET_OF_BOOKS_ID = gll.LEDGER_ID
                AND hou.organization_id = 204
                AND gcc.CHART_OF_ACCOUNTS_ID = gll.CHART_OF_ACCOUNTS_ID
                AND    gcc.segment1
                    || '-'
                    || gcc.segment2
                    || '-'
                    || gcc.segment3
                    || '-'
                    || gcc.segment4
                    || '-'
                    || gcc.segment5 =   REQ_LINE_tbl(i).CHARGE_ACCOUNT ;	
        
			EXCEPTION 
			WHEN OTHERS THEN
			REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
			REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'INVALID CHARGE ACCOUNT' ;
        END ;

		--- CODE COMBINATION ID ---
		
		BEGIN
		select gcc.code_combination_id
		INTO REQ_LINE_tbl(i).code_combination_id
		from gl_ledgers GLL
		, gl_code_combinations gcc
		where 1=1
		and gll.ledger_id = fnd_profile.value('GL_SET_OF_BKS_ID')
		and gcc.CHART_OF_ACCOUNTS_ID = gll.CHART_OF_ACCOUNTS_ID
		and gcc.segment1||'-'||gcc.segment2||'-'||gcc.segment3||'-'||gcc.segment4||'-'||gcc.segment5 = REQ_LINE_tbl(i).CHARGE_ACCOUNT ;		
		 
		EXCEPTION 
        WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN code combination id' ;
		END ;
            
			
        /*
	    IF REQ_LINE_tbl(i).PROCESS_FLAG = 'E' THEN
        ln_error_count := ln_error_count + 1;
        END IF;
        ln_total_lines := ln_total_lines + 1;
		*/

        --- UPDATE LINE ---
            
            UPDATE XXQGEN_PO_REQ_LINES_STG_AR
               SET PROCESS_FLAG = REQ_LINE_tbl (i).PROCESS_FLAG,
                   ERROR_MESSAGE = REQ_LINE_tbl (i).ERROR_MESSAGE,
                   ITEM_ID = REQ_LINE_tbl (i).ITEM_ID,
                   LINE_TYPE_ID = REQ_LINE_tbl (i).LINE_TYPE_ID,
                   CATEGORY_ID = REQ_LINE_tbl (i).CATEGORY_ID,
                   TO_PERSON_ID = REQ_LINE_tbl (i).TO_PERSON_ID,
                   ORGANIZATION_ID = REQ_LINE_tbl (i).ORGANIZATION_ID,
                   LOCATION_ID = REQ_LINE_tbl (i).LOCATION_ID,
                   VENDOR_ID = REQ_LINE_tbl (i).VENDOR_ID,
                   VENDOR_SITE_ID = REQ_LINE_tbl (i).VENDOR_SITE_ID,
                   CHARGE_ACCOUNT_ID = REQ_LINE_tbl (i).CHARGE_ACCOUNT_ID 
				   code_combination_id =  REQ_LINE_tbl (i).code_combination_id
                  WHERE RECORD_ID  = REQ_LINE_tbl (i).RECORD_ID ;
                                                        
      COMMIT;
      END LOOP;
      END LOOP;

      CLOSE CUR_REQ_LINE;
     
      
    /*
            IF ln_error_count = ln_total_lines THEN
            REQ_HDR_tbl(i).PROCESS_FLAG := 'E';
            REQ_HDR_tbl(i).ERROR_MESSAGE := 'ALL LINES HAVE ERRORS';
           ELSE
            REQ_HDR_tbl(i).PROCESS_FLAG := 'V';
            REQ_HDR_tbl(i).ERROR_MESSAGE := NULL;
            END IF;
	*/

      -- UPDATE HDR VALUES ---


            UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
               SET PROCESS_FLAG = REQ_HDR_tbl (i).PROCESS_FLAG,
                   ERROR_MESSAGE = REQ_HDR_tbl (i).ERROR_MESSAGE,
                   ORG_ID = REQ_HDR_tbl (i).ORG_ID,
                   PREPARER_ID = REQ_HDR_tbl (i).PREPARER_ID
             WHERE 1=1
            AND REQUEST_ID = REQ_HDR_tbl (i).REQUEST_ID
            AND REQUISITION_NUMBER = REQ_HDR_tbl (i).REQUISITION_NUMBER ;
          
        END LOOP;

        COMMIT;
		EXCEPTION 
		WHEN OTHERS THEN
		fnd_file.put_line (fnd_file.LOG,'ERROR INSIDE VALIDATION LOOP'||SQLCODE||' '||SQLERRM ) ;	 
		END ;
		END LOOP;

      CLOSE CUR_REQ_HDR;


      
      EXCEPTION WHEN OTHERS 
      THEN 
            fnd_file.put_line (fnd_file.LOG,'ERROR IN VALIDATE DATA '||SQLCODE||' '||SQLERRM ) ;
      
    END VALIDATE_DATA;


    /*************************************************************************************************
     * Program Name : VALIDATE_REQUIRED
     * Language     : PL/SQL
     * Description  : VALIDATE MENDATORY FIELDS.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/

    
    PROCEDURE VALIDATE_REQUIRED IS
    BEGIN
    
    UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'OPERATING_UNIT CAN NOT BE NULL' 
    WHERE OPERATING_UNIT IS NULL 
    AND REQUEST_ID = gn_request_id ;
    
	
    UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'PREPARER CAN NOT BE NULL' 
    WHERE PREPARER IS NULL 
    AND REQUEST_ID = gn_request_id ;
    
	
    UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'REQUISITION TYPE CAN NOT BE NULL' 
    WHERE REQUISITION_TYPE IS NULL 
    AND REQUEST_ID = gn_request_id ;

    
    UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'AUTHORIZATION STATUS CAN NOT BE NULL' 
    WHERE AUTHORIZATION_STATUS IS NULL 
    AND REQUEST_ID = gn_request_id ;
	
	
	
	UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR HDR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'LINES NOT EXIST FOR THIS HEADER' 
    WHERE NOT EXISTS
	(SELECT 1 FROM XXQGEN_PO_REQ_LINES_STG_AR LINE 
	 WHERE LINE.REQUISITION_NUMBER = HDR.REQUISITION_NUMBER 
	 AND LINE.REQUEST_ID = gn_request_id ) ;
    
	
    
	---- LINE LEVEL ---
	
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'HEADER NOT EXISTS FOR THIS LINE' 
    WHERE REQUISITION_NUMBER IS NULL 
    AND REQUEST_ID = gn_request_id ;
    
	
    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'ITEM_NUMBER CAN NOT BE NULL' 
    WHERE ITEM_NUMBER IS NULL 
    AND REQUEST_ID = gn_request_id ;
    
    
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'CATEGORY CAN NOT BE NULL' 
    WHERE CATEGORY IS NULL 
    AND REQUEST_ID = gn_request_id ;

    
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'REQUESTER CAN NOT BE NULL' 
    WHERE REQUESTER IS NULL 
    AND REQUEST_ID = gn_request_id ;


    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'LINE_TYPE CAN NOT BE NULL' 
    WHERE LINE_TYPE IS NULL 
    AND REQUEST_ID = gn_request_id ;
    

    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'ORGANIZATION CAN NOT BE NULL' 
    WHERE ORGANIZATION IS NULL 
    AND REQUEST_ID = gn_request_id ;
    

    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'LOCATION CAN NOT BE NULL' 
    WHERE LOCATION IS NULL 
    AND REQUEST_ID = gn_request_id ;
    

    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'SUPPLIER CAN NOT BE NULL' 
    WHERE SUPPLIER IS NULL 
    AND REQUEST_ID = gn_request_id ;
    
	
    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'UOM CAN NOT BE NULL' 
    WHERE UOM IS NULL 
    AND REQUEST_ID = gn_request_id ;
    
    
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'QUANTITY CAN NOT BE NULL' 
    WHERE QUANTITY IS NULL
    AND REQUEST_ID = gn_request_id ;

    
    UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'UNIT_PRICE CAN NOT BE NULL' 
    WHERE UNIT_PRICE IS NULL 
    AND REQUEST_ID = gn_request_id ;
	
	
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'NEED_BY_DATE CAN NOT BE NULL OR LESS THEN SYSDATE' 
    WHERE NEED_BY_DATE IS NULL 
	AND NEED_BY_DATE < SYSDATE
    AND REQUEST_ID = gn_request_id ;
	
	
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'DESTINATION_TYPE CAN NOT BE NULL' 
    WHERE DESTINATION_TYPE IS NULL 
    AND REQUEST_ID = gn_request_id ;
	
	
	UPDATE XXQGEN_PO_REQ_LINES_STG_AR
    SET PROCESS_FLAG = 'E',
    ERROR_MESSAGE = 'CHARGE_ACCOUNT CAN NOT BE NULL' 
    WHERE CHARGE_ACCOUNT IS NULL 
    AND REQUEST_ID = gn_request_id ;

    
    EXCEPTION
    WHEN OTHERS THEN 
    fnd_file.put_line (fnd_file.LOG,'ERROR IN VALIDATE REQUIRED '||SQLCODE||' '||SQLERRM ) ;
    
    END VALIDATE_REQUIRED ;
    



    /*************************************************************************************************
     * Program Name : LOAD_DATA
     * Language     : PL/SQL
     * Description  : LOAD DATA INTO STAGING TABLE.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/


   PROCEDURE LOAD_DATA
   IS
   BEGIN
      INSERT INTO XXQGEN_PO_REQ_HEADERS_STG_AR
           VALUES (
                    REQ_LOAD_REC_ID_SEQ_AR.NEXTVAL ,
                  gn_request_id,
                  gn_user_id,
                   gd_date,
                  gn_user_id,
                   gd_date,
                   'N',
                   NULL,
                   NULL,
                   REQ_NUM_SEQ_AR.NEXTVAL,
                   NULL,
                   'Stock, Ms. Pat',
                   'Vision Operations',
                   NULL,
                   'INCOMPLETE',
                   'TEST87',
                   'PURCHASE');
                  
                         
 INSERT INTO XXQGEN_PO_REQ_LINES_STG_AR
           VALUES (
                    REQ_LOAD_REC_ID_SEQ2_AR.NEXTVAL ,
                gn_request_id,
                   gn_user_id,
                   gd_date,
                  gn_user_id,
                   gd_date,
                   'N', 
                   NULL,
                   REQ_NUM_SEQ_AR.CURRVAL,
                   NULL,
                   1,
                   'Goods',
                   NULL,
                   NULL,
                   'f20000',
                   'Paper - requires 2-way match office supply item',
                   NULL,
                   'SUPPLIES.OFFICE',
                   'Each',
                   1,
                   50,
                   'USD',
                   NULL,
                   'Stock, Ms. Pat',
                   SYSDATE + 10,
                   NULL,
                   'Vision Operations',
                   NULL,
                   'V1- New York City',
                   NULL,
                   '3M Health Care',
                   NULL,
                   'CORP HQ',
                   NULL,
                   'Jones Samantha',
                   '651 737-7777',
                   'EXPENSE',
                   NULL,
                   'VENDOR',
                   NULL,
                   NULL,
                   '01-510-7530-0000-000' ,
                   NULL
                   );

           
                   INSERT INTO XXQGEN_PO_REQ_HEADERS_STG_AR
           VALUES (
                    REQ_LOAD_REC_ID_SEQ_AR.NEXTVAL ,
                  gn_request_id,
                  gn_user_id,
                   gd_date,
                  gn_user_id,
                   gd_date,
                   'N',
                   NULL,
                   NULL,
                   REQ_NUM_SEQ_AR.NEXTVAL,
                   NULL,
                   'Stock, Ms. Pat',
                   'Vision Operation',
                   NULL,
                   'INCOMPLETE',
                   'TEST20',
                   'PURCHASE');
                   
                   
                   
      INSERT INTO XXQGEN_PO_REQ_LINES_STG_AR
           VALUES (
                    REQ_LOAD_REC_ID_SEQ2_AR.NEXTVAL ,
                gn_request_id,
                   gn_user_id,
                   gd_date,
                  gn_user_id,
                   gd_date,
                   'N', 
                   NULL,
                   REQ_NUM_SEQ_AR.CURRVAL,
                   NULL,
                   1,
                   'Goods',
                   NULL,
                   NULL,
                   'f20000',
                   'Paper - requires 2-way match office supply item',
                   NULL,
                   'SUPPLIES.OFFICE',
                   'Each',
                   1,
                   50,
                   'USD',
                   NULL,
                   'Stock, Ms. Pat',
                   SYSDATE +10 ,
                   NULL,
                   'Vision Operation',
                   NULL,
                   'V1- New York City',
                   NULL,
                   '3M Health Care',
                   NULL,
                   'CORP HQ',
                   NULL,
                   'Jones Samantha',
                   '651 737-7777',
                   'EXPENSE',
                   NULL,
                   'VENDOR',
                   NULL,
                   NULL,
                   '01-510-7530-0000-000' ,
                   NULL
                   );
              
            
     
      COMMIT;
      
      EXCEPTION 
      WHEN OTHERS THEN
      fnd_file.put_line (fnd_file.LOG, 'error in load data '||SQLCODE||' '||SQLERRM);
    
    END LOAD_DATA;



    /*************************************************************************************************
     * Program Name : MAIN
     * Language     : PL/SQL
     * Description  : CALL ALL THE PROCESS .
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/
     

   PROCEDURE MAIN(p_erbuff OUT VARCHAR2, p_retcode OUT VARCHAR2)
   IS
   BEGIN
    LOAD_DATA;
    VALIDATE_DATA;
    INTERFACE_DATA ;
    SUBMIT_REQUISITION ;
    UPDATE_STATUS ;
    SUBMIT_REPORT ;
    
    EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'ERROR IN MAIN : ' || SQLCODE || ',' || SQLERRM);

   END MAIN;


END XXQGEN_REQ_DATA_LOAD_PKG_AR;



