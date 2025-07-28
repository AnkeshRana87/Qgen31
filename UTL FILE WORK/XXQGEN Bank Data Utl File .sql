/* Formatted on 4/10/2025 12:52:36 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY XXQGEN_UTL_CB_AR
AS

--######################################################################################

PROCEDURE BOC 
 IS
    l_file         UTL_FILE.file_type;
    l_location     VARCHAR2(100) := 'XXQGEN_COMBINED_DIR';
    l_filename     VARCHAR2(100);
    V_Request_Id   VARCHAR2(100) := Fnd_Profile.Value('CONC_REQUEST_ID');
    
    CURSOR CUR_BOC IS
        SELECT 
       ce.bank_account_num payer_bank_account_number
      ,ieba.bank_account_num payee_bank_account_number
      ,ieba.bank_account_name payee_bank_account_name
--    ,ieba.branch_number payee_branch_number
      ,ieba.branch_name payee_bank_branch
      ,ieba.BANK_NUMBER payee_bank_number
      ,null clearing_bank_number
      ,to_char('单位') type_of_payee
      ,aca.amount
      ,null paid_account_number
      ,ipa.PAYMENT_DATE specify_a_payment_date
      ,null purpose
      ,null customers_bus
      ,null payee_email
--       , aca.check_number
--      ,aca.currency_code
--      ,ce.bank_account_name payer_account_name
--      ,ieba.bank_name payee_bank_name
FROM ap_checks_all aca
    ,iby_payments_all ipa
    ,ce_bank_accounts ce
    ,iby_payee_all_bankacct_v ieba
WHERE     1 = 1
      AND aca.external_bank_account_id = ieba.ext_bank_account_id
      AND ipa.internal_bank_account_id = ce.bank_account_id
      AND aca.payment_id = ipa.payment_id
      AND aca.check_id = 91735;

    
BEGIN
    l_filename := 'XXQGN_BOC_AR_' || V_Request_Id || '.txt';
    l_file := UTL_FILE.fopen(l_location, l_filename, 'w');
    
    
    UTL_FILE.put_line(l_file,
        'payer_bank_account_number'|| 
        'payee_bank_account_number'|| 
        'PAYEE_BANK_ACCOUNT_NAME'||
        'payee_bank_branch'||  
        'payee_bank_number'|| 
        'clearing_bank_number'|| 
        'type_of_payee'|| 
        'amount'|| 
        'paid_account_number'|| 
        'specify_a_payment_date'|| 
        'purpose'||
		'customers_bus'||
		'payee_email'
		);
    
    FOR REC_BOC IN CUR_BOC
    LOOP
        UTL_FILE.put_line(l_file,
            RPAD(REC_BOC.payer_bank_account_number,35,' ') ||
            RPAD(REC_BOC.payee_bank_account_number,32,' ') ||
            RPAD(REC_BOC.PAYEE_BANK_ACCOUNT_NAME,120,' ') ||
            RPAD(REC_BOC.payee_bank_branch,70,' ') ||
            RPAD(REC_BOC.payee_bank_number,12,' ') ||
            RPAD(REC_BOC.clearing_bank_number,12,' ') ||
            RPAD(REC_BOC.type_of_payee,20,' ') ||
            RPAD(NVL(REC_BOC.amount,15,' ') ||
            RPAD(NVL(REC_BOC.paid_account_number,35,' ') ||
            RPAD(REC_BOC.specify_a_payment_date,12,' ') ||
            RPAD(REC_BOC.purpose,200,' ')||
			RPAD(REC_BOC.customers_bus,16,' ') ||
            RPAD(REC_BOC.payee_email,40,' ')
			);
    END LOOP;
    
    UTL_FILE.fclose(l_file);
	fnd_file.put_line(fnd_file.LOG,'Successfully Outbond'||l_filename)

    
EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.is_open(l_file) THEN
            UTL_FILE.fclose(l_file);
        END IF;
        
END BOC;



--######################################################################################

PROCEDURE CIB 
 IS
    l_file         UTL_FILE.file_type;
    l_location     VARCHAR2(100) := 'XXQGEN_COMBINED_DIR';
    l_filename     VARCHAR2(100);
    V_Request_Id   VARCHAR2(100) := Fnd_Profile.Value('CONC_REQUEST_ID');
    
    CURSOR CUR_CIB IS
        SELECT DISTINCT 
               aca.check_number,
               aca.check_id,
               aca.currency_code,
               aca.amount,
               (CASE WHEN substr(ce.bank_account_num,1,3) = substr(ieba.bank_account_num,1,3)
                    THEN 1
                    ELSE 0
                END) AS Internal_bank_transfer,
               ce.bank_account_name payer_account_name,
               ce.bank_account_num payer_account_number,
               ieba.bank_account_num payee_bank_account_number,
               ieba.bank_account_name payee_bank_account_name,
               ieba.bank_name payee_bank_name,
               ieba.branch_number payee_branch_number,
               aca.city vendor_city,
               '供应商付款' AS Purpose,
               NULL AS NOTE,
               (CASE WHEN aca.amount >= 50000 
                     THEN '否'
                     WHEN aca.amount < 50000
                     THEN '是'
                END) AS Emergency
        FROM ap_checks_all aca,
             iby_payments_all ipa,
             ce_bank_accounts ce,
             iby_payee_all_bankacct_v ieba
        WHERE 1 = 1
          AND aca.external_bank_account_id = ieba.ext_bank_account_id
          AND ipa.internal_bank_account_id = ce.bank_account_id
          AND aca.payment_id = ipa.payment_id
          AND aca.check_id > 91736;

    
BEGIN
    l_filename := 'XXQGN_CIB_AR_' || V_Request_Id || '.txt';
    l_file := UTL_FILE.fopen(l_location, l_filename, 'w');
    
    
    UTL_FILE.put_line(l_file,
        RPAD('PAYER_BANK_ACCOUNT_NUMBER', 28) || 
        RPAD('INTERNAL_BANK_TRANSFER', 25) || 
        RPAD('PAYEE_BANK_ACCOUNT_NUMBER', 30) || 
        RPAD('PAYEE_BANK_ACCOUNT_NAME', 45) ||
        RPAD('PAYEE_BRANCH_NUMBER', 25) ||  
        RPAD('VENDOR_CITY', 20) || 
        RPAD('AMOUNT', 15) || 
        RPAD('PURPOSE', 20) || 
        RPAD('NOTE', 15) || 
        RPAD('EMERGENCY', 15) || 
        RPAD('E-MAIL', 12) || 
        RPAD('VENDOR_BANK_NUMBER', 15));
    
		FOR REC_CIB IN CUR_CIB;
		LOOP
        UTL_FILE.put_line(l_file,
            RPAD(NVL(r_payment_data.payer_account_number, ' '), 28) ||
            RPAD(NVL(TO_CHAR(r_payment_data.Internal_bank_transfer), ' '), 25) ||
            RPAD(NVL(r_payment_data.payee_bank_account_number, ' '), 30) ||
            RPAD(NVL(r_payment_data.payee_bank_account_name, ' '), 45) ||
            RPAD(NVL(r_payment_data.payee_branch_number, ' '), 25) ||
            RPAD(NVL(r_payment_data.vendor_city, ' '), 20) ||
            RPAD(NVL(TO_CHAR(r_payment_data.amount), ' '), 15) ||
            RPAD(NVL(r_payment_data.Purpose, ' '), 20) ||
            RPAD(NVL(r_payment_data.NOTE, ' '), 15) ||
            RPAD(NVL(r_payment_data.Emergency, ' '), 15) ||
            RPAD(' ', 12) ||
            RPAD(' ', 15));
		END LOOP;
    
    UTL_FILE.fclose(l_file);

    
EXCEPTION
    WHEN OTHERS THEN
        IF UTL_FILE.is_open(l_file) THEN UTL_FILE.fclose(l_file);
        END IF;
        
END CIB;

  
--###################################################################################

 PROCEDURE CITI_BANK
   AS
      l_file         UTL_FILE.file_type;
      V_REQUEST_ID   VARCHAR2 (100) := FND_PROFILE.VALUE ('CONC_REQUEST_ID');
      l_location     VARCHAR2 (100) := 'XXQGEN_COMBINED_DIR';
      l_filename     VARCHAR2 (100);

      CURSOR CUR_CITI_BANK
      IS
         SELECT DECODE (aca.currency_code, 'VND', 'DFT', 'EFT') paycode,
                aca.check_date value_date,
                asup.vendor_name transaction_ref,
                SUBSTR (ieba.BANK_ACCOUNT_NAME, 1, 60) BenName,
                SUBSTR (ieba.BANK_ACCOUNT_NAME, 61, 35) BenAdd,
                aca.amount,
                aca.currency_code ccy,
                ieba.bank_account_num BenAcct,
                CASE
                   WHEN aca.currency_code <> 'VND' THEN bb.eft_swift_code
                   ELSE ''
                END
                   bencode,
                SUBSTR (IEBA.BRANCH_NAME, 1, 35) ben_bank_name,
                SUBSTR (IEBA.BRANCH_NAME, 36, 53) ben_bank_add,
                ce.bank_account_num funding_account_number,
                TO_CHAR (
                   'Pmt : ' || aila.description || ' of ' || aia.invoice_num)
                   payment_details,
                TO_CHAR ('OUR') charge,
                TO_CHAR ('COHERENT VIETNAM (DONG NAI) CO LTD')
                   ordering_party_name,
                NULL confidential
           --      ,aia.invoice_id
           --      ,aila.line_number
           --      ,ieba.bank_name ben_bank_name
           --      ,aca.check_number
           --      ,ieba.bank_account_name ben_bank_account_name
           --      ,IEBA.BANK_NUMBER ben_bank_number
           --      ,ieba.branch_number ben_branch_number
           FROM ap_checks_all aca,
                iby_payments_all ipa,
                ce_bank_accounts ce,
                cefv_bank_branches bb,
                iby_payee_all_bankacct_v ieba,
                ap_suppliers asup,
                ap_invoices_all aia,
                ap_invoice_lines_all aila,
                ap_invoice_payments_all aipa
          WHERE     1 = 1
                AND aca.vendor_id = asup.vendor_id
                AND aca.external_bank_account_id = ieba.ext_bank_account_id
                AND ce.bank_branch_id = bb.bank_branch_id
                AND ipa.internal_bank_account_id = ce.bank_account_id
                AND aca.payment_id = ipa.payment_id
                AND aia.invoice_id = aila.invoice_id
                AND aia.invoice_id = aipa.invoice_id
                AND aca.check_id = aipa.check_id
                AND aca.check_id = 91735;
   BEGIN
      l_filename := 'XXQGEN_CITI_BANK_AR' || '_' || V_REQUEST_ID || '.txt';

      l_file := UTL_FILE.fopen (l_location, l_filename, 'w');

      UTL_FILE.put_line (
         l_file,
            'Paycode'
         || ','
         || 'Value_date'
         || ','
         || 'Transaction_Ref'
         || ','
         || 'BenName'
         || ','
         || 'BenAdd'
         || ','
         || 'amount'
         || ','
         || 'ccy'
         || ','
         || 'BenAcct'
         || ','
         || 'bencode'
         || ','
         || 'ben_bank_name'
         || ','
         || 'ben_bank_add'
         || ','
         || 'funding_account_number'
         || ','
         || 'payment_details'
         || ','
         || 'charge'
         || ','
         || 'ordering_party_name');

      FOR REC_CB IN CUR_CITI_BANK
      LOOP
         UTL_FILE.put_line (
            l_file,
               RPAD (REC_CB.Paycode, 3, ' ')
            || ','
            || RPAD (REC_CB.Value_date, 8, ' ')
            || ','
            || RPAD (REC_CB.Transaction_Ref, 15, ' ')
            || ','
            || RPAD (REC_CB.BenName, 60, ' ')
            || ','
            || RPAD (REC_CB.BenAdd, 35, ' ')
            || ','
            || RPAD (REC_CB.amount, 21, ' ')
            || ','
            || RPAD (REC_CB.ccy, 3, ' ')
            || ','
            || RPAD (REC_CB.BenAcct, 34, ' ')
            || ','
            || RPAD (REC_CB.bencode, 11, ' ')
            || ','
            || RPAD (REC_CB.ben_bank_name, 35, ' ')
            || ','
            || RPAD (REC_CB.ben_bank_add, 35, ' ')
            || ','
            || RPAD (REC_CB.funding_account_number, 34, ' ')
            || ','
            || RPAD (REC_CB.payment_details, 35, ' ')
            || ','
            || RPAD (REC_CB.charge, 3, ' ')
            || ','
            || RPAD (REC_CB.ordering_party_name, 35, ' '));
      END LOOP;

      UTL_FILE.fclose (l_file);

      fnd_file.put_line (
         fnd_file.LOG,
         'Successfully Outbond into file' || ' ' || l_filename);
   
   EXCEPTION
      WHEN OTHERS
      THEN
        IF UTL_FILE.is_open(l_file) 
		THEN UTL_FILE.fclose(l_file);
   END CITI_BANK;
   
  
 PROCEDURE MAIN(ERRBUF OUT VARCHAR2,RETCODE OUT VARCHAR2,P_BANK VARCHAR2)
   AS
   
   BEGIN
   
   IF P_BANK = 'CITI_BANK' THEN 
   CITI_BANK;
   END IF ;
   
   IF P_BANK = 'CIB' THEN
   CIB;
   END IF;
   
   IF P_BANK = 'BOC' THEN
   BOC;
   END IF;
   
   EXCEPTION 
   WHEN OTHERS THEN
   FND_FILE.PUT_LINE(FND_FILE.LOG,'ERROR IN MAIN');
   END MAIN;

END XXQGEN_UTL_CB_AR;