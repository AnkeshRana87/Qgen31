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
     * ANKESH RANA        1.0          23-FEB-2025      Initial Version
	 ***************************************************************************************************/
     
	/*************************************************************************************************
     * Program Name : SUBMIT_REPORT
     * Language     : PL/SQL
     * Description  : SUBMIT REPORT FOR PROCESSED DATA.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
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
      l_layout               BOOLEAN;

      
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
/*
      IF ln_request = 0
      THEN
         fnd_file.put_line ( fnd_file.LOG, 'REQUEST ID : '|| gn_request_id);
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

*/

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

BEGIN

FOR REC IN (

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
AND PRHA.ATTRIBUTE7 = gn_request_id )

LOOP

UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
SET PROCESS_FLAG = 'P'
, REQUISITION_NUMBER = REC.SEGMENT1
, REQUISITION_HEADER_ID  = REC.REQUISITION_HEADER_ID
WHERE RECORD_ID = REC.ATTRIBUTE8
AND REQUEST_ID = REC.ATTRIBUTE7 ;

UPDATE XXQGEN_PO_REQ_LINES_STG_AR
SET PROCESS_FLAG = 'P'
, REQUISITION_NUMBER = REC.SEGMENT1
, REQUISITION_LINE_ID  = REC.REQUISITION_LINE_ID
, DISTRIBUTION_ID = REC.DISTRIBUTION_ID
WHERE RECORD_ID = REC.LINE8
AND  REQUEST_ID = REC.LINE7 ;

END LOOP ;
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
      
      fnd_file.put_line (   fnd_file.LOG,'REQUEST TO UPLOAD REQUISITION LEGACY DATA START1.' || gn_request_id);

      IF ln_request = 0
      THEN
         fnd_file.put_line ( fnd_file.LOG, 'REQUEST TO UPLOAD REQUISITION LEGACY DATA NOT SUBMITTED.'|| gn_request_id);
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
                         'REQUEST TO UPLOAD REQUISITION LEGACY DATA START2.');
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
     * Program Name : PROCESS_DATA
     * Language     : PL/SQL
     * Description  : INSERT VALID DATA INTO INTERFACE TABLE.
     * History      :
     *
     * WHO               Version #    WHEN             WHAT
     * ===============   ==========   =============    ================================================
     * ANKESH RANA       1.0          23-FEB-2025     Initial Version
     ***************************************************************************************************/


PROCEDURE PROCESS_DATA 
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
         LIMIT 100;

         FOR i IN 1 .. process_tbl.COUNT loop

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
            
        end loop ;
                 EXIT WHEN process_tbl.COUNT = 0;
        END LOOP;
        
        COMMIT ;
        CLOSE  CUR_PROCESS ;

        
        EXCEPTION WHEN OTHERS 
        THEN
         fnd_file.put_line (
            fnd_file.LOG,
            'ERROR CREATE REQ INTERFACE DTLS : ' || SQLCODE || ',' || SQLERRM);
      END PROCESS_DATA;
      
      
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
  

-- OPEN HEADER LEVEL CURSOR --

 BEGIN

 
      OPEN CUR_REQ_HDR;

      LOOP
         FETCH CUR_REQ_HDR
         BULK COLLECT INTO REQ_HDR_tbl
         LIMIT 10;

         EXIT WHEN REQ_HDR_tbl.COUNT = 0;

         FOR i IN 1 .. REQ_HDR_tbl.COUNT
         LOOP
            REQ_HDR_tbl (i).PROCESS_FLAG := 'V';
            REQ_HDR_tbl (i).ERROR_MESSAGE := NULL;

            --- OPERATING UNIT ---
            
            IF REQ_HDR_tbl (i).OPERATING_UNIT IS NULL
            THEN
               REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
               REQ_HDR_tbl (i).ERROR_MESSAGE :=
                  'OPERATING_UNIT CAN NOT BE NULL' ;
            ELSE
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
            END IF;

            --- PREPARER ---
            
            IF REQ_HDR_tbl (i).PREPARER IS NULL
            THEN
               REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
               REQ_HDR_tbl (i).ERROR_MESSAGE := 'PREPARER CAN NOT BE NULL';
            ELSe
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
            END IF;

            --- REQUISITION_TYPE ---
            
            IF REQ_HDR_tbl (i).requisition_type IS NULL
            THEN
               REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
               REQ_HDR_tbl (i).ERROR_MESSAGE :=
                  REQ_HDR_tbl (i).ERROR_MESSAGE
                  || 'REQUISITION TYPE CANNOT BE NULL - ';
            ELSE
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
            END IF;
            
            
             --VALIDATE  REQ STATUS
             
            IF REQ_HDR_tbl (i).AUTHORIZATION_STATUS IS NULL
            THEN
               REQ_HDR_tbl (i).PROCESS_FLAG := 'E';
               REQ_HDR_tbl (i).ERROR_MESSAGE :=
                  REQ_HDR_tbl (i).ERROR_MESSAGE || 'STATUS CANNOT BE NULL - ';
            ELSE
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
            END IF;
            

      --- OPEN LINE LEVEL CURSOR ---
      
      OPEN CUR_REQ_LINE (REQ_HDR_tbl (i).REQUISITION_NUMBER);


      LOOP
         FETCH CUR_REQ_LINE
         BULK COLLECT INTO REQ_LINE_tbl
         LIMIT 10;

         EXIT WHEN REQ_LINE_tbl.COUNT = 0;

         FOR i IN 1 .. REQ_LINE_tbl.COUNT
         LOOP
            REQ_LINE_tbl (i).PROCESS_FLAG := 'V';
            REQ_LINE_tbl (i).ERROR_MESSAGE := NULL;
            
                
            --- VALIDATE ITEM ---
            
            IF REQ_LINE_tbl (i).ITEM_NUMBER IS NULL
            THEN
               REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
               REQ_LINE_tbl (i).ERROR_MESSAGE :=  REQ_LINE_tbl (i).ERROR_MESSAGE ||'-'|| 'ITEM CAN NOT BE NULL';
            ELSE
               BEGIN
                  SELECT INVENTORY_ITEM_ID
                    INTO REQ_LINE_tbl (i).ITEM_ID
                    FROM MTL_SYSTEM_ITEMS_B MSIB,
                         ORG_ORGANIZATION_DEFINITIONS OOD
                   WHERE UPPER (REQ_LINE_tbl (i).ITEM_NUMBER) =UPPER (MSIB.SEGMENT1)
                         AND MSIB.ORGANIZATION_ID = OOD.ORGANIZATION_ID
                         AND OOD.ORGANIZATION_NAME = REQ_LINE_tbl (i).ORGANIZATION;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
                     REQ_LINE_tbl (i).ERROR_MESSAGE := REQ_LINE_tbl (i).ERROR_MESSAGE ||'-'||'ERROR IN FETCHING ITEM';
               END;
            END IF;

         

            --- VALIDATE CATEGORY ---
            
            IF REQ_LINE_tbl (i).CATEGORY IS NULL
            THEN
               REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
               REQ_LINE_tbl (i).ERROR_MESSAGE := REQ_LINE_tbl (i).ERROR_MESSAGE ||'-'||'CATEGORY CAN NOT BE NULL';
            ELSE
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
            END IF;
            

        --- VALIDATE REQUESTER ---
        
        IF REQ_LINE_tbl(i).REQUESTER IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'REQUESTER CAN NOT BE NULL' ;
        
        ELSE 
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
        END IF ;
        
        
        --- VALIDATE LINE TYPE ---
        
        IF REQ_LINE_tbl(i).LINE_TYPE IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'LINE TYPE CAN NOT BE NULL' ;
        
        ELSE 
        BEGIN
        SELECT LINE_TYPE_ID INTO REQ_LINE_tbl(i).LINE_TYPE_ID
        FROM PO_LINE_TYPES
        WHERE UPPER(LINE_TYPE) = UPPER(REQ_LINE_tbl(i).LINE_TYPE) ;
                
        EXCEPTION 
        WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING LINE TYPE' ;
        END ;
        END IF ;
        

        
        --- ORGANIZATION ---
        
        IF REQ_LINE_tbl(i).ORGANIZATION IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ORGANIZATION CAN NOT BE NULL' ;
        
        ELSE 
        BEGIN
        SELECT ORGANIZATION_ID INTO REQ_LINE_tbl(i).ORGANIZATION_ID
        FROM ORG_ORGANIZATION_DEFINITIONS 
        WHERE UPPER(ORGANIZATION_NAME) = UPPER(REQ_LINE_tbl(i).ORGANIZATION) ;
        
        EXCEPTION 
        WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING ORGANIZATION' ;
        END ;
        END IF ;
        
        
        --- VALIDATE LOCATION ---
        
        IF REQ_LINE_tbl(i).LOCATION IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE|| '-'|| 'LOCATION CAN NOT BE NULL' ;
        
        ELSE 
        
        BEGIN
        SELECT LOCATION_ID INTO REQ_LINE_tbl(i).LOCATION_ID
        FROM HR_LOCATIONS 
        WHERE UPPER(LOCATION_CODE) = UPPER(REQ_LINE_tbl(i).LOCATION) ;
        
        EXCEPTION 
        WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING LOCATION' ;
        END ;
        END IF ;
                            
                    
                    
        --VALIDATION DESTINATION TYPE
                                      
                  IF REQ_LINE_tbl (i).DESTINATION_TYPE IS NULL
                  THEN
                     REQ_LINE_tbl (i).PROCESS_FLAG := 'E';
                     REQ_LINE_tbl (i).ERROR_MESSAGE :=
                        ' DESTINATION TYPE CANNOT BE NULL - ';
                  ELSE
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
                  END IF;

        --- VALIDATE SUPPLIER ---
        
        IF REQ_LINE_tbl(i).SUPPLIER IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'SUPPLIER CAN NOT BE NULL' ;
        
        ELSE 
        BEGIN
        SELECT VENDOR_ID INTO REQ_LINE_tbl(i).VENDOR_ID
        FROM AP_SUPPLIERS 
        WHERE UPPER(VENDOR_NAME) = UPPER(REQ_LINE_tbl(i).SUPPLIER) ;
        
        EXCEPTION 
        WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING SUPPLIER' ;
        END ;
        END IF ;
        
        
        --- VALIDATE SITE ---
        
        BEGIN
        SELECT VENDOR_SITE_ID INTO  REQ_LINE_tbl(i).VENDOR_SITE_ID
        FROM AP_SUPPLIER_SITES_ALL 
        WHERE UPPER(VENDOR_SITE_CODE) =  UPPER(REQ_LINE_tbl(i).SITE) 
        AND ORG_ID = 204 
        AND UPPER(VENDOR_ID) = UPPER( REQ_LINE_tbl(i).VENDOR_ID);
        
        EXCEPTION WHEN OTHERS 
        THEN
         REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN FETCHING SITE' ;
        END ;
        
        ---UOM ---
        
        IF REQ_LINE_tbl(i).UOM IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'UOM CAN NOT BE NULL' ;
        END IF ;
        

        --- QUANTITY ---        
        
        IF REQ_LINE_tbl(i).QUANTITY IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'QUANTITY CAN NOT BE NULL' ;
        END IF ;
        

        --- UNIT_PRICE ---
        
        IF REQ_LINE_tbl(i).UNIT_PRICE IS NULL
        THEN REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'UNIT_PRICE CAN NOT BE NULL' ;
        END IF ;
		
		

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
                    || gcc.segment5 =   REQ_LINE_tbl(i).CHARGE_ACCOUNT
                    ;
         EXCEPTION 
         WHEN OTHERS THEN
        REQ_LINE_tbl(i).PROCESS_FLAG := 'E' ;
        REQ_LINE_tbl(i).ERROR_MESSAGE :=REQ_LINE_tbl (i).ERROR_MESSAGE||'-'|| 'ERROR IN  CHARGE ACCOUNT ID ' ;
         END ;

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
                  WHERE   RECORD_ID  = REQ_LINE_tbl (i).RECORD_ID ;
                                                        
            REQ_LINE_tbl (i).PROCESS_FLAG := 'V';
            REQ_LINE_tbl (i).ERROR_MESSAGE := NULL;
                
          COMMIT;

         END LOOP;

      END LOOP;

      CLOSE CUR_REQ_LINE;
      
      -- UPDATE HDR VALUES ---

            UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
               SET PROCESS_FLAG = REQ_HDR_tbl (i).PROCESS_FLAG,
                   ERROR_MESSAGE = REQ_HDR_tbl (i).ERROR_MESSAGE,
                   ORG_ID = REQ_HDR_tbl (i).ORG_ID,
                   PREPARER_ID = REQ_HDR_tbl (i).PREPARER_ID
             WHERE 1=1
            AND REQUEST_ID = REQ_HDR_tbl (i).REQUEST_ID
            AND REQUISITION_NUMBER = REQ_HDR_tbl (i).REQUISITION_NUMBER ;
          

            REQ_HDR_tbl (i).PROCESS_FLAG := 'V';
            REQ_HDR_tbl (i).ERROR_MESSAGE := NULL;
         END LOOP;

         COMMIT;
      END LOOP;

      CLOSE CUR_REQ_HDR;


      
      EXCEPTION WHEN OTHERS 
      THEN 
            fnd_file.put_line (fnd_file.LOG,'ERROR IN VALIDATE DATA '||SQLCODE||' '||SQLERRM ) ;
      
	END VALIDATE_DATA;



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
                   SYSDATE,
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
                   '13185',
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
                   SYSDATE,
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
                   '13185',
                   '01-510-7530-0000-000' ,
                   NULL
                   );
              
            
     
      COMMIT;
      
      EXCEPTION 
      WHEN OTHERS THEN
                  fnd_file.put_line (fnd_file.LOG, 'error in load data ');
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
    PROCESS_DATA ;
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



