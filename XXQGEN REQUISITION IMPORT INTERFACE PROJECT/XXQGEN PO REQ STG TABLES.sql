CREATE TABLE XXQGEN_PO_REQ_HEADERS_STG_AR (
    RECORD_ID                       NUMBER ,
    REQUEST_ID                      NUMBER,
    CREATED_BY                      NUMBER,            
    CREATION_DATE                 DATE ,  
    LAST_UPDATED_BY           NUMBER,            
    LAST_UPDATE_DATE        DATE ,  
    PROCESS_FLAG                VARCHAR2(10),
    ERROR_MESSAGE           VARCHAR2(2000),  
    REQUISITION_HEADER_ID NUMBER,
    REQUISITION_NUMBER      VARCHAR2(50),          
    PREPARER_ID                    NUMBER,  
    PREPARER                        VARCHAR2(100),
    OPERATING_UNIT          VARCHAR2(100),  
    ORG_ID                          NUMBER,
    AUTHORIZATION_STATUS    VARCHAR2(30),        
    DESCRIPTION             VARCHAR2(240),       
    REQUISITION_TYPE        VARCHAR2(30)
)

select * from XXQGEN_PO_REQ_HEADERS_STG_AR

truncate table XXQGEN_PO_REQ_HEADERS_STG_AR

drop table XXQGEN_PO_REQ_HEADERS_STG_AR




INSERT INTO XXQGEN_PO_REQ_HEADERS_STG_AR VALUES (
NULL
,NULL
,1000
,SYSDATE
,1000
,SYSDATE
,'N'
,NULL
,NULL
,NULL
,'Stock, Ms. Pat'
,'Vision Operations'
,NULL
,'APPROVED'
,'REQUISITION FOR TEST'
,'PURCHASE'
,NULL
,NULL
,NULL
) 

INSERT INTO XXQGEN_PO_REQ_HEADERS_STG_AR VALUES (
NULL
,NULL
,11
,SYSDATE
,11
,SYSDATE
,'N'
,NULL
,NULL
,NULL
,'Stock, Ms. Pat'
,'Vision Operations'
,NULL
,'INCOMPLETE'
,'TEST5'
,'PURCHASE'
,NULL
,NULL
,NULL
) 

INSERT INTO XXQGEN_PO_REQ_HEADERS_STG_AR VALUES (
NULL
,FND_PROFILE.VALUE('CONC_REQUEST_ID')
,FND_PROFILE.VALUE('USER_ID')
,SYSDATE
,FND_PROFILE.VALUE('USER_ID')
,SYSDATE
,'N'
,NULL
,81
,'104'
,NULL
,'Green, Mr. Terry'
,'Vision Operations'
,NULL
,'APPROVED'
,'Testing Description'
,'PURCHASE'
,NULL
,NULL
,NULL
) 


UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'Preparer can not be null' 
where preparer is null ;


UPDATE XXQGEN_PO_REQ_HEADERS_STG_AR
SET PROCESS_FLAG = 'E' ,
ERROR_MESSAGE = 'Requisition Number can not be null' 
where requisition_number is null ;



SELECT * FROM 
PO_REQUISITION_HEADERS_ALL PRHA
, PO_REQUISITION_LINES_ALL PRLA
,PO_REQ_DISTRIBUTIONS_ALL PRDA
WHERE 1=1
AND PRHA.REQUISITION_HEADER_ID = PRLA.REQUISITION_HEADER_ID
AND PRLA.REQUISITION_LINE_ID = PRDA.REQUISITION_LINE_ID
AND PRHA.ORG_ID = 204
AND PRLA.REQUISITION_LINE_ID IS NOT NULL
AND PRDA.DISTRIBUTION_ID IS NOT NULL


select * from po_requisition_headers_all where segment1 = '15948'


81 (HDR_ID)     24(PREPARER_ID)      104(SEGMENT1)     APPROVED (AUTHORIZATION_STATUS)       PURCHASE(TYPE_LOOKUP_CODE)        204(ORG_ID)

81  (REQUISITION_LINE_ID)      1 (LINE_NUM  )  1(CATEGORY_ID)       Each (UNIT_MEAS_LOOKUP_CODE)       
20 (UNIT_PRICE)     50 (QUANTITY)     209 (DELIVER_TO_LOCATION_ID)      24  (TO_PERSON_ID)      75(ITEM)        1/4/1996(NBD)       207(DESTINATION ORGANIZATION)       

81 DI     13401(CCI)        13402 (ACCURAL)      13781(VARIANCE)



SELECT * FROM PER_ALL_PEOPLE_F WHERE PERSON_ID =25

----- 
SELECT * FROM PO_REQ_DISTRIBUTIONS_ALL


CREATE TABLE XXQGEN_PO_REQ_LINES_STG_AR (
    RECORD_ID                       NUMBER ,
    REQUEST_ID                      NUMBER,
    CREATED_BY              NUMBER,            
    CREATION_DATE           DATE ,  
    LAST_UPDATED_BY         NUMBER(15),            
    LAST_UPDATE_DATE        DATE ,  
    PROCESS_FLAG            VARCHAR2(2),   
    ERROR_MESSAGE           VARCHAR2(2000),
    REQUISITION_NUMBER      VARCHAR2(50),          
    REQUISITION_LINE_ID     NUMBER,            
    LINE_NUM                NUMBER,      
    LINE_TYPE               VARCHAR2(100),
    LINE_TYPE_ID NUMBER ,    
    ITEM_ID                 NUMBER,   
    ITEM_NUMBER        VARCHAR2(20),        
    ITEM_DESCRIPTION        VARCHAR2(240),       
    CATEGORY_ID             NUMBER,  
    CATEGORY                VARCHAR2(50),
    UOM                         VARCHAR2(25),          
    QUANTITY                NUMBER,
    UNIT_PRICE              NUMBER,         
    CURRENCY_CODE           VARCHAR2(10),         
    TO_PERSON_ID            NUMBER,
    REQUESTER                   VARCHAR2(100),  
    NEED_BY_DATE            DATE,        
    ORGANIZATION_ID     NUMBER,
    ORGANIZATION            VARCHAR2(100),
    LOCATION_ID             NUMBER,
    LOCATION                VARCHAR2(300),         
    VENDOR_ID               NUMBER(15),    
    SUPPLIER                    VARCHAR2(200),       
    VENDOR_SITE_ID          NUMBER(15), 
    SITE                            VARCHAR2(200),
    VENDOR_CONTACT_ID          NUMBER(15),
    CONTACT                   VARCHAR2(100),           
    PHONE                       VARCHAR2(30),
    DESTINATION_TYPE         VARCHAR2(150),
    SUBINVENTORY              VARCHAR2(150),
    SOURCE              VARCHAR2(150),
    DISTRIBUTION_ID NUMBER ,
    CODE_COMBINATION_ID NUMBER,
    CHARGE_ACCOUNT VARCHAR2(50),
    CHARGE_ACCOUNT_ID NUMBER
);    
    
          
DROP TABLE XXQGEN_PO_REQ_LINES_STG_AR

SELECT * FROM XXQGEN_PO_REQ_LINES_STG_AR

INSERT INTO XXQGEN_PO_REQ_LINES_STG_AR VALUES (
NULL
,FND_PROFILE.VALUE('CONC_REQUEST_ID')
,FND_PROFILE.VALUE('USER_ID')
,SYSDATE
,FND_PROFILE.VALUE('USER_ID')
,SYSDATE
,'N'
,NULL
,NULL
,NULL
,NULL
,NULL
,'f80000'
,'Sentinal Multimedia'
,NULL
,'MISC MISC'
,'EACH'
,10
,1000
,'USD'
,NULL
,'Stock, Ms. Pat'
,SYSDATE
,NULL
,'Vision Operations'
,NULL
,'HR- San Francisco'
,NULL
,'Dell Computers'
,NULL
,'DELL CHINA'
,NULL
,NULL
,NULL
,NULL
,NULL
)


INSERT INTO XXQGEN_PO_REQ_LINES_STG_AR VALUES (
NULL
,FND_PROFILE.VALUE('CONC_REQUEST_ID')
,FND_PROFILE.VALUE('USER_ID')
,SYSDATE
,FND_PROFILE.VALUE('USER_ID')
,SYSDATE
,'N'
,NULL
,'104'
,81
,1
,NULL
,'f20000'
,'Paper - requires 2-way match office supply item'
,NULL
,'MISC MISC'
,'Each'
,50
,20
,'USD'
,NULL
,'Stock, Ms. Pat'
,SYSDATE
,NULL
,'Vision Operations'
,NULL
,'HR- San Francisco'
,NULL
,'Dell Computers'
,NULL
,'DELL CHINA'
,NULL
,NULL
,NULL
,NULL
,NULL
)

select * from mtl_system_items_b WHERE INVENTORY_ITEM_ID =75 AND ORGANIZATION_ID =204

--f80000     Sentinal Multimedia        63      204
--f12000    Mobile phone                  73        204
      

SELECT * FROM PO_REQUISITION_HEADERS_ALL WHERE SEGMENT1 ='15948' 

SELECT * FROM PO_REQUISITION_LINES_ALL WHERE REQUISITION_HEADER_ID =571811

SELECT * FROM PO_LOOKUP_CODES 
WHERE 1=1
AND DISPLAYED_FIELD ='Supplier'
--AND LOOKUP_CODE = 'VENDOR'
 AND ENABLED_FLAG ='Y' AND LOOKUP_TYPE ='VENDOR TYPE'


SELECT * FROM PO_LINE_TYPES WHERE LINE_TYPE_ID  =1


SELECT * FROM MTL_SYSTEM_ITEMS_B WHERE INVENTORY_ITEM_ID = 75
 
select * from po_req_distributions_all

SELECT * FROM DBA_OBJECTS WHERE OBJECT_NAME LIKE 'PO%REQ%INTERFACE%'

SELECT * FROM PO_REQUISITIONS_INTERFACE_ALL

select * from po_requisition_headers_all


select * from mtl_categories WHERE CATEGORY_ID =1

segment1||' '||segment2

--MISC MISC     1

select * from Po_requisition_lines_all

SELECT * FROM HR_LOCATIONS
--HR- San Francisco   202
--V1- New York City   204

SELECT * FROM AP_SUPPLIERS
--TP1 Supp          30163
--Jamie Frost       8
--Dell Computers        1078

SELECT * FROM AP_SUPPLIER_SITES_ALL WHERE VENDOR_ID = 1078
--4169     DELL CHINA
--5888      VHS DELL
                
               

CREATE TABLE XXQGEN_PO_REQ_DIST_STG_AR (
    RECORD_ID                       NUMBER ,
    REQUEST_ID                      NUMBER,
    CREATED_BY                        NUMBER,            
    CREATION_DATE                 DATE ,  
    LAST_UPDATED_BY               NUMBER(15),            
    LAST_UPDATE_DATE             DATE ,  
    PROCESS_FLAG                     NUMBER,   
    ERROR_MESSAGE                 VARCHAR2(2000),
    REQUISITION_NUMBER         VARCHAR2(50),    
    REQUISITION_LINE_ID          NUMBER,
    CODE_COMBINATION_ID      NUMBER,
    CHARGE_ACCOUNT              VARCHAR2(50),
    ACCRUAL_ACCOUNT_ID       NUMBER,
    VARIANCE_ACCOUNT_ID      NUMBER ,
    ORG_ID                              NUMBER
    ) ;
    
    
    SELECT * FROM PO_REQ_DISTRIBUTIONS_ALL WHERE REQUISITION_LINE_ID = 624262
    -- DISTRIBUTION ID 621621 
    
    SELECT  *
    FROM GL_CODE_COMBINATIONS WHERE CODE_COMBINATION_ID =  13185
    
    --01 510 7530 0000 000
    
    
      SELECT GCC.CODE_COMBINATION_ID 
      INTO  REQ_LINE_tbl(i).CODE_COMBINATION_ID
         FROM GL_CODE_COMBINATIONS GCC, PO_REQ_DISTRIBUTIONS_ALL PRDA
         WHERE 1=1 
         AND GCC.CODE_COMBINATION_ID = PRDA.CODE_COMBINATION_ID
         AND PRDA.DISTRIBUTION_ID = REQ_LINE_tbl(i).DISTRIBUTION_ID
         AND SEGMENT1||' '||SEGMENT2||' '||SEGMENT3||' '||SEGMENT4||' '||SEGMENT5 = REQ_LINE_tbl(i).CHARGE_ACCOUNT ;
         
    
CREATE SEQUENCE REQ_LOAD_REC_ID_SEQ_AR
  INCREMENT BY 1
  START WITH 1
  MINVALUE 1  ;
  
  
  CREATE SEQUENCE REQ_LOAD_REC_ID_SEQ2_AR
  INCREMENT BY 1
  START WITH 1
  MINVALUE 1  ;
  
  
      
CREATE SEQUENCE REQ_NUM_SEQ_AR
  INCREMENT BY 1
  START WITH 1
  MINVALUE 1  ;
  
  
  select * from po_requisitions_interface_all
  
  inser into po_requisitions_interface_all (
  TRANSACTION_ID 
  ,PROCESS_FLAG ,
   REQUEST_ID ,
   CREATION_DATE ,
    CREATED_BY ,
    INTERFACE_SOURCE_CODE
    ,SOURCE_TYPE_CODE ,
     REQUISITION_HEADER_ID
    REQUISITION_LINE_ID
     ,REQ_DISTRIBUTION_ID 
     , REQUISITION_TYPE 
     , DESTINATION_TYPE_CODE
      , ITEM_DESCRIPTION 
      ,QUANTITY
       ,UNIT_PRICE
        ,AUTHORIZATION_STATUS
    BATCH_ID 
    ,PREPARER_ID 
    ,HEADER_DESCRIPTION
     ,ITEM_ID
      ,CHARGE_ACCOUNT_ID 
      ,CATEGORY_ID
       ,UNIT_OF_MEASURE 
       ,LINE_TYPE_ID
       ,DESTINATION_ORGANIZATION_ID
    DELIVER_TO_LOCATION_ID
    ,DELIVER_TO_REQUESTOR_ID
    ,SUGGESTED_VENDOR_ID
    ,SUGGESTED_VENDOR_SITE_ID
    ,SUGGESTED_VENDOR_CONTACT
    ,NEED_BY_DATE
    ,ORG_ID
    ,REQ_DIST_SEQUENCE_ID
    )
  
/* Formatted on 2/18/2025 11:12:38 PM (QP5 v5.163.1008.3004) */
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
       AND hdr.record_id = line.record_id
       AND hdr.process_flag = 'V'
       AND line.process_flag = 'V'
       
       
       
       
       FUNCTION get_chart_account_id (charge_account       VARCHAR2,
                                  organization_name    VARCHAR2)
      RETURN NUMBER
   AS
      ln_chart_account_id   NUMBER := NULL;
   BEGIN
      BEGIN
         SELECT gcc.CHART_OF_ACCOUNTS_ID
           INTO ln_chart_account_id
           FROM hr_operating_units hou,
                xle_entity_profiles xlef,
                GL_LEDGERS gll,
                gl_code_combinations gcc
          WHERE     hou.DEFAULT_LEGAL_CONTEXT_ID = xlef.LEGAL_ENTITY_ID
                AND hou.SET_OF_BOOKS_ID = gll.LEDGER_ID
                --         and hou.organization_id = 204
                AND hou.organization_id = get_org_id (organization_name)
                AND gcc.CHART_OF_ACCOUNTS_ID = gll.CHART_OF_ACCOUNTS_ID
                --         and gcc.segment1||'-'||gcc.segment2||'-'||gcc.segment3||'-'||gcc.segment4||'-'||gcc.segment5 = '01-000-1410-0000-000'
                AND    gcc.segment1
                    || '-'
                    || gcc.segment2
                    || '-'
                    || gcc.segment3
                    || '-'
                    || gcc.segment4
                    || '-'
                    || gcc.segment5 = charge_account;
      END;

      RETURN ln_chart_account_id;
   END get_chart_account_id;
   
   
   select * from dba_objects where object_name like 'XXQGEN%AK'


 SELECT gcc.CHART_OF_ACCOUNTS_ID 
           --INTO ln_chart_account_id
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
                    || gcc.segment5 =   '01-510-7530-0000-000';
                    
                    
                    


             
                        
                        
                        
                        
                        
     
         