PACKAGE BODY xxfil_upload_file_pkg IS
  g_enc CONSTANT VARCHAR2(1) := '"';
  g_trm CONSTANT VARCHAR2(1) := ',';
  g_date_mask VARCHAR2(50) := 'MM/DD/YYYY';
  --g_date_mask VARCHAR2(50) := NVL(fnd_profile.VALUE('ICX_DATE_FORMAT_MASK'),'DD-MON-YYYY');
  e_unsupported_format EXCEPTION;
  g_batch_id NUMBER;
  g_org_id   NUMBER := fnd_profile.VALUE('ORG_ID');
  --
  FUNCTION convert_to_date(p_string VARCHAR2) RETURN DATE IS
    l_date DATE;
  BEGIN
    l_date := TO_DATE(p_string, g_date_mask);
    RETURN l_date;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;

  FUNCTION convert_to_number(p_string VARCHAR2) RETURN NUMBER IS
    l_num NUMBER;
  BEGIN
    l_num := REPLACE(p_string, ',');
    RETURN l_num;
  EXCEPTION
    WHEN OTHERS THEN
      RETURN NULL;
  END;
  --
  PROCEDURE submit_stmnt_recon_prg(p_bank_account_id IN NUMBER) IS
    --
    l_request_id NUMBER := 0;
    --
  BEGIN
    --
    -- Submit the loader program to upload records from data file
    l_request_id := fnd_request.submit_request('XXFIL',
                                               'XXFIL_BANK_STATEMENT_RECONCILE',
                                               NULL,
                                               NULL,
                                               FALSE,
                                               p_bank_account_id,
                                               g_batch_id);
  
    COMMIT;
    --
    UPDATE xxfil_bank_statement_stg
       SET request_id = l_request_id, status = 'P'
     WHERE batch_id = g_batch_id
       AND status != 'E';
    --
    :SYSTEM.message_level := 25;
    COMMIT;
    :SYSTEM.message_level := 0;
    --
    IF l_request_id = 0 THEN
      fnd_message.set_string('Error! Unable to submit request for FIL Bank Statement Reconciliation Program');
      fnd_message.show;
    ELSE
      fnd_message.set_string('Submitted Request ' || TO_CHAR(l_request_id) ||
                             ' for FIL Bank Statement Reconciliation Program');
      fnd_message.show;
    END IF;
  
    --
  EXCEPTION
    WHEN OTHERS THEN
      fnd_message.set_string('Unhandled exception in SUBMIT_STMNT_RECON_PRG ' ||
                             SQLERRM);
      fnd_message.show;
      RAISE;
  END submit_stmnt_recon_prg;

  PROCEDURE validate_records(p_bank_account_id IN NUMBER) IS
    --
    --Cursor to fetch distinct transaction dates from staging
    CURSOR get_trans_dt IS
      SELECT DISTINCT TO_DATE(transaction_date, 'DD-MM-RR') transaction_date
        FROM xxfil_bank_statement_stg
       WHERE status = 'N'
         AND UPPER(transaction_remarks) != 'OPENING BALANCE'
         AND batch_id = g_batch_id
       ORDER BY 1;
  
    lv_cnt NUMBER := 0;
  BEGIN
    --
    FOR l_rec IN get_trans_dt LOOP
      --
      lv_cnt := 0;
      --
      IF TRUNC(l_rec.transaction_date) >= TRUNC(SYSDATE) THEN
        --
        UPDATE xxfil_bank_statement_stg
           SET status        = 'E',
               error_message = 'Future date transactions can not be uploaded.'
         WHERE batch_id = g_batch_id
           AND TRUNC(TO_DATE(transaction_date, 'DD-MM-RR')) =
               TRUNC(l_rec.transaction_date);
        --
      ELSE
        --
        --Check if statement already uploaded
        SELECT COUNT(*)
          INTO lv_cnt
          FROM xxfil_bank_statement_stg
         WHERE TRUNC(TO_DATE(transaction_date, 'DD-MM-RR')) =
               TRUNC(l_rec.transaction_date)
           AND bank_account_id = p_bank_account_id
           AND status = 'S'
           AND batch_id != g_batch_id;
        --
        IF lv_cnt > 0 THEN
          --
          UPDATE xxfil_bank_statement_stg
             SET status        = 'E',
                 error_message = 'Transactions of this date already uploaded.'
           WHERE batch_id = g_batch_id
             AND TRUNC(TO_DATE(transaction_date, 'DD-MM-RR')) =
                 TRUNC(l_rec.transaction_date);
        END IF;
        --
      END IF;
      --
    END LOOP;
    --
    COMMIT;
    --
  EXCEPTION
    WHEN OTHERS THEN
      fnd_message.set_string('Unhandled exception in VALIDATE_RECORDS ' ||
                             SQLERRM);
      fnd_message.show;
      RAISE;
  END validate_records;

  --
  PROCEDURE csv_parser(p_string   VARCHAR2,
                       p_num_cols NUMBER DEFAULT 127,
                       o_data1    OUT VARCHAR2,
                       o_data2    OUT VARCHAR2,
                       o_data3    OUT VARCHAR2,
                       o_data4    OUT VARCHAR2,
                       o_data5    OUT VARCHAR2,
                       o_data6    OUT VARCHAR2,
                       o_data7    OUT VARCHAR2,
                       o_data8    OUT VARCHAR2) IS
    v_string      VARCHAR2(4000);
    v_cols        NUMBER := 1;
    v_enc_end     PLS_INTEGER;
    v_enc_counter PLS_INTEGER;
    v_trm_end     PLS_INTEGER;
    v_val_start   PLS_INTEGER;
    v_val_end     PLS_INTEGER;
    v_value       VARCHAR2(2000);
  BEGIN
    v_string := p_string;
  
    WHILE LENGTH(v_string) > 0 LOOP
      IF SUBSTR(v_string, 1, 1) = g_enc THEN
        v_enc_counter := 1;
        v_enc_end     := INSTR(v_string, g_enc, v_enc_counter + 1);
      
        IF v_enc_end = LENGTH(v_string) THEN
          v_val_start := 2;
          v_val_end   := v_enc_end - 1;
          v_trm_end   := v_val_end + 1;
        ELSIF SUBSTR(v_string, v_enc_end + 1, 1) = g_trm THEN
          v_val_start := 2;
          v_val_end   := v_enc_end - 1;
          v_trm_end   := v_enc_end + 1;
        ELSE
          :control.MESSAGE := 'This loader cannot handle quoted strings yet';
          SYNCHRONIZE;
          RAISE form_trigger_failure;
        END IF;
      ELSE
        v_trm_end := INSTR(v_string, g_trm);
      
        IF v_trm_end = 0 THEN
          v_val_start := 1;
          v_val_end   := LENGTH(v_string);
          v_trm_end   := v_val_end + 1;
        ELSE
          v_val_start := 1;
          v_val_end   := v_trm_end - 1;
        END IF;
      END IF;
    
      v_value := SUBSTR(v_string, v_val_start, v_val_end - v_val_start + 1);
    
      IF v_cols = 1 THEN
        o_data1 := v_value;
      ELSIF v_cols = 2 THEN
        o_data2 := v_value;
      ELSIF v_cols = 3 THEN
        o_data3 := v_value;
      ELSIF v_cols = 4 THEN
        o_data4 := v_value;
      ELSIF v_cols = 5 THEN
        o_data5 := v_value;
      ELSIF v_cols = 6 THEN
        o_data6 := v_value;
      ELSIF v_cols = 7 THEN
        o_data7 := v_value;
      ELSIF v_cols = 8 THEN
        o_data8 := v_value;
      END IF;
    
      v_cols := v_cols + 1;
    
      IF v_trm_end + 1 > LENGTH(v_string) THEN
        EXIT;
      ELSE
        v_string := SUBSTR(v_string, v_trm_end + 1);
      END IF;
    
      IF v_cols > p_num_cols THEN
        EXIT;
      END IF;
    END LOOP;
  END csv_parser;

  --
  PROCEDURE upload IS
    button_choice NUMBER;
    access_id     NUMBER;
    l_server_url  VARCHAR2(255);
    l_web_agent   VARCHAR2(240);
    l_gfm_id      NUMBER := NULL;
    l_parameters  VARCHAR2(255);
    l_message     VARCHAR2(2000);
    blobdata      BLOB;
    l_org_id      NUMBER := fnd_profile.VALUE('ORG_ID');
    v_filehandle  UTL_FILE.file_type;
    v_newline     VARCHAR2(5000);
    l_filename    VARCHAR2(500);
    l_data1_raw   VARCHAR2(2000);
    l_data2_raw   VARCHAR2(2000);
    l_data3_raw   VARCHAR2(2000);
    l_data4_raw   VARCHAR2(2000);
    l_data5_raw   VARCHAR2(2000);
    l_data6_raw   VARCHAR2(2000);
    l_data7_raw   VARCHAR2(2000);
    l_data8_raw   VARCHAR2(2000);
    l_data9_raw   VARCHAR2(2000);
    l_data10_raw  VARCHAR2(2000);
    l_count       NUMBER := 0;
    l_retcode     NUMBER;
    r_line        xxfil_bank_statement_stg%ROWTYPE;
    r_line_blank  xxfil_bank_statement_stg%ROWTYPE;
    e_error EXCEPTION;
    lv_file       VARCHAR2(100);
    l_valid_count NUMBER := 0;
    --
    l_skip_first_row NUMBER := 0;
  BEGIN
    :control.MESSAGE := NULL;
    GO_BLOCK('XXFIL_BANK_STATEMENT_STG');
  
    IF NOT FORM_SUCCESS THEN
      RAISE form_trigger_failure;
    END IF;
  
    CLEAR_BLOCK(no_validate);
  
    IF NOT FORM_SUCCESS THEN
      RAISE form_trigger_failure;
    END IF;
  
    access_id := fnd_gfm.authorize(NULL);
    fnd_profile.get('APPS_WEB_AGENT', l_server_url);
    l_parameters := 'access_id=' || access_id || '&l_server_url=' ||
                    l_server_url;
    fnd_function.EXECUTE(function_name => 'FND_FNDFLUPL',
                         open_flag     => 'Y',
                         session_flag  => 'Y',
                         other_params  => l_parameters);
    fnd_message.set_name('FND', 'ATCHMT-FILE-UPLOAD-COMPLETE');
    button_choice := fnd_message.question(button1     => 'YES',
                                          button2     => NULL,
                                          button3     => 'NO',
                                          default_btn => 1,
                                          cancel_btn  => 3,
                                          icon        => 'question');
  
    IF (button_choice = 3) THEN
      GO_ITEM('CONTROL.UPLOAD');
      RETURN;
    ELSIF (button_choice = 1) THEN
      app_window.progress(5);
      --
      BEGIN
        SELECT XXFIL_BANK_STATEMENT_BATCH_S.nextval
          INTO g_batch_id
          FROM dual;
      EXCEPTION
        WHEN OTHERS THEN
          NULL;
      END;
    
      :PARAMETER.p_batch_id := g_batch_id;
    
      /*DELETE FROM xxfil_bank_statement_stg
       WHERE request_id = g_request_id;
      
      :SYSTEM.message_level := 25;
      COMMIT;
      :SYSTEM.message_level := 0;*/
      l_gfm_id := fnd_gfm.get_file_id(access_id);
    
      IF l_gfm_id IS NOT NULL THEN
        lv_file := xxfil_write_blob_to_disk(l_gfm_id,
                                            'XXFIL_FILE_UPLOAD_DIR');
      ELSE
        l_message := 'Unable to upload data file';
        RAISE e_error;
      END IF;
    
      app_window.progress(10);
      l_message := 'Stage 1 Data File Upload';
      --  Open the specified file for reading. File created using BLOB
      v_filehandle := UTL_FILE.fopen('XXFIL_FILE_UPLOAD_DIR',
                                     lv_file, --'Bank_Factor_Spreadsheet.csv',
                                     'r');
      app_window.progress(15);
      l_message := 'Stage 2 Data File Opened';
    
      BEGIN
        --  Loop over the file, reading in each line. GET_LINE will raise
        --  NO_DATA_FOUND when it is done, so we use that as the exit condition
        --  for the loop
        LOOP
          --Reset all local variables
          l_data1_raw := NULL;
          l_data2_raw := NULL;
          l_data3_raw := NULL;
          l_data4_raw := NULL;
          l_data5_raw := NULL;
          l_data6_raw := NULL;
          l_data7_raw := NULL;
          l_data8_raw := NULL;
          r_line      := r_line_blank;
        
          BEGIN
            UTL_FILE.get_line(v_filehandle, v_newline);
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              EXIT;
          END;
          --
          l_message := 'Stage 3 Data Record Read';
          -- Remove the LIne feed from the Line (LINUX specific)
          v_newline := REPLACE(v_newline, CHR(13), '');
          csv_parser(p_string   => v_newline,
                     p_num_cols => 8,
                     o_data1    => l_data1_raw,
                     o_data2    => l_data2_raw,
                     o_data3    => l_data3_raw,
                     o_data4    => l_data4_raw,
                     o_data5    => l_data5_raw,
                     o_data6    => l_data6_raw,
                     o_data7    => l_data7_raw,
                     o_data8    => l_data8_raw);
          --
          l_message                  := 'Stage 5 Data Record Parsed';
          r_line.value_date          := SUBSTR(l_data1_raw, 1, 30);
          r_line.transaction_date    := SUBSTR(l_data2_raw, 1, 30);
          r_line.instrument_id       := SUBSTR(l_data3_raw, 1, 30);
          r_line.transaction_remarks := SUBSTR(l_data4_raw, 1, 2000);
          r_line.amount_dr           := SUBSTR(l_data5_raw, 1, 30);
          r_line.amount_cr           := SUBSTR(l_data6_raw, 1, 30);
          r_line.account_balance     := SUBSTR(l_data7_raw, 1, 30);
          r_line.transaction_ref_no  := SUBSTR(l_data8_raw, 1, 50);
        
          --
          IF (r_line.transaction_date IS NOT NULL) AND
             (l_skip_first_row != 0) THEN
            --
            INSERT INTO xxfil_bank_statement_stg
              (record_id,
               value_date,
               transaction_date,
               instrument_id,
               transaction_remarks,
               amount_dr,
               amount_cr,
               account_balance,
               transaction_ref_no,
               status,
               batch_id,
               BANK_ACCOUNT_ID,
               creation_date,
               created_by,
               last_update_date,
               last_updated_by)
              SELECT XXFIL_BANK_STATEMENT_STG_S.NEXTVAL,
                     TRIM(r_line.value_date),
                     TRIM(r_line.transaction_date),
                     TRIM(r_line.instrument_id),
                     TRIM(r_line.transaction_remarks),
                     TRIM(r_line.amount_dr),
                     TRIM(r_line.amount_cr),
                     TRIM(r_line.account_balance),
                     TRIM(r_line.transaction_ref_no),
                     'N',
                     g_batch_id,
                     :CONTROL.BANK_ACCOUNT_ID,
                     SYSDATE,
                     fnd_global.user_id,
                     SYSDATE,
                     fnd_global.user_id
                FROM DUAL;
          
            --
            l_count   := l_count + 1;
            l_message := 'Stage 6 Data Record Added';
          END IF; -- order number is not null
        
          --
          l_skip_first_row := l_skip_first_row + 1;
          --
        END LOOP;
      
        --
        UTL_FILE.fclose(v_filehandle);
        app_window.progress(80);
        l_message             := 'Stage 7 All Rows processed';
        :SYSTEM.message_level := 25;
        COMMIT;
        :SYSTEM.message_level := 0;
        --
      
        --Call procedure to validate records
        validate_records(:CONTROL.BANK_ACCOUNT_ID);
      
        SELECT COUNT(*)
          INTO l_valid_count
          FROM xxfil_bank_statement_stg
         WHERE status != 'E'
           AND batch_id = g_batch_id;
      
        IF l_valid_count > 0 THEN
          --Call procedure to submit FIL Bank Statement Reconciliation Program
          submit_stmnt_recon_prg(:CONTROL.BANK_ACCOUNT_ID);
          --
        END IF;
        --
        app_window.progress(90);
        l_message := 'Stage 8 Data Uploaded';
        l_message := 'Records in data = ' || TO_CHAR(l_count);
      
        SELECT COUNT(*)
          INTO l_count
          FROM xxfil_bank_statement_stg
         WHERE status = 'P'
           AND batch_id = g_batch_id;
      
        l_message := l_message || CHR(10) || 'Records processed = ' ||
                     TO_CHAR(l_count);
      
        SELECT COUNT(*)
          INTO l_count
          FROM xxfil_bank_statement_stg
         WHERE status = 'E'
           AND batch_id = g_batch_id;
      
        l_message := l_message || CHR(10) || 'Records rejected = ' ||
                     TO_CHAR(l_count);
        app_window.progress(100);
        --IF l_count > 0 THEN
        GO_BLOCK('XXFIL_BANK_STATEMENT_STG');
      
        IF NOT FORM_SUCCESS THEN
          RAISE form_trigger_failure;
        END IF;
      
        EXECUTE_QUERY;
      
        IF NOT FORM_SUCCESS THEN
          RAISE form_trigger_failure;
        END IF;
      
        --END IF;
        :control.MESSAGE := l_message;
        SYNCHRONIZE;
      END;
    END IF;
  EXCEPTION
    WHEN e_error THEN
      fnd_message.set_string('Processing Error - Last Stage was ' ||
                             l_message);
      fnd_message.show;
      RAISE form_trigger_failure;
    WHEN UTL_FILE.invalid_path THEN
      fnd_message.set_string(' FILE ERROR : Invalid PATH ');
      fnd_message.show;
      RAISE form_trigger_failure;
    WHEN UTL_FILE.invalid_mode THEN
      fnd_message.set_string(' FILE ERROR : Invalid MODE ');
      fnd_message.show;
      RAISE form_trigger_failure;
    WHEN UTL_FILE.invalid_operation THEN
      fnd_message.set_string(' FILE ERROR : Invalid Operation');
      fnd_message.show;
      RAISE form_trigger_failure;
    WHEN UTL_FILE.invalid_filehandle THEN
      UTL_FILE.fclose(v_filehandle);
      fnd_message.set_string(' FILE ERROR : Invalid FILE Handle ');
      fnd_message.show;
      RAISE form_trigger_failure;
    WHEN UTL_FILE.read_error THEN
      UTL_FILE.fclose(v_filehandle);
      fnd_message.set_string(' FILE ERROR : READ ERROR ');
      fnd_message.show;
      RAISE form_trigger_failure;
  END;
  --
END;