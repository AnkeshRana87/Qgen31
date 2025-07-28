CREATE OR REPLACE PROCEDURE PROCESS_ITEM 
IS

  l_item_table     EGO_ITEM_PUB.Item_Tbl_Type;
  x_item_table     EGO_ITEM_PUB.Item_Tbl_Type;
  x_return_status  VARCHAR2(1);
  x_msg_count      NUMBER;
  x_msg_data       VARCHAR2(1000);
  x_message_list   ERROR_HANDLER.error_tbl_type;
  
  l_index NUMBER := 0;
  
    CURSOR CUR_ITEM IS
    SELECT *
    FROM xxqgen_item_stg_ar
    WHERE process_flag = 'N' ;

BEGIN
  FND_GLOBAL.APPS_INITIALIZE(user_id => 1318, resp_id => 50583, resp_appl_id => 401);

    
    FOR REC IN CUR_ITEM
    
   LOOP
    l_index := l_index + 1;

    l_item_table(l_index).transaction_type := rec.transaction_type;
    l_item_table(l_index).segment1 := rec.segment1;
    l_item_table(l_index).description := rec.description;
    l_item_table(l_index).long_description := rec.long_description;
    l_item_table(l_index).organization_id := rec.organization_id;
    l_item_table(l_index).template_id := rec.template_id;
    l_item_table(l_index).template_name := rec.template_name;
    l_item_table(l_index).inventory_item_status_code := rec.inventory_item_status_code;
  END LOOP;


EGO_ITEM_PUB.Process_Items(
   p_api_version     => 1.0,
   p_init_msg_list   => FND_API.G_TRUE,
   p_commit          => FND_API.G_FALSE,
   p_item_tbl        => l_item_table,
   x_item_tbl        => x_item_table,
   x_return_status   => x_return_status,
   x_msg_count       => x_msg_count
--  , x_msg_data        => x_msg_data
);

  -- Handle response
  IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
    FOR i IN 1 .. x_item_table.COUNT LOOP
      UPDATE xxqgen_item_stg_ar
      SET process_flag = 'Y',
          error_message = 'Item ID: ' || x_item_table(i).inventory_item_id || ', Org ID: ' || x_item_table(i).organization_id,
          last_update_date = SYSDATE
      WHERE segment1 = x_item_table(i).segment1
        AND organization_id = x_item_table(i).organization_id;
    END LOOP;
  ELSE
    -- Collect error messages
    Error_Handler.GET_MESSAGE_LIST(x_message_list => x_message_list);
    FOR i IN 1 .. l_item_table.COUNT LOOP
      UPDATE xxqgen_item_stg_ar
      SET process_flag = 'E',
          error_message = ('ERROR'),
          last_update_date = SYSDATE
      WHERE segment1 = l_item_table(i).segment1
        AND organization_id = l_item_table(i).organization_id;
    END LOOP;
  END IF;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
    ROLLBACK;
END PROCESS_ITEM;

/

CREATE OR REPLACE PROCEDURE ASSIGN_ITEM_TO_ORG_AR
IS
        g_user_id             fnd_user.user_id%TYPE  :=1318 ;
        l_appl_id             fnd_application.application_id%TYPE := 401;
        l_resp_id             fnd_responsibility_tl.responsibility_id%TYPE := 50583;
        l_api_version         NUMBER := 1.0;
        l_init_msg_list       VARCHAR2(2) := fnd_api.g_false;
        l_commit              VARCHAR2(2) := FND_API.G_FALSE;
        X_RETURN_STATUS  VARCHAR2(1);
        X_MSG_COUNT      NUMBER;
        x_msg_data       VARCHAR2(1000);
        x_message_list   ERROR_HANDLER.error_tbl_type;
  
  BEGIN
  
  EGO_ITEM_PUB.ASSIGN_ITEM_TO_ORG(
                   P_API_VERSION          => l_api_version
                ,  P_INIT_MSG_LIST        => l_init_msg_list
                ,  P_COMMIT               => l_commit
--                ,  P_INVENTORY_ITEM_ID    => 302227
                ,  p_item_number          => 'ITEM003'
                ,  p_organization_id      => 1759
                ,  P_ORGANIZATION_CODE    => 'U1'
--                ,  P_PRIMARY_UOM_CODE     => 'EA'
                ,  X_RETURN_STATUS        => x_return_status
                ,  X_MSG_COUNT            => x_msg_count
            );
            
             DBMS_OUTPUT.PUT_LINE('Status: '||x_return_status);
        
        IF (x_return_status <> FND_API.G_RET_STS_SUCCESS) THEN
          DBMS_OUTPUT.PUT_LINE('Error Messages :');
          Error_Handler.GET_MESSAGE_LIST(x_message_list=>x_message_list);
            FOR j IN 1..x_message_list.COUNT LOOP
              DBMS_OUTPUT.PUT_LINE(x_message_list(j).message_text);
            END LOOP;
        END IF;
EXCEPTION
        WHEN OTHERS THEN
          dbms_output.put_line('Exception Occured :');
          DBMS_OUTPUT.PUT_LINE(SQLCODE ||':'||SQLERRM);
END ASSIGN_ITEM_TO_ORG_AR;
/

/
BEGIN
--PROCESS_ITEM ;
ASSIGN_ITEM_TO_ORG_AR;
END;
/

SELECT * FROM MTL_SYSTEM_ITEMS_B msib--, ORG_ORGANIZATION_DEFINITIONS ood 
where segment1 ='ITEM003'
--and msib.ORGANIZATION_ID = ood.ORGANIZATION_ID --302227 ,302228,302225,302226,301226

/

select * from mtl_item_categories where INVENTORY_ITEM_ID =302227

select * from MTL_ITEM_REVISIONS_B where INVENTORY_ITEM_ID =302227

select * from  MTL_CATEGORIES

select * from  MTL_CATEGORY_SETS

select * from  MTL_ITEM_STATUS

select * from  MTL_ITEM_TEMPLATES


SELECT msib.inventory_item_id
, msib.segment1 item#
, icat.category_id
, icat.category_set_id
,mc.segment1||' '||mc.segment2 category
--,mc.description
--, mcs.category_set_name
FROM mtl_system_items_b msib
, mtl_item_categories icat 
, mtl_categories mc 
, mtl_category_sets_b mcs
WHERE 1=1
and msib.inventory_item_id = icat.inventory_item_id 
AND icat.category_id = mc.category_id
AND icat.category_set_id = mcs.category_set_id
AND msib.organization_id = icat.organization_id
and msib.inventory_item_id = 302227

SELECT * FROM ORG_ORGANIZATION_DEFINITIONS

SELECT inventory_item_id, organization_id, segment1
FROM mtl_system_items
WHERE inventory_item_id = 302227
  AND organization_id =204
