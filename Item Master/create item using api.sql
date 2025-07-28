DECLARE
  l_inventory_item_id   NUMBER := 8779;
  l_organization_id     NUMBER := 204 ;
  l_return_status       VARCHAR2 (4000) := 'S';
  l_msg_data            VARCHAR2 (4000) := 'ITEM CREATED';
  l_msg_count           NUMBER := 10;
  x_message_list        error_handler.error_tbl_type;
BEGIN
  fnd_global.apps_initialize (user_id => 1318, --> OPERATIONS
                              resp_id => 50583, --> Inventory, Vision Operations (USA)
                              resp_appl_id => 401); --> Inventory

  ego_item_pub.process_item (p_api_version                  => 1.0
                            ,p_init_msg_list                => 'T' -- (F:- False), (T:- True)
                            ,p_commit                       => 'F' -- (F:- False), (T:- True)
                            ,p_transaction_type             => 'CREATE' -- UPDATE FOR Updating item
                            ,p_segment1                     => 'Test Item AR' -- ITEM CODE
                            ,p_description                  => ' Test Item AR Description' -- ITEM DESCRIPTION
                            ,p_long_description             => 'Test Long Item Description AR' -- ITEM LONG DESCRIPTION
                            ,p_organization_id              => 204 -- Vision Operations
                            ,p_apply_template               => 'ALL'
                            ,p_template_id                  => 2 -- Purchased Item — select * from mtl_item_templates_vl
                            -- P_TEMPLATE_NAME => '@Purchased Item',
                            -- P_ITEM_TYPE => 'P',
                            ,p_inventory_item_status_code   => 'Active'
                            ,p_approval_status              => 'A'
                            ,x_inventory_item_id            => l_inventory_item_id
                            ,x_organization_id              => l_organization_id
                            ,x_return_status                => l_return_status
                            ,x_msg_count                    => l_msg_count
                            ,x_msg_data                     => l_msg_data);

  IF l_return_status = fnd_api.g_ret_sts_success THEN
    dbms_output.put_line ('Item is Created Successfully, Inventory Item ID : ' || l_inventory_item_id);

  ELSE
    dbms_output.put_line ('Item Creation is Failed');
    error_handler.get_message_list (x_message_list => x_message_list);

    FOR i IN 1 .. x_message_list.count
    LOOP
      dbms_output.put_line (x_message_list (i).message_text);
    END LOOP;

    ROLLBACK;
  END IF;
--> EXCEPTIONS HANDLING PART
EXCEPTION
  WHEN OTHERS THEN
    FOR i IN 1 .. l_msg_count
    LOOP
      dbms_output.put_line (substr (fnd_msg_pub.get (p_encoded => fnd_api.g_false), 1, 255));
      dbms_output.put_line ('message is: ' || l_msg_data);
    END LOOP;
END;

/
commit
/

SELECT * FROM MTL_SYSTEM_ITEMS_B