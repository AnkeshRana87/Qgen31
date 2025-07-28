CREATE OR REPLACE PACKAGE BODY XXFIL_BOM_BURSTING_PKG AS

  FUNCTION BeforeReport RETURN BOOLEAN IS  
  RETURN TRUE;
   END BeforeReport;

  FUNCTION AfterReport RETURN BOOLEAN IS 
    cp_conc_id NUMBER;
    cp_desc VARCHAR2(100);
    cp_request_id CONSTANT NUMBER := FND_PROFILE.VALUE('CONC_REQUEST_ID');   
  BEGIN            
    
    BEGIN
      SELECT USER_CONCURRENT_PROGRAM_NAME
      INTO cp_desc
      FROM
        FND_CONCURRENT_REQUESTS fcr,
        FND_CONCURRENT_PROGRAMS_VL fcp
      WHERE 1=1 
        AND fcr.CONCURRENT_PROGRAM_ID = fcp.CONCURRENT_PROGRAM_ID
        AND fcr.REQUEST_ID = cp_request_id; 
    EXCEPTION
      WHEN OTHERS THEN
        cp_desc := NULL;
    END;

    cp_conc_id := FND_REQUEST.SUBMIT_REQUEST(
      application => 'XDO',
      program     => 'XDOBURSTREP',
      description => cp_desc,
      start_time  => NULL,
      sub_request => FALSE,
      argument1   => 'Y',
      argument2   => cp_request_id,
      argument3   => 'Y'
    );

    COMMIT;

    IF cp_conc_id <= 0 THEN
      -- fnd_file.log('100','Failed to Submit Brusting Program for Request id'||cp_request_id);
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Failed to Submit Brusting Program for Request id'||cp_request_id);
    END IF;

    RETURN TRUE;

  EXCEPTION
    WHEN OTHERS THEN
      -- srw.message('1001','Failed in After Report Trigger'||SQLERRM); 
      FND_FILE.PUT_LINE(FND_FILE.LOG, 'Failed in After Report Trigger'||SQLERRM);
      RETURN FALSE;
  END AfterReport;

END XXFIL_BOM_BURSTING_PKG;
/
