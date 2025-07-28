CREATE OR REPLACE PROCEDURE PROCESS_AND_ASSIGN_ITEM
IS
    g_user_id       fnd_user.user_id%TYPE := 1318;
    g_resp_id       fnd_responsibility.responsibility_id%TYPE := 50583;
    g_appl_id       fnd_application.application_id%TYPE := 401;

    -- API variables
    l_item_table     EGO_ITEM_PUB.Item_Tbl_Type;
    x_item_table     EGO_ITEM_PUB.Item_Tbl_Type;
    x_return_status  VARCHAR2(1);
    x_msg_count      NUMBER;
    x_msg_data       VARCHAR2(1000);
    x_message_list   ERROR_HANDLER.error_tbl_type;

    l_index NUMBER := 0;

    CURSOR cur_items IS
        SELECT *
        FROM xxqgen_item_stg_ar
        WHERE process_flag = 'N';

BEGIN
    -- Initialize apps session
    FND_GLOBAL.APPS_INITIALIZE(user_id => g_user_id, resp_id => g_resp_id, resp_appl_id => g_appl_id);

    -- item creation record

    FOR rec IN cur_items LOOP
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

  -- Call EGO_ITEM_PUB.PROCESS_ITEMS
    
    EGO_ITEM_PUB.Process_Items(
        p_api_version     => 1.0,
        p_init_msg_list   => FND_API.G_TRUE,
        p_commit          => FND_API.G_FALSE,
        p_item_tbl        => l_item_table,
        x_item_tbl        => x_item_table,
        x_return_status   => x_return_status,
        x_msg_count       => x_msg_count
    );

    IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
        
        -- Assign each item to target org
        
        FOR i IN 1 .. x_item_table.COUNT LOOP
            BEGIN
                EGO_ITEM_PUB.ASSIGN_ITEM_TO_ORG(
                    p_api_version         => 1.0,
                    p_init_msg_list       => FND_API.G_TRUE,
                    p_commit              => FND_API.G_FALSE,
                    p_inventory_item_id   => x_item_table(i).inventory_item_id,
                    p_organization_id     => x_item_table(i).organization_id,
--                  p_organization_code   => NULL, -- Optional if ID is passed
                    x_return_status       => x_return_status,
                    x_msg_count           => x_msg_count
--                  x_msg_data            => x_msg_data
                );

                IF x_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    UPDATE xxqgen_item_stg_ar
                    SET process_flag = 'S',
                        last_update_date = SYSDATE
                    WHERE segment1 = x_item_table(i).segment1
                      AND organization_id = x_item_table(i).organization_id;
                ELSE
                    -- Get error messages for assignment
                    Error_Handler.GET_MESSAGE_LIST(x_message_list => x_message_list);
                    UPDATE xxqgen_item_stg_ar
                    SET process_flag = 'E',
                        error_message = 'Assignment failed: ' --|| x_message_list(1).message_text,
                       , last_update_date = SYSDATE
                    WHERE segment1 = x_item_table(i).segment1
                      AND organization_id = x_item_table(i).organization_id;
                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    UPDATE xxqgen_item_stg_ar
                    SET process_flag = 'E',
                        error_message = 'Assignment EXCEPTION: ' --|| SQLERRM,
                       , last_update_date = SYSDATE
                    WHERE segment1 = x_item_table(i).segment1
                      AND organization_id = x_item_table(i).organization_id;
            END;
        END LOOP;

    ELSE
        -- Capture item creation errors
        Error_Handler.GET_MESSAGE_LIST(x_message_list => x_message_list);
        FOR i IN 1 .. l_item_table.COUNT LOOP
            UPDATE xxqgen_item_stg_ar
            SET process_flag = 'E',
                error_message = 'Creation failed: ' || x_message_list(1).message_text,
                last_update_date = SYSDATE
            WHERE segment1 = l_item_table(i).segment1
              AND organization_id = l_item_table(i).organization_id;
        END LOOP;
    END IF;

--    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Fatal Error: ' || SQLERRM);
        ROLLBACK;
END PROCESS_AND_ASSIGN_ITEM;
/
