/* Formatted on 4/15/2025 2:39:25 PM (QP5 v5.163.1008.3004) */
CREATE OR REPLACE PACKAGE BODY APPS.XXQGEN_OUTBOND_AR
AS
   CURSOR CUR_CITI_BANK
   IS
      SELECT 
             DECODE (aca.currency_code, 'VND', 'DFT', 'EFT') paycode,
             TO_CHAR (aca.check_date, 'YYYYMMDD') value_date,
             asup.vendor_name transaction_ref,
             SUBSTR (ieba.BANK_ACCOUNT_NAME, 1, 60) BenName,
             SUBSTR (ieba.BANK_ACCOUNT_NAME, 61, 35) BenAdd,
             aca.amount,
             aca.currency_code ccy,
             ieba.bank_account_num BenAcct,
             CASE
                WHEN aca.currency_code <> 'VND' THEN bb.eft_swift_code
                ELSE ' '
             END
                bANKcode,
             SUBSTR (IEBA.BRANCH_NAME, 1, 35) ben_bank_name,
             SUBSTR (IEBA.BRANCH_NAME, 36, 53) ben_bank_add,
             ce.bank_account_num funding_account_number,
             (SELECT TO_CHAR (
                           'Pmt : '
                        || aila.description
                        || ' of '
                        || aia.invoice_num)
                FROM ap_invoices_all aia,
                     ap_invoice_lines_all aila,
                     ap_invoice_payments_all aipa
               WHERE     aia.invoice_id = aila.invoice_id
                     AND aia.invoice_id = aipa.invoice_id
                     AND aipa.check_id = aca.check_id
                     AND ROWNUM = 1)
                payment_details,
             TO_CHAR ('OUR') charge,
             TO_CHAR ('COHERENT VIETNAM (DONG NAI) CO LTD')
                ordering_party_name,
             NULL confidential
        FROM ap_checks_all aca,
             iby_payments_all ipa,
             ce_bank_accounts ce,
             cefv_bank_branches bb,
             iby_payee_all_bankacct_v ieba,
             ap_suppliers asup
       WHERE     1 = 1
             AND aca.vendor_id = asup.vendor_id
             AND aca.external_bank_account_id = ieba.ext_bank_account_id
             AND ce.bank_branch_id = bb.bank_branch_id
             AND ipa.internal_bank_account_id = ce.bank_account_id
             AND aca.payment_id = ipa.payment_id
             AND aca.check_id > 129999;

   LC_HEADER   VARCHAR2 (4000)
      := RPAD('Paycode',9,' ')
               || ','
               || RPAD('Value_date',12,' ')
               || ','
               || RPAD('Transaction_Ref',15,' ')
               || ','
               || RPAD('BenName',60,' ')
               || ','
               ||RPAD( 'BenAdd',35,' ')
               || ','
               || RPAD('amount',21,' ')
               || ','
               || RPAD('ccy',10,' ')
               || ','
               || RPAD('BenAcct',34,' ' )
               || ','
               ||RPAD( 'bencode',11,' ')
               || ','
               || RPAD('ben_bank_name',35,' ')
               || ','
               || RPAD('ben_bank_add',35,' ')
               || ','
               || RPAD('funding_account_number',34,' ')
               || ','
               || RPAD('payment_details',40,' ')
               || ','
               || RPAD('charge',10,' ')
               || ','
               || RPAD('ordering_party_name',35,' ');

   PROCEDURE CITI_BANK_UTL(P_DIRECTORY VARCHAR2)
   AS
      l_file         UTL_FILE.file_type;
      V_REQUEST_ID   VARCHAR2 (100) := FND_PROFILE.VALUE ('CONC_REQUEST_ID');
     -- l_location     VARCHAR2 (100) := 'XXQGEN_COMBINED_DIR';
      l_filename     VARCHAR2 (100);
   BEGIN
      l_filename := 'XXQGEN_CITI_BANK_AR' || '_' || V_REQUEST_ID || '.txt';

      l_file := UTL_FILE.fopen (P_DIRECTORY, l_filename, 'w');

      UTL_FILE.put_line (l_file, LC_HEADER);

      FOR REC_CB IN CUR_CITI_BANK
      LOOP
         UTL_FILE.put_line (
            l_file,
             RPAD( NVL(TRIM(TO_CHAR(REC_CB.Paycode)), ' '),9,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.Value_date)), ' '),12,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.Transaction_Ref)),' '),15,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.BenName)), ' '),60,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.BenAdd)),' '),35,' ')
            || ','
            || RPAD(NVL( TRIM(TO_CHAR(REC_CB.amount)),' '),21,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ccy)),' '),10,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.BenAcct)), ' '),34,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.bankcode)),' '),11,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ben_bank_name)),' '),35,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ben_bank_add)), ' '),35,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.funding_account_number)), ' '),34,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.payment_details)), ' '),40,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.charge)), ' '),10,' ' )
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ordering_party_name)), ' '),35,' '));
            
      END LOOP;

      UTL_FILE.fclose (l_file);

      fnd_file.put_line (
         fnd_file.LOG,
         'Successfully Outbond into file' || ' ' || l_filename);
   EXCEPTION
      WHEN OTHERS
      THEN
         IF UTL_FILE.is_open (l_file)
         THEN
            UTL_FILE.fclose (l_file);
         END IF;
   END CITI_BANK_UTL;

   --#########################################################

   PROCEDURE CB_DBMS_OUTPUT
   AS
   BEGIN
      FND_FILE.PUT_LINE (FND_FILE.OUTPUT, LC_HEADER);

      FOR REC_CB IN CUR_CITI_BANK
      LOOP
         FND_FILE.PUT_LINE (
            FND_FILE.OUTPUT,
             RPAD( NVL(TRIM(TO_CHAR(REC_CB.Paycode)), ' '),9,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.Value_date)), ' '),12,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.Transaction_Ref)),' '),15,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.BenName)), ' '),60,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.BenAdd)),' '),35,' ')
            || ','
            ||RPAD(NVL( TRIM(TO_CHAR(REC_CB.amount)),' '),21,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ccy)),' '),10,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.BenAcct)), ' '),34,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.bankcode)),' '),11,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ben_bank_name)),' '),35,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ben_bank_add)), ' '),35,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.funding_account_number)), ' '),34,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.payment_details)), ' '),40,' ')
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.charge)), ' '),10,' ' )
            || ','
            || RPAD(NVL(TRIM(TO_CHAR(REC_CB.ordering_party_name)), ' '),35,' '));
            
            END LOOP;
   EXCEPTION
      WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'ERROR IN GENERATING DBMS OUTPUT');
   END CB_DBMS_OUTPUT;

   --########################################################

   PROCEDURE MAIN (ERRBUF OUT VARCHAR, RETCODE OUT VARCHAR,P_TYPE VARCHAR2 ,P_DIRECTORY VARCHAR2)
   AS
   BEGIN
      IF P_TYPE = 'UTL FILE'
      THEN
         CITI_BANK_UTL(P_DIRECTORY);
      ELSIF P_TYPE = 'DBMS OUTPUT'
      THEN
         CB_DBMS_OUTPUT;
      END IF;
   EXCEPTION
      WHEN OTHERS
      THEN
         FND_FILE.PUT_LINE (FND_FILE.LOG, 'ERROR IN MAIN');
   END MAIN;
END XXQGEN_OUTBOND_AR;
/