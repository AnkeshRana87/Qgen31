SELECT DISTINCT wnd.name DELIVERY_NUMBER,  
  mmt.transaction_id P_TRANSACTION_ID,
  mmt.organization_id P_ORGANIZATION_ID,
       TO_CHAR (wnd.ultimate_dropoff_date, 'YYYY/MM/DD')
           DELIVERY_DATE,
       oel.CUST_PO_NUMBER,  
       wnd.CARRIER_ID,
       oeh.order_number SALES_ORDER_NUMBER,
       HZL.LOCATION_CODE ORG_NAME,
          hzl.address_line_1
       || ' '
       || hzl.address_line_2
       || ' '
       || hzl.address_line_3
       || ' '
       || hzl.town_or_city
           SALES_ORG_DETAILS,
       HZL.TELEPHONE_NUMBER_1
           TEL,
       HZL.TELEPHONE_NUMBER_3
           FAX,
       hp.party_id
           SHIP_TO_PARTY_ID,
       FR_PACKING_NOTE_RPT_PKG.get_invoice_address (oeh.attribute17,
                                                    oeh.INVOICE_TO_ORG_ID)
           INVOICE_ADDRESS,
       NULL
           FORWARDING_AGENT,
       NULL
           CUSTOMER_DESCR_OF_PARTNER,
       oeh.fob_point_code
           INCOTERMS_OF_DELIVERY,
       wnd.mode_of_transport
           MEANS_OF_TRANSPORT_TYPE,
       wnd.waybill
           BILL_OF_LADING,
       NULL
           BOX_LABEL,
       NULL
           BOX_ID,
       oel.ordered_item
           ITEM_NUMBER_OF_DELIVERY_NOTE,
       oel.ordered_item
           CUSTOMER_ITEM_NUMBER,
       oel.ordered_item
           ITEM_NUMBER,  
       (SELECT description
          FROM mtl_system_items_b msib
         WHERE msib.inventory_item_id = oel.inventory_item_id AND ROWNUM <= 1)
           ITEM_DESCRIPTION,
       oel.shipped_quantity
           QUANTITY_OF_DELIVERY_ITEM,
       oel.order_quantity_uom
           UNIT_OF_MEASUREMENT,
       oel.subinventory
           STORAGE_LOCATION,
       NULL
           PL_CODE2,
  oel.LINE_NUMBER||'.'||oel.SHIPMENT_NUMBER
           SALES_ORDER_LINE_NUMBER,
       hp.party_name
           CUSTOMER_NAME,
       hca.account_number
           CUSTOMER_NUMBER,
       hp.party_id
           SHIP_TO_CUSTOMER_ID,
       hp.party_name
           SHIP_TO_CUSTOMER_NAME,
          hl.address1
       || ' '
       || hl.address2
       || ' '
       || hl.address3
       || ' '
       || hl.address4
           SHIPTO_CUSTOMER_ADDRESS,
       hl.address2
           SHIPTO_CUSTOMER_STREET,
       hl.city
           SHIPTO_CUSTOMER_CITY,
       hl.county
           SHIPTO_CUSTOMER_DISTRICT,
       hl.country
           SHIPTO_CUSTOMER_COUNTRY,
       hl.postal_code
           POSTAL_CODE,
       hpc.party_name
           CARRIER_NAME,
       NULL
           INCOTERMS_PART2,
       NULL
           SPECIAL_SHIP_INSTRUCTIONS,
       NULL
           PROFORMA_INVOICE_NUMBER,
       NVL(wdd.ATTRIBUTE3,
              (SELECT COUNTRY
                 FROM HR_ORGANIZATION_UNITS_V
                WHERE organization_id = oeh.sold_from_org_id))
           COUNTRY_OF_ORGN,
       wnd.GROSS_WEIGHT,
       wnd.NET_WEIGHT,
       FDST.SHORT_TEXT NOTES,
  wnd.attribute1 NO_OF_BOXES,
  OEH.ATTRIBUTE14 AUTHORISED_BY,
  oel.LINE_NUMBER,
  oel.SHIPMENT_NUMBER
  FROM wsh_new_deliveries            wnd,
       wsh_delivery_assignments      wda,
       wsh_delivery_details          wdd,
       wsh_carrier_services          wcs,
       oe_order_headers_all          oeh,
       oe_order_lines_all            oel,
       org_organization_definitions  ood,
       mtl_material_transactions     mmt,
       hz_cust_accounts              hca,
       hz_parties                    hp,
       hz_cust_site_uses_all         hcsuas,
       hz_cust_acct_sites_all        hcasas,
       hz_party_sites                hps,
       hz_locations                  hl,
       hz_parties                    hpc,
       hz_party_usg_assignments      hpu,
       HR_organization_units         hou,
       hr_locations                  hzl,
       FND_DOCUMENTS_TL              FDT,
       FND_DOCUMENTS                 FD,
       FND_DOCUMENTS_SHORT_TEXT      FDST,
       FND_ATTACHED_DOCUMENTS        FAD
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
       AND oeh.sold_to_org_id = hca.cust_account_id
       AND hca.party_id = hp.party_id
       AND oeh.ship_to_org_id = hcsuas.site_use_id
       AND hcasas.cust_acct_site_id = hcsuas.cust_acct_site_id
       AND hps.party_site_id = hcasas.party_site_id
       AND hl.location_id = hps.location_id
       AND FDT.DOCUMENT_ID(+) = FD.DOCUMENT_ID
       AND FAD.DOCUMENT_ID = FD.DOCUMENT_ID(+)
       AND FD.MEDIA_ID = FDST.MEDIA_ID(+)
       AND FAD.PK1_VALUE(+) = TO_CHAR (OEH.HEADER_ID)
       AND FDT.LANGUAGE(+) = USERENV ('LANG')
       AND FAD.ENTITY_NAME(+) = 'OE_ORDER_HEADERS'
       AND hcsuas.site_use_code = 'SHIP_TO'
	   AND wdd.source_code = 'OE'
       AND wnd.delivery_id = :P_DELIVERY_ID --'15293946'                                 -- '15253947'  
  ORDER BY oel.LINE_NUMBER, oel.SHIPMENT_NUMBER