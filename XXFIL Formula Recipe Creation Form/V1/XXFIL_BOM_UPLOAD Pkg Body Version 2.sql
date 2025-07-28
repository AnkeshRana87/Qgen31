PACKAGE BODY XXFIL_BOM_UPLOAD IS     
/*
    --procedure show data --
      
      PROCEDURE SHOW_DATA (P_BATCH_ID IN NUMBER)
      IS 
      CURSOR CUR_DATA IS 
      SELECT * FROM 
      XXFIL_BOM_STG
      WHERE BATCH_ID = P_BATCH_ID ;
      
      BEGIN
      	FOR REC IN  CUR_DATA
      	LOOP
						:XXFIL_BOM_UPLOAD_STG.PRODUCT := REC.PRODUCT;
						:XXFIL_BOM_UPLOAD_STG.RM_CODE := REC.RM_CODE;
						:XXFIL_BOM_UPLOAD_STG.RM_DESCRIPTION := REC.RM_DESCRIPTION;
						:XXFIL_BOM_UPLOAD_STG.VERSION := REC.VERSION;
						:XXFIL_BOM_UPLOAD_STG.QUANTITY := REC.QUANTITY;
						:XXFIL_BOM_UPLOAD_STG.AVG_SPEED := REC.AVG_SPEED;
						:XXFIL_BOM_UPLOAD_STG.WIDTH := REC.WIDTH;
						:XXFIL_BOM_UPLOAD_STG.STATUS := REC.STATUS;
						:XXFIL_BOM_UPLOAD_STG.INITIATER := REC.INITIATER;
						:XXFIL_BOM_UPLOAD_STG.APPROVER := REC.APPROVER;
						:XXFIL_BOM_UPLOAD_STG.BATCH_ID := REC.BATCH_ID;
						:XXFIL_BOM_UPLOAD_STG.REJECTION_REASON := REC.REJECTION_REASON;
						:XXFIL_BOM_UPLOAD_STG.REQUEST_ID := REC.REQUEST_ID;
      	END LOOP;
      	EXCEPTION WHEN OTHERS
      		THEN
      		FND_MESSAGE.SET_STRING('Error in show data '||sqlcode||sqlerrm);
      		fnd_message.show;
      END;
*/      
      

----- PROCEDURE UPLOAD_DATA -----
  
  PROCEDURE UPLOAD_DATA IS 
   access_id            NUMBER;
   l_parameters         VARCHAR2 (2000);
   l_server_url         VARCHAR2 (2000);
   l_gfm_id             NUMBER;
   lv_file              VARCHAR2 (100);
   l_message            VARCHAR2 (2000);
   e_error              EXCEPTION;
   button_choice        NUMBER;
      lc_approval_status  VARCHAR2 (100) := 'INCOMPLETE';
      ln_request_load     NUMBER;
      ln_interval         NUMBER := 5;
      ln_max_wait         NUMBER := 60;
      lc_phase            VARCHAR2 (3000);
      lc_status           VARCHAR2 (3000);
      lc_dev_phase        VARCHAR2 (3000);
      lc_dev_status       VARCHAR2 (3000);
      lc_message          VARCHAR2 (3000);
      lc_conc_status      BOOLEAN;
  
   BEGIN
   access_id := fnd_gfm.authorize (NULL);
   fnd_profile.get ('APPS_WEB_AGENT', l_server_url);  
   
   l_parameters :=
                'access_id=' || access_id || '&l_server_url=' || l_server_url;    

			begin          
   			fnd_function.EXECUTE (function_name      => 'FND_FNDFLUPL',
                         open_flag          => 'Y',
                         session_flag       => 'Y',
                         other_params       => l_parameters
                        );
				exception when others 
				then
   			fnd_message.set_string ('error in FND_FNDFLUPL '||sqlcode ||sqlerrm);
   			fnd_message.show;          
			end;
		
   -- fnd_message.set_name('FND', 'ATCHMT-FILE-UPLOAD-COMPLETE');    
   
   button_choice :=
      fnd_message.question (button1          => 'YES',
                            button2          => NULL,
                            button3          => 'NO',
                            default_btn      => 1,
                            cancel_btn       => 3,
                            icon             => 'question'
                           );             
                           
   fnd_message.set_string ('File Uploading');
   fnd_message.show;
   --IF (button_choice = 3) THEN
     --fnd_message.set_string('Cancelled :');
           --fnd_message.show;
     --RETURN;
   --ELSIF (button_choice = 1) THEN
--   app_window.progress (5);
   DBMS_LOCK.sleep (10);            
   
   l_gfm_id := fnd_gfm.get_file_id (access_id); 
   
   fnd_message.set_string ('File Id :' || l_gfm_id);
   fnd_message.show;

   --IF l_gfm_id IS NOT NULL THEN
   			BEGIN
      		lv_file := xxfil_write_blob_to_disk (l_gfm_id, 'XXFIL_FILE_UPLOAD_DIR');
   				EXCEPTION
      		WHEN OTHERS
      		THEN
         fnd_message.set_string (   'Error in xxfil_write_blob_to_disk : '
                                 || SQLCODE
                                 || '-'
                                 || SQLERRM
                                );
         fnd_message.show;
   			END;

			IF lv_file IS NOT NULL THEN 
   		fnd_message.set_string ('File Name : ' || lv_file);
   		fnd_message.show;
   
   		:CONTROL.FILE_NAME := lv_file;
   		END IF;
		
   --   ELSE
        --l_message := 'Unable to upload data file';
       -- RAISE e_error;
      --END IF;
   --app_window.progress (10);
   --l_message := 'Stage 1 Data File Upload';

   BEGIN
      fnd_global.apps_initialize (gn_user_id, gn_resp_id, gn_resp_appl_id);
      fnd_request.set_org_id (gn_org_id);
    
      ln_request_load :=
         fnd_request.submit_request (application      => 'XXFIL',
                                     program          => 'XXFIL_BOM_LOAD',
                                     argument1        => NULL
                                    );
      COMMIT;

      IF ln_request_load = 0
      THEN                        
         
   		fnd_message.set_string ('DATA NOT SUBMITTED '||ln_request_load);
   		fnd_message.show;
      
      ELSIF ln_request_load > 0
      THEN
         LOOP
            lc_conc_status :=
               fnd_concurrent.wait_for_request (request_id      => ln_request_load,
                                                INTERVAL        => ln_interval,
                                                max_wait        => ln_max_wait,
                                                phase           => lc_phase,
                                                status          => lc_status,
                                                dev_phase       => lc_dev_phase,
                                                dev_status      => lc_dev_status,
                                                MESSAGE         => lc_message
                                               );
            EXIT WHEN UPPER (lc_phase) = 'COMPLETED'
                  OR UPPER (lc_status) IN
                                         ('CANCELLED', 'ERROR', 'TERMINATED');
         END LOOP;

         fnd_message.set_string (ln_request_load||' : '||lc_phase||' , '||lc_status);
   				fnd_message.show;
  
     END IF;
      
      	BEGIN 	
      		SELECT USER_NAME,NVL(email_address,'notification@flexfilm.com')  
      		INTO LC_USER,LC_USER_MAIL
      		FROM FND_USER 
					WHERE 1=1
					AND USER_ID = gn_user_id ;
					
					EXCEPTION WHEN OTHERS THEN	
					fnd_message.set_string (   'ERROR IN FETCHING USER '
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      		fnd_message.show;
				END;
					
				BEGIN
					 SELECT 
           NVL(PAPF2.FULL_NAME,'Ankesh Rana') 
           ,NVL(PAPF2.EMAIL_ADDRESS,'arana@quadragensolutions.com') INTO LC_SUPERVISOR ,LC_SUPERVISOR_MAIL
           FROM FND_USER FU 
           ,PER_ALL_PEOPLE_F PAPF
					 ,PER_ALL_ASSIGNMENTS_F PAAF 
           ,PER_ALL_PEOPLE_F PAPF2
					WHERE 1=1
					AND FU.EMPLOYEE_ID = PAPF.PERSON_ID 
					AND PAPF.PERSON_ID = PAAF.PERSON_ID      
        	AND PAAF.SUPERVISOR_ID = PAPF2.PERSON_ID(+)
					AND SYSDATE BETWEEN PAAF.EFFECTIVE_START_DATE AND NVL(PAAF.EFFECTIVE_END_DATE, SYSDATE+1)
					AND (PAPF.CURRENT_EMPLOYEE_FLAG = 'Y' OR PAPF.CURRENT_NPW_FLAG = 'Y')
					AND SYSDATE BETWEEN PAPF.EFFECTIVE_START_DATE AND NVL(PAPF.EFFECTIVE_END_DATE, SYSDATE+1)
					AND USER_ID = gn_user_id; 
						      	
					EXCEPTION WHEN OTHERS 
      		THEN
      		fnd_message.set_string (   'ERROR IN FETCHING USER '
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      		fnd_message.show;
      	END ; 
      
      
      UPDATE xxfil_bom_stg
         SET batch_id = ln_request_load,
             created_by = gn_user_id,
             creation_date = SYSDATE,
             last_update_date = SYSDATE,
             last_updated_by = gn_user_id,
             initiater = LC_USER,
             status = 'NEW',
             APPROVER = LC_SUPERVISOR
       WHERE status IS NULL AND batch_id IS NULL ;

      COMMIT;
      
      
      if ln_request_load > 0 then
     go_block('XXFIL_BOM_UPLOAD_STG');
     --PROCEDURE WITH NEW DATA 
     --SHOW_DATA(ln_request_load);
		 SET_BLOCK_PROPERTY('XXFIL_BOM_UPLOAD_STG',DEFAULT_WHERE,'BATCH_ID ='||ln_request_load);
		 CLEAR_BLOCK(NO_VALIDATE);
		 execute_query;
		 end if;
		 
   		EXCEPTION
      WHEN OTHERS
      THEN
               fnd_message.set_string (   'ERROR IN DATA LOAD PROGRAM '
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      fnd_message.show;
   		END;        
   
   
		EXCEPTION
   	WHEN OTHERS
   	THEN
      fnd_message.set_string ('Unhandeled exception in UPLOAD_DATA procedure'
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      fnd_message.show;
      
	END UPLOAD_DATA; --PROCEDURE UPLOAD_DATA END
  
  
  -- ******** PROCEDURE MAIL FOR APPROVAL ********************
  
  
PROCEDURE MAIL_TO_APPROVER IS

      lc_approval_status  VARCHAR2 (100) := 'INCOMPLETE';
      ln_request          NUMBER;
      ln_interval         NUMBER := 1;
      ln_max_wait         NUMBER := 60;
      lc_phase            VARCHAR2 (3000);
      lc_status           VARCHAR2 (3000);
      lc_dev_phase        VARCHAR2 (3000);
      lc_dev_status       VARCHAR2 (3000);
      lc_message          VARCHAR2 (3000);
      lc_conc_status      BOOLEAN;  
      lv_layout BOOLEAN;

   BEGIN
      fnd_global.apps_initialize (gn_user_id, gn_resp_id, gn_resp_appl_id);
      fnd_request.set_org_id (gn_org_id);
   
/*
   begin   
	 lv_layout := fnd_request.add_layout(
   template_appl_name => 'XXFIL',
   template_code      => 'XXFIL_BOM_APPROVAL_XLS',
   template_language  => 'en',
   template_territory => NULL,
   output_format      => 'EXCEL'
);

   commit;
   end;
  */
   
      ln_request :=
         fnd_request.submit_request (application      => 'XXFIL',
                                     program          => 'XXFIL_BOM_APPROVAL',
                                     argument1        => 'NEW',
                                     argument2				=>  NULL,
                                     argument3				=>  LC_SUPERVISOR_MAIL,
                                     argument4				=>  :XXFIL_BOM_UPLOAD_STG.batch_id
                                    );
     COMMIT;

      IF ln_request = 0
      THEN
       fnd_message.set_string ('XXFIL_BOM_APPROVAL PROGRAM NOT SUBMITTED');
       fnd_message.show;

      ELSIF ln_request > 0
      THEN
      --fnd_message.set_string ('Request ID : '||ln_request);
      --fnd_message.show;

         LOOP
            lc_conc_status :=
               fnd_concurrent.wait_for_request (request_id      => ln_request,
                                                INTERVAL        => ln_interval,
                                                max_wait        => ln_max_wait,
                                                phase           => lc_phase,
                                                status          => lc_status,
                                                dev_phase       => lc_dev_phase,
                                                dev_status      => lc_dev_status,
                                                MESSAGE         => lc_message
                                               );
            EXIT WHEN UPPER (lc_phase) = 'COMPLETED'
                  OR UPPER (lc_status) IN
                                         ('CANCELLED', 'ERROR', 'TERMINATED');
         END LOOP;
         
      fnd_message.set_string ('Nofification sent to Supervisor');
      fnd_message.show;
         

      END IF;
      
      
   EXCEPTION
      WHEN OTHERS
      THEN
      fnd_message.set_string (   'Unhandeled exception '
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      fnd_message.show;   
           
   END MAIL_TO_APPROVER; -- end procedure (MAIL_TO_APPROVER)
  
  
  -- ****************************PROCEDURE  APPROVE BUTTON ************************
  
  
  PROCEDURE APPROVE_BUTTON IS

  button_choice       NUMBER;
  lc_approval_status  VARCHAR2(100) := 'INCOMPLETE';
  ln_formula_request          NUMBER;
  ln_interval         NUMBER := 1;
  ln_max_wait         NUMBER := 60;
  lc_phase            VARCHAR2(3000);
  lc_status           VARCHAR2(3000);
  lc_dev_phase        VARCHAR2(3000);
  lc_dev_status       VARCHAR2(3000);
  lc_message          VARCHAR2(3000);
  lc_conc_status      BOOLEAN;
	ln_request_approved NUMBER;
BEGIN

    fnd_message.set_string('Are you sure, You want to Approve.');

  button_choice :=
      fnd_message.question (button1     => 'YES',
                            button2     => NULL,
                            button3     => 'NO',
                            default_btn => 1,
                            cancel_btn  => 3,
                            icon        => 'question');
    
  IF (button_choice = 3) THEN
    RETURN;

  ELSIF (button_choice = 1) THEN 
  BEGIN

  	UPDATE XXFIL_BOM_STG
  	SET STATUS = 'APPROVED',
  	LAST_UPDATE_DATE = SYSDATE,
  	LAST_UPDATED_BY = gn_user_id
  	WHERE BATCH_ID = :XXFIL_BOM_UPLOAD_STG.BATCH_ID ; 
  	
  	COMMIT;

    
      -- Initialize apps 
      fnd_global.apps_initialize(gn_user_id, gn_resp_id, gn_resp_appl_id);
      fnd_request.set_org_id(gn_org_id);

      -- Submit Formula Creation concurrent Program
      ln_formula_request := fnd_request.submit_request(
                      application => 'XXFIL',
                      program     => 'XXFIL_BOM_FORMULA',
                      argument1   => :XXFIL_BOM_UPLOAD_STG.BATCH_ID
                    );

      COMMIT;

      IF ln_formula_request = 0 THEN
        fnd_message.set_string('XXFIL_BOM_FORMULA program not submitted.');
        fnd_message.show;

      ELSE
        fnd_message.set_string('Request submitted with ID: ' || ln_formula_request);
        fnd_message.show;

        LOOP
          lc_conc_status := fnd_concurrent.wait_for_request(
                              request_id => ln_formula_request,
                              interval   => ln_interval,
                              max_wait   => ln_max_wait,
                              phase      => lc_phase,
                              status     => lc_status,
                              dev_phase  => lc_dev_phase,
                              dev_status => lc_dev_status,
                              message    => lc_message
                            );

          EXIT WHEN UPPER(lc_phase) = 'COMPLETED' 
              OR UPPER(lc_status) IN ('CANCELLED', 'ERROR', 'TERMINATED');
        END LOOP;
        
				--:XXFIL_BOM_UPLOAD_STG.REQUEST_ID := ln_formula_request ;
				
        fnd_message.set_string('Program Status: ' || lc_phase || ' , ' || lc_status);
        fnd_message.show;
        
        --	:XXFIL_BOM_UPLOAD_STG.STATUS := upper(lc_status) ;
        
          	UPDATE XXFIL_BOM_STG
  					SET STATUS = upper('APPROVED'),
  					REQUEST_ID = ln_formula_request,
  					LAST_UPDATE_DATE = SYSDATE,
  					LAST_UPDATED_BY = gn_user_id
  					WHERE	BATCH_ID = :XXFIL_BOM_UPLOAD_STG.BATCH_ID 
  					AND STATUS != 'FAILED' ;
  	
  				COMMIT;
  				
        	GO_BLOCK('XXFIL_BOM_UPLOAD_STG');
        	SET_BLOCK_PROPERTY('XXFIL_BOM_UPLOAD_STG',DEFAULT_WHERE,'BATCH_ID ='||:XXFIL_BOM_UPLOAD_STG.BATCH_ID);
		 			CLEAR_BLOCK(NO_VALIDATE);
		 			execute_query;
					
					--EXECUTE_QUERY;
					
					
			BEGIN	
      		SELECT USER_NAME,NVL(email_address,'notification@flexfilm.com')  
      		INTO LC_USER,LC_USER_MAIL
      		FROM FND_USER 
					WHERE 1=1
					AND USER_ID = gn_user_id ;
					
				EXCEPTION WHEN OTHERS THEN	
				fnd_message.set_string (   'ERROR IN FETCHING USER '
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      	fnd_message.show;
			END;
					
			BEGIN
					 SELECT 
           NVL(PAPF2.FULL_NAME,'Ankesh Rana') 
           ,NVL(PAPF2.EMAIL_ADDRESS,'arana@quadragensolutions.com') INTO LC_SUPERVISOR ,LC_SUPERVISOR_MAIL
           FROM FND_USER FU 
           ,PER_ALL_PEOPLE_F PAPF
					 ,PER_ALL_ASSIGNMENTS_F PAAF 
           ,PER_ALL_PEOPLE_F PAPF2
					WHERE 1=1
				AND FU.EMPLOYEE_ID = PAPF.PERSON_ID 
				AND PAPF.PERSON_ID = PAAF.PERSON_ID      
        AND PAAF.SUPERVISOR_ID = PAPF2.PERSON_ID(+)
				AND SYSDATE BETWEEN PAAF.EFFECTIVE_START_DATE AND NVL(PAAF.EFFECTIVE_END_DATE, SYSDATE+1)
				AND (PAPF.CURRENT_EMPLOYEE_FLAG = 'Y' OR PAPF.CURRENT_NPW_FLAG = 'Y')
				AND SYSDATE BETWEEN PAPF.EFFECTIVE_START_DATE AND NVL(PAPF.EFFECTIVE_END_DATE, SYSDATE+1)
				AND USER_ID = gn_user_id; 
						      	
				EXCEPTION WHEN OTHERS 
      	THEN
      	fnd_message.set_string (   'ERROR IN FETCHING USER '
                              || SQLCODE
                              || '-'
                              || SQLERRM
                             );
      	fnd_message.show;
      END ; 
     
					
				---- Sending mail to Initiater that records approved successfully ---
				
				BEGIN	
				ln_request_approved :=
        fnd_request.submit_request (application      => 'XXFIL',
                                     program          => 'XXFIL_BOM_APPROVAL',
                                     argument1        => 'APPROVED',
                                     argument2        => LC_SUPERVISOR_MAIL,
                                     argument3        => 'ankeshrana821@gmail.com',
                                     argument4        => :XXFIL_BOM_UPLOAD_STG.BATCH_ID
                                    );
     		COMMIT;

      	IF ln_request_approved = 0
      	THEN
       	fnd_message.set_string ('XXFIL_BOM_APPROVAL PROGRAM FAILED ');
       	fnd_message.show;

      	ELSIF ln_request_approved > 0
      	THEN

        LOOP
            lc_conc_status :=
               fnd_concurrent.wait_for_request (request_id      => ln_request_approved,
                                                INTERVAL        => ln_interval,
                                                max_wait        => ln_max_wait,
                                                phase           => lc_phase,
                                                status          => lc_status,
                                                dev_phase       => lc_dev_phase,
                                                dev_status      => lc_dev_status,
                                                MESSAGE         => lc_message
                                               );
         EXIT WHEN UPPER (lc_phase) = 'COMPLETED'
         OR UPPER (lc_status) IN
         ('CANCELLED', 'ERROR', 'TERMINATED');
         END LOOP;
         
      	fnd_message.set_string ('Approved Nofification sent to '||gn_user_name);
      	fnd_message.show;
      	END IF;
      	END;
					
				--- 
					
      END IF;
      

    EXCEPTION
      WHEN OTHERS THEN
        fnd_message.set_string('Unhandled exception: ' || SQLCODE || ' - ' || SQLERRM);
        fnd_message.show;
    END; 
  END IF;
END APPROVE_BUTTON; -- END PROCEDURE APPROVE_BUTTON



-- ******************** PROCEDURE REJECT BUTTON ********************

PROCEDURE REJECT_BUTTON IS
  button_choice NUMBER;
  l_reason varchar2(2000);
BEGIN

    fnd_message.set_string('Are you sure, You want to Reject.');

  	button_choice :=
      fnd_message.question (button1     => 'YES',
                            button2     => NULL,
                            button3     => 'NO',
                            default_btn => 1,
                            cancel_btn  => 3,
                            icon        => 'question');

  IF (button_choice = 3) THEN
    RETURN;

  ELSIF (button_choice = 1) THEN 
  SHOW_VIEW('XXREJECTIONREASON');  
  GO_BLOCK('XXREJECTIONREASON');
  --GO_ITEM('XXREJECTIONREASON.REASON'); 
  
  END IF;
END REJECT_BUTTON; --END PROCEDURE REJECT_BUTTON

END XXFIL_BOM_UPLOAD ; -- MAIN END 