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
          WHERE PROCESS_FLAG = 'N' 
          AND REQUEST_ID = gn_request_id ;

      TYPE ITEM_DATA_TYPE IS TABLE OF CUR_ITEM%ROWTYPE
                                   INDEX BY PLS_INTEGER;

      ITEM_TBL    ITEM_DATA_TYPE;
      
      

 BEGIN
      OPEN CUR_ITEM;

      LOOP
         FETCH CUR_ITEM
         BULK COLLECT INTO ITEM_TBL
         LIMIT gn_limit;

         EXIT WHEN ITEM_TBL.COUNT = 0;

         FOR i IN 1 .. ITEM_TBL.COUNT
         LOOP
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
                     ITEM_TBL (i).ERROR_MESSAGE := 'Invalid Organization Name';
               END;
			   
			   
		-- TEMPLATE NAME --	   
		            
               BEGIN
                  SELECT TEMPLATE_ID
                  INTO ITEM_TBL (i).TEMPLATE_ID
                  FROM MTL_ITEM_TEMPLATES
                  WHERE UPPER (TEMPLATE_NAME) = UPPER (ITEM_TBL (i).TEMPLATE_NAME);
               EXCEPTION
                  WHEN OTHERS
                  THEN
                     ITEM_TBL (i).PROCESS_FLAG := 'E';
                     ITEM_TBL (i).ERROR_MESSAGE := 'INVALID TEMPLATE NAME ';
               END;
			  			   
			
      -- UPDATE VALUES ---


            UPDATE XXQGEN_ITEM_STG_AR
               SET PROCESS_FLAG = ITEM_TBL (i).PROCESS_FLAG,
                   ERROR_MESSAGE = ITEM_TBL (i).ERROR_MESSAGE,
                   ORGANIZATION_ID = ITEM_TBL (i).ORGANIZATION_ID,
                   TEMPLATE_ID = ITEM_TBL (i).TEMPLATE_ID
             WHERE 1=1
            AND REQUEST_ID = ITEM_TBL (i).REQUEST_ID ;
			
        END LOOP;
        COMMIT;
		EXCEPTION 
		WHEN OTHERS THEN
		fnd_file.put_line (fnd_file.LOG,'ERROR INSIDE VALIDATION LOOP'||SQLCODE||' '||SQLERRM ) ;	 
		END ;
		END LOOP;

      CLOSE CUR_ITEM;
	  


      
      EXCEPTION WHEN OTHERS 
      THEN 
            fnd_file.put_line (fnd_file.LOG,'ERROR IN VALIDATE DATA '||SQLCODE||' '||SQLERRM ) ;
      
    END VALIDATE_DATA;