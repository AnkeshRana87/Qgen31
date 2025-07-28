CREATE OR REPLACE PACKAGE XXQGEN_ITEM_CREATION_AR  AS

    /*************************************************************************************************
     *                 Copy Rights Reserved Â© QGEN- 2024
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
	 
   gn_org_id         hr_all_organization_units.organization_id%TYPE
                        := fnd_profile.VALUE ('ORG_ID');

   gc_user_name      fnd_user.user_name%TYPE := fnd_profile.VALUE ('USERNAME');

   gc_resp_name      fnd_responsibility_tl.responsibility_name%TYPE
                        := fnd_profile.VALUE ('RESP_NAME');

   gn_request_id     fnd_concurrent_requests.request_id%TYPE 
                        := fnd_profile.VALUE ('CONC_REQUEST_ID');

   gn_user_id        fnd_user.user_id%TYPE := fnd_profile.VALUE ('USER_ID');

   gn_resp_id        fnd_responsibility_tl.responsibility_id%TYPE
                        := fnd_profile.VALUE ('RESP_ID');

   gn_resp_appl_id   fnd_responsibility_tl.application_id%TYPE
                        := fnd_profile.VALUE ('RESP_APPL_ID');

   gn_login_id       fnd_logins.login_id%TYPE
                        := fnd_profile.VALUE ('LOGIN_ID');

   gd_date           DATE := SYSDATE;
   
   ln_count NUMBER ;
   
   gn_limit number := 100;
   
   
   
PROCEDURE MAIN (p_erbuff OUT VARCHAR2, p_retcode OUT VARCHAR2);


END  XXQGEN_ITEM_CREATION_AR ;
 

