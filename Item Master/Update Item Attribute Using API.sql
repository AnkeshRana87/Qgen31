DECLARE
   l_inventory_item_id   NUMBER;
   l_organization_id      NUMBER;
   l_desc                      VARCHAR2(100); 
   l_item_num              VARCHAR2 (50);
   l_long_description    VARCHAR2(200);
   l_so_tran_flag          VARCHAR2 (1);
   l_attribute5              VARCHAR2 (20);
   x_inventory_item_id   NUMBER;
   x_organization_id       NUMBER;
   x_return_status           VARCHAR2 (300);
   x_msg_count               NUMBER;
   x_msg_data                 VARCHAR2 (4000);
BEGIN

          l_inventory_item_id   := 307293;
          l_organization_id      := 204;
          l_desc                      := 'New Description'; 
          l_item_num              :=  'DK_ITEM001';
          l_long_description    :=  'New Long Description';
         l_so_tran_flag           := 'Y';
         l_attribute5               := 'N';

         apps.ego_item_pub.process_item
                      (p_api_version                => 1.0,
                       p_init_msg_list               => 'T',
                       p_commit                      => 'T',
                       p_transaction_type        => 'UPDATE',
                       p_inventory_item_id      => l_inventory_item_id,
                       p_organization_id          => l_organization_id,
                       p_segment1                  =>   l_item_num,
                       p_description               =>    l_desc,
                       p_long_description       =>    l_long_description,
                       p_so_transactions_flag   => l_so_tran_flag,
                       p_attribute5                   => l_attribute5,
                       x_inventory_item_id         => x_inventory_item_id,
                       x_organization_id           => x_organization_id,
                       x_return_status             => x_return_status,
                       x_msg_count                 => x_msg_count,
                       x_msg_data                  => x_msg_data
                      );
        IF (x_return_status <> apps.fnd_api.g_ret_sts_success)
        THEN
               DBMS_OUTPUT.PUT_LINE( 'Item Attribute Update API Error'|| x_return_status );
        ELSE
               DBMS_OUTPUT.PUT_LINE('Item Attribute Update API Success' || x_return_status);
        END IF;
END;
