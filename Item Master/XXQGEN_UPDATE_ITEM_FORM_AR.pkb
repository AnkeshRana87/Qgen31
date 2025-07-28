/* Formatted on 5/23/2025 10:39:58 AM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY XXQGEN_UPDATE_ITEM_FORM_AR
AS
   /*************************************************************************************************
    *                 Copy Rights Reserved © QGEN- 2024
    *
    * $Header: @(#)
    * Program Name : XXQGEN_ITEM_CREATION_AR.pkb
    * Language     : PL/SQL
    * Description  : IMPORT ITEMS
    * History      :
    *
    * WHO                Version #    WHEN             WHAT
    * ===============    =========    =============    ==================================================
    * ANKESH RANA        1.0          15-MAY-2025      Initial Version
    ***************************************************************************************************/

   PROCEDURE PROCESS_DATA
   IS
      /*************************************************************************************************
      * Program Name : PROCESS_DATA
      * Language     : PL/SQL
      * Description  : INSERT VALID DATA USING API.
      * History      :
      * WHO               Version #    WHEN             WHAT
      * ===============   ==========   =============    ================================================
      * ANKESH RANA       1.0          15-MAY-2025     Initial Version
      ***************************************************************************************************/

      -- Variables --
      l_item_table      EGO_ITEM_PUB.Item_Tbl_Type;
      x_item_table      EGO_ITEM_PUB.Item_Tbl_Type;
      x_return_status   VARCHAR2 (1);
      x_msg_count       NUMBER;
      x_msg_data        VARCHAR2 (1000);
      x_message_list    ERROR_HANDLER.error_tbl_type;

      l_assign_status   VARCHAR2 (1);
      l_index           NUMBER := 0;
      ln_exists         NUMBER;

      CURSOR cur_items
      IS
         SELECT *
           FROM xxqgen_item_stg_ar
          WHERE process_flag = 'V';
   BEGIN
      FND_GLOBAL.APPS_INITIALIZE (user_id        => gn_user_id,
                                  resp_id        => gn_resp_id,
                                  resp_appl_id   => gn_resp_appl_id);

      FOR rec IN cur_items
      LOOP
         SELECT COUNT (1)
           INTO ln_exists
           FROM mtl_system_items_b
          WHERE segment1 = rec.segment1
                AND organization_id = rec.organization_id;

         IF ln_exists = 0
         THEN
            l_index := l_index + 1;
            l_item_table (l_index).transaction_type := rec.transaction_type;
            l_item_table (l_index).segment1 := rec.segment1;
            l_item_table (l_index).description := rec.description;
            l_item_table (l_index).long_description := rec.long_description;
            l_item_table (l_index).organization_id := rec.organization_id;
            l_item_table (l_index).template_id := rec.template_id;
            l_item_table (l_index).template_name := rec.template_name;
            l_item_table (l_index).inventory_item_status_code :=rec.inventory_item_status_code;
         ELSE
         
         UPDATE xxqgen_item_stg_ar
               SET process_flag = 'E',
                   error_message = 'Duplicate item: already exists in MSIB',
                   last_update_date = SYSDATE
             WHERE segment1 = rec.segment1
                   AND organization_id = rec.organization_id;
         END IF;
      END LOOP;

      EGO_ITEM_PUB.Process_Items (p_api_version     => 1.0,
                                  p_init_msg_list   => FND_API.G_TRUE,
                                  p_commit          => FND_API.G_FALSE,
                                  p_item_tbl        => l_item_table,
                                  x_item_tbl        => x_item_table,
                                  x_return_status   => x_return_status,
                                  x_msg_count       => x_msg_count);


      FOR i IN 1 .. x_item_table.COUNT
      LOOP
         IF x_item_table (i).return_status = fnd_api.g_ret_sts_success
         THEN

                -- Update staging table as successful

            UPDATE xxqgen_item_stg_ar
               SET process_flag = 'S',
                   error_message = NULL,
                   ATTRIBUTE1 = x_item_table (i).inventory_item_id,
                   last_update_date = SYSDATE
             WHERE segment1 = x_item_table (i).segment1
             AND organization_id = x_item_table (i).organization_id;

          -- assign item to org --

/*
            DECLARE
               CURSOR cur_org
               IS
                  SELECT *
                    FROM item_org_mapping
                   WHERE item_code = x_item_table (i).segment1;
                   
            BEGIN
               FOR rec IN cur_org
               LOOP
                  l_index := l_index + 1;
                  x_item_table (l_index).organization_id := rec.target_org_id;
               END LOOP;
--               END;

--            
BEGIN
               EGO_ITEM_PUB.assign_item_to_org (
                  p_api_version         => 1.0,
                  p_init_msg_list       => FND_API.G_TRUE,
                  p_commit              => FND_API.G_FALSE,
                  p_inventory_item_id   => x_item_table (i).inventory_item_id,
                  p_organization_id     => 207,--x_item_table(i).organization_id,
                  x_return_status       => l_assign_status,
                  x_msg_count           => x_msg_count);
                  
                fnd_file.put_line (
                fnd_file.LOG,
                'SUCCESS assign_item_to_org' );

                EXCEPTION
                WHEN OTHERS
                THEN
                fnd_file.put_line (
                fnd_file.LOG,
                'Error In ASSIGN_ITEM_TO_ORG :' || x_item_table (i).inventory_item_id);
                END;
*/
BEGIN
   FOR org_rec IN (
      SELECT target_org_id
        FROM item_org_mapping
       WHERE item_code = x_item_table(i).segment1
   ) LOOP
      BEGIN
         EGO_ITEM_PUB.assign_item_to_org (
            p_api_version         => 1.0,
            p_init_msg_list       => FND_API.G_TRUE,
            p_commit              => FND_API.G_FALSE,
            p_inventory_item_id   => x_item_table(i).inventory_item_id,
            p_organization_id     => org_rec.target_org_id,
            x_return_status       => l_assign_status,
            x_msg_count           => x_msg_count
--            x_msg_data            => x_msg_data
         );
        

         IF l_assign_status = FND_API.G_RET_STS_SUCCESS THEN
            fnd_file.put_line(fnd_file.LOG,
               'SUCCESS: Assigned item ' || x_item_table(i).segment1 ||
               ' to org ' || org_rec.target_org_id);
    
             
         ELSE
            fnd_file.put_line(fnd_file.LOG,
               'FAILED: Item ' || x_item_table(i).segment1 ||
               ' to org ' || org_rec.target_org_id || 
               ' - ' || x_msg_data);
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.LOG,
               'ERROR during assignment of item ' || x_item_table(i).segment1 ||
               ' to org ' || org_rec.target_org_id || ': ' || SQLERRM);
      END;
   END LOOP;
END;


         ELSE
         
        UPDATE xxqgen_item_stg_ar
        SET process_flag = 'E',
        error_message =
            'Item Creation failed: ' || SUBSTR (x_msg_data, 1, 2000),
            last_update_date = SYSDATE
             WHERE segment1 = x_item_table (i).segment1
                   AND organization_id = x_item_table (i).organization_id;
         END IF;
      END LOOP;

                fnd_file.put_line (
                fnd_file.LOG,
                'SUCCESS PROCESS_DATA' );
                
      COMMIT;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
            'Error In Process Data:' || SQLCODE || ' ' || SQLERRM);
         ROLLBACK;
   END PROCESS_DATA;
   

   /*************************************************************************************************
    * Program Name : VALIDATE_DATA
    * Language     : PL/SQL
    * Description  : VALIDATE DATA INTO STAGING TABLE.
    * History      :
    *
    * WHO               Version #    WHEN             WHAT
    * ===============   ==========   =============    ================================================
    * ANKESH RANA       1.0          19-May-2025     Initial Version
    ***************************************************************************************************/

   PROCEDURE VALIDATE_DATA
   IS
      CURSOR CUR_ITEM
      IS
         SELECT *
           FROM xxqgen_item_stg_ar
          WHERE PROCESS_FLAG IN( 'N' ,'E') ;
--          AND REQUEST_ID = gn_request_id;

      TYPE ITEM_DATA_TYPE IS TABLE OF CUR_ITEM%ROWTYPE
                                INDEX BY PLS_INTEGER;

      ITEM_TBL   ITEM_DATA_TYPE;
   BEGIN
      OPEN CUR_ITEM;

      LOOP
         FETCH CUR_ITEM
         BULK COLLECT INTO ITEM_TBL
         LIMIT gn_limit;

         EXIT WHEN ITEM_TBL.COUNT = 0;

         FOR i IN 1 .. ITEM_TBL.COUNT
         LOOP
            BEGIN
               ITEM_TBL (i).PROCESS_FLAG := 'V';
               ITEM_TBL (i).ERROR_MESSAGE := NULL;


               --- Organization Name ---

               BEGIN
                  SELECT ORGANIZATION_ID
                    INTO ITEM_TBL (i).ORGANIZATION_ID
                    FROM ORG_ORGANIZATION_DEFINITIONS
                   WHERE UPPER (ORGANIZATION_CODE) =
                            UPPER (ITEM_TBL (i).ORGANIZATION_CODE);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'Invalid Organization Code';
               END;


               -- TEMPLATE NAME --

               BEGIN
                  SELECT TEMPLATE_ID
                    INTO ITEM_TBL (i).TEMPLATE_ID
                    FROM MTL_ITEM_TEMPLATES
                   WHERE UPPER (TEMPLATE_NAME) =
                            UPPER (ITEM_TBL (i).TEMPLATE_NAME);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'Invalid Template Name ';
               END;

               --- DUPLICATE ITEM NUMBER IN STAGING ---

               LN_COUNT := 0;

               BEGIN
                  SELECT COUNT (1)
                    INTO LN_COUNT
                    FROM xxqgen_item_stg_ar
                   WHERE SEGMENT1 = ITEM_TBL (i).SEGMENT1;

                  IF LN_COUNT > 1
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'Duplicate Segment1';
                     
                  END IF;
               END;


               ---- APPLY_TEMPLATE -----

               BEGIN
                  SELECT APPLY_TEMPLATE
                    INTO ITEM_TBL (i).APPLY_TEMPLATE
                    FROM xxqgen_item_stg_ar
                   WHERE APPLY_TEMPLATE IN ('ALL', 'NOT NULL', 'NULL')
                         AND RECORD_ID = ITEM_TBL (i).RECORD_ID;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'Invalid Template Type';
               END;


               ---- APPROVAL STATUS -----

               BEGIN
                  SELECT APPROVAL_STATUS
                    INTO ITEM_TBL (i).APPROVAL_STATUS
                    FROM xxqgen_item_stg_ar
                   WHERE APPROVAL_STATUS IN ('A', 'S', 'D', 'R')
                         AND RECORD_ID = ITEM_TBL (i).RECORD_ID;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'Invalid Approval Status';
               END;


               ---- TRANSACTION TYPE -----

               BEGIN
                  SELECT TRANSACTION_TYPE
                    INTO ITEM_TBL (i).TRANSACTION_TYPE
                    FROM xxqgen_item_stg_ar
                   WHERE TRANSACTION_TYPE IN ('CREATE', 'UPDATE')
                         AND RECORD_ID = ITEM_TBL (i).RECORD_ID;
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'Invalid Transaction Type';
               END;



               -- UPDATE VALUES ---

               UPDATE XXQGEN_ITEM_STG_AR
                  SET PROCESS_FLAG = ITEM_TBL (i).PROCESS_FLAG,
                      ERROR_MESSAGE = ITEM_TBL (i).ERROR_MESSAGE,
                      ORGANIZATION_ID = ITEM_TBL (i).ORGANIZATION_ID,
                      TEMPLATE_ID = ITEM_TBL (i).TEMPLATE_ID,
                      SEGMENT1= ITEM_TBL (i).SEGMENT1
                WHERE 1 = 1 -- AND REQUEST_ID = ITEM_TBL (i).REQUEST_ID
                      AND RECORD_ID = ITEM_TBL (i).RECORD_ID;
            EXCEPTION
               WHEN OTHERS
               THEN
                  fnd_file.put_line (
                     fnd_file.LOG,
                        'ERROR INSIDE VALIDATION LOOP'
                     || SQLCODE
                     || ' '
                     || SQLERRM);
            END;

            COMMIT;
         END LOOP;
      END LOOP;

      CLOSE CUR_ITEM;

      --DBMS_OUTPUT.PUT_LINE('SUCCESS VALIDATE DATA ');
      fnd_file.put_line (fnd_file.LOG, 'SUCCESS VALIDATE DATA');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
            'ERROR IN VALIDATE DATA ' || SQLCODE || ' ' || SQLERRM);
   -- DBMS_OUTPUT.PUT_LINE('ERROR IN VALIDATE DATA ');


   END VALIDATE_DATA;



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

   PROCEDURE VALIDATE_REQUIRED
   IS
   BEGIN
      UPDATE xxqgen_item_stg_ar
         SET PROCESS_FLAG = 'E',
             ERROR_MESSAGE = 'Transaction Type Can Not Be Null'
       WHERE TRANSACTION_TYPE IS NULL;
--        AND REQUEST_ID = gn_request_id;

      /*
      UPDATE xxqgen_item_stg_ar
      SET PROCESS_FLAG = 'E' ,
      ERROR_MESSAGE = 'INVALID TRANSACTION_TYPE'
      WHERE TRANSACTION_TYPE NOT IN ('CREATE','UPDATE')
      AND REQUEST_ID = gn_request_id;
      */

      UPDATE xxqgen_item_stg_ar
         SET PROCESS_FLAG = 'E', 
         ERROR_MESSAGE = 'Segment1 Can Not Be Null'
       WHERE SEGMENT1 IS NULL;
--        AND REQUEST_ID = gn_request_id;

      /*
      UPDATE xxqgen_item_stg_ar
      SET PROCESS_FLAG = 'E' ,
      ERROR_MESSAGE = 'SEGMENT1 ALREADY EXISTS IN SYSTEM'
      WHERE EXISTS
      (SELECT 1 FROM
       MTL_SYSTEM_ITEMS_B MSIB
       WHERE UPPER(MSIB.SEGMENT1) = UPPER(SEGMENT1)
       AND REQUEST_ID = 1 );
      */

      UPDATE xxqgen_item_stg_ar
         SET PROCESS_FLAG = 'E',
             ERROR_MESSAGE = 'Description Can Not Be Null'
       WHERE DESCRIPTION IS NULL ;
--       AND REQUEST_ID = gn_request_id;

      UPDATE xxqgen_item_stg_ar
         SET PROCESS_FLAG = 'E',
             ERROR_MESSAGE = 'Organization_Name Can Not Be Null'
       WHERE organization_code IS NULL; 
--       AND REQUEST_ID = gn_request_id;

      UPDATE xxqgen_item_stg_ar
         SET PROCESS_FLAG = 'E',
             ERROR_MESSAGE = 'Template_Name Can Not Be Null'
       WHERE TEMPLATE_NAME IS NULL ;
--       AND REQUEST_ID = gn_request_id;

      /*
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
      */

      --DBMS_OUTPUT.PUT_LINE('SUCCESS VALIDATE REQUIRED ');
      fnd_file.put_line (fnd_file.LOG, 'SUCCESS VALIDATE REQUIRED');
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (
            fnd_file.LOG,
            'ERROR IN VALIDATE REQUIRED ' || SQLCODE || ' ' || SQLERRM);
         DBMS_OUTPUT.PUT_LINE ('ERROR IN VALIDATE REQUIRED ');
   END VALIDATE_REQUIRED;

   /*************************************************************************************************
    * Program Name : MAIN
    * Language     : PL/SQL
    * Description  : CALL ALL THE PROCESS .
    * History      :
    *
    * WHO               Version #    WHEN             WHAT
    * ===============   ==========   =============    ================================================
    * ANKESH RANA       1.0          20-May-2025     Initial Version
    ***************************************************************************************************/


   PROCEDURE MAIN (p_erbuff OUT VARCHAR2, p_retcode OUT VARCHAR2)
   IS
   BEGIN
      VALIDATE_DATA;
      VALIDATE_REQUIRED;
      PROCESS_DATA;
   EXCEPTION
      WHEN OTHERS
      THEN
         fnd_file.put_line (fnd_file.LOG,
                            'ERROR IN MAIN : ' || SQLCODE || ',' || SQLERRM);
   END MAIN;
END XXQGEN_UPDATE_ITEM_FORM_AR;