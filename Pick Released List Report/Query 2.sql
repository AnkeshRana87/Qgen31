SELECT 
OEH.ORDER_NUMBER,
hp2.party_name SHIP_TO_CUSTOMER,
          hl.address1
       || ' '
       || hl.address2
       || ' '
       || hl.address3
       || ' '
       || hl.address4
          SHIP_TO_CUSTOMER_ADDRESS,
                 hp2.PERSON_LAST_NAME
          || DECODE (hp2.PERSON_FIRST_NAME,
                     NULL, NULL,
                     ', ' || hp2.PERSON_FIRST_NAME)
             SHIP_TO_CONTACT,
             hp2.primary_phone_number  ship_to_phone,
       bill_to_party.party_name BILL_TO_CUSTOMER,
          bill_to_location.address1
       || ' '
       || bill_to_location.address2
       || ' '
       || bill_to_location.address3
       || ' '
       || bill_to_location.address4
          BILL_TO_CUSTOMER_ADDRESS
     ,hp3.PERSON_LAST_NAME
          || DECODE (hp3.PERSON_FIRST_NAME,
                     NULL, NULL,
                     ', ' || hp3.PERSON_FIRST_NAME)
             BILL_TO_CONTACT,
        hp2.primary_phone_number  bill_to_phone,
       OEH.ORDER_CATEGORY_CODE,
       oeh.order_number SALES_ORDER_NUMBER,
       oel.LINE_NUMBER || '.' || oel.SHIPMENT_NUMBER SALES_ORDER_LINE_NUMBER,
       oel.LINE_NUMBER,
       oel.CUST_PO_NUMBER CUSTOMER_ORDER_NUMBER,
       oel.ordered_item CUSTOMER_PARTS#,
       msib.SEGMENT1 PART_NUMBER,
       msib.description ITEM_DESCRIPTION,
       wnd.name DELIVERY_NUMBER,
       TO_CHAR (wnd.ultimate_dropoff_date, 'YYYY/MM/DD') DELIVERY_DATE,
       wdd.DELIVERED_QUANTITY,
              oel.SHIPMENT_NUMBER,
              NULL SHIPPING_NOTES,
              NULL SHIPPING_INSTRUCTIONS
       /*
       ,mmt.transaction_id P_TRANSACTION_ID,
       mmt.organization_id P_ORGANIZATION_ID,
       wnd.CARRIER_ID,
       HZL.LOCATION_CODE ORG_NAME,
          hzl.address_line_1
       || ' '
       || hzl.address_line_2
       || ' '
       || hzl.address_line_3
       || ' '
       || hzl.town_or_city
          SALES_ORG_DETAILS,
       HZL.TELEPHONE_NUMBER_1 TEL,
       HZL.TELEPHONE_NUMBER_3 FAX,
       hp.party_id SHIP_TO_PARTY_ID,
       --FR_PACKING_NOTE_RPT_PKG.get_invoice_address (oeh.attribute17,  oeh.INVOICE_TO_ORG_ID)  INVOICE_ADDRESS,
       NULL FORWARDING_AGENT,
       NULL CUSTOMER_DESCR_OF_PARTNER,
       oeh.fob_point_code INCOTERMS_OF_DELIVERY,
       wnd.mode_of_transport MEANS_OF_TRANSPORT_TYPE,
       wnd.waybill BILL_OF_LADING,
       NULL BOX_LABEL,
       NULL BOX_ID,
       oel.ordered_item ITEM_NUMBER_OF_DELIVERY_NOTE,
       (SELECT description
          FROM mtl_system_items_b msib
         WHERE msib.inventory_item_id = oel.inventory_item_id AND ROWNUM <= 1)
          ITEM_DESCRIPTION,
       oel.shipped_quantity QUANTITY_OF_DELIVERY_ITEM,
       oel.order_quantity_uom UNIT_OF_MEASUREMENT,
       oel.subinventory STORAGE_LOCATION,
       NULL PL_CODE2,
       hp.party_name CUSTOMER_NAME,
       hca.account_number CUSTOMER_NUMBER,
       hp.party_id SHIP_TO_CUSTOMER_ID,
       hp.party_name SHIP_TO_CUSTOMER_NAME,
          hl.address1
       || ' '
       || hl.address2
       || ' '
       || hl.address3
       || ' '
       || hl.address4
          SHIPTO_CUSTOMER_ADDRESS,
       hl.address2 SHIPTO_CUSTOMER_STREET,
       hl.city SHIPTO_CUSTOMER_CITY,
       hl.county SHIPTO_CUSTOMER_DISTRICT,
       hl.country SHIPTO_CUSTOMER_COUNTRY,
       hl.postal_code POSTAL_CODE,
       hpc.party_name CARRIER_NAME,
       NULL INCOTERMS_PART2,
       NULL SPECIAL_SHIP_INSTRUCTIONS,
       NULL PROFORMA_INVOICE_NUMBER,
       NVL (wdd.ATTRIBUTE3,
            (SELECT COUNTRY
               FROM HR_ORGANIZATION_UNITS_V
              WHERE organization_id = oeh.sold_from_org_id))
          COUNTRY_OF_ORGN,
       wnd.GROSS_WEIGHT,
       wnd.NET_WEIGHT,
       FDST.SHORT_TEXT NOTES,
       wnd.attribute1 NO_OF_BOXES,
       OEH.ATTRIBUTE14 AUTHORISED_BY,
 */
 FROM wsh_new_deliveries wnd,
       wsh_delivery_assignments wda,
       wsh_delivery_details wdd,
       wsh_carrier_services wcs,
       oe_order_headers_all oeh,
       oe_order_lines_all oel,
       org_organization_definitions ood,
       mtl_material_transactions mmt,
       mtl_system_items_b msib,
       hz_cust_accounts hca,
       hz_parties hp,
       hz_parties hp1,
       hz_parties hp2,
       hz_cust_site_uses_all hcsuas,
       hz_cust_acct_sites_all hcasas,
       hz_party_sites hps,
       hz_locations hl,
       hz_relationships ship_rel,
       hz_cust_account_roles ship_roles,
       HZ_CUST_ACCOUNTS ship_acct,
--       hz_contact_points hcp,
       hz_parties bill_to_party,
       hz_cust_site_uses_all bill_to_asu,
       hz_cust_acct_sites_all bill_to_as,
       hz_party_sites bill_to_sites,
       hz_locations bill_to_location,
       hz_relationships bill_rel,
       hz_cust_account_roles bill_roles,
       HZ_CUST_ACCOUNTS BILL_ACCT,
       hz_parties hp3,
       hz_parties hpc,
       hz_party_usg_assignments hpu,
       HR_organization_units hou,
       hr_locations hzl,
       FND_DOCUMENTS_TL FDT,
       FND_DOCUMENTS FD,
       FND_DOCUMENTS_SHORT_TEXT FDST,
       FND_ATTACHED_DOCUMENTS FAD
 WHERE     1 = 1
       AND wda.delivery_detail_id = wdd.delivery_detail_id
       AND wda.delivery_id = wnd.delivery_id(+)
       AND wnd.carrier_id = hpc.party_id(+)
       AND hpc.party_id = hpu.party_id(+)
       AND hpu.party_usage_code(+) = 'TRANSPORTATION_PROVIDER'
       AND wnd.carrier_id = wcs.carrier_id(+)
       AND wnd.ship_method_code = wcs.ship_method_code(+)
       AND wdd.source_header_id = oeh.header_id
       AND wdd.source_line_id = oel.line_id
       AND oeh.header_id = oel.header_id
       AND oeh.ship_from_org_id = ood.organization_id
       AND oeh.sold_from_org_id = hou.organization_id
       AND hou.location_id = hzl.location_id
       AND mmt.trx_source_delivery_id = wnd.delivery_id
       AND mmt.TRX_SOURCE_LINE_ID = oel.line_id
       AND OEL.INVENTORY_ITEM_ID = msib.inventory_item_id
       AND msib.organization_id = ood.organization_id
       AND oeh.sold_to_org_id = hca.cust_account_id
       AND hca.party_id = hp.party_id
       AND oeh.ship_to_org_id = hcsuas.site_use_id --SHIP TO
       AND hcasas.cust_acct_site_id = hcsuas.cust_acct_site_id
       AND hps.party_site_id = hcasas.party_site_id
       AND hl.location_id = hps.location_id
       AND hp1.party_id = hps.party_id
       AND ship_roles.party_id = ship_rel.party_id(+)
--       AND BILL_roles.primary_flag='Y'
       AND oeh.ship_to_contact_id = ship_roles.cust_account_role_id(+)
       AND ship_roles.role_type(+) = 'CONTACT'
       AND NVL (ship_rel.object_id, -1) = NVL (ship_acct.party_id, -1)
--       and hcp.owner_table_id = hp2.party_id and hcp.contact_point_type = 'PHONE' and hcp.primary_flag = 'Y'
       AND ship_rel.subject_id = hp2.party_id(+)
       AND ship_roles.cust_account_id = ship_acct.cust_account_id
       AND ship_roles.PARTY_ID=ship_rel.PARTY_ID
       AND oeh.invoice_to_org_id = bill_to_asu.site_use_id          -- bill_to
       AND bill_to_as.cust_acct_site_id = bill_to_asu.cust_acct_site_id
       AND bill_to_sites.party_site_id = bill_to_as.party_site_id
       AND bill_to_location.location_id = bill_to_sites.location_id
       AND bill_to_party.party_id = bill_to_sites.party_id
       AND oeh.invoice_to_contact_id = bill_roles.cust_account_role_id(+)
       AND bill_roles.role_type = 'CONTACT'
       AND bill_rel.subject_id = hp3.party_id(+)
       AND bill_roles.PARTY_ID =bill_rel.PARTY_ID
       AND bill_roles.cust_account_id = BILL_ACCT.cust_account_id(+)
       AND NVL (bill_rel.object_id, -1) = NVL (BILL_ACCT.party_id, -1)
       AND FDT.DOCUMENT_ID(+) = FD.DOCUMENT_ID
       AND FAD.DOCUMENT_ID = FD.DOCUMENT_ID(+)
       AND FD.MEDIA_ID = FDST.MEDIA_ID(+)
       AND FAD.PK1_VALUE(+) = TO_CHAR (OEH.HEADER_ID)
       AND FDT.LANGUAGE(+) = USERENV ('LANG')
       AND FAD.ENTITY_NAME(+) = 'OE_ORDER_HEADERS'
       AND hcsuas.site_use_code = 'SHIP_TO'
       AND bill_to_asu.site_use_code = 'BILL_TO'
       AND wdd.source_code = 'OE'
       AND wnd.delivery_id = 4831661--61007  --:P_DELIVERY_ID --'15293946', '15253947'
