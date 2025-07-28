options (skip=1)
LOAD DATA
INFILE 'item_creation2.csv'
INTO TABLE xxqgen_item_stg_ar
APPEND
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  transaction_type,
  segment1							"TRIM(:segment1)",
  description						"TRIM(:description)",
  long_description					"TRIM(:long_description)",
  organization_code					"TRIM(:organization_code)",
  template_name 					"TRIM(:template_name)",
  inventory_item_status_code		"TRIM(:inventory_item_status_code)",
  approval_status					"TRIM(:approval_status)",
  apply_template					"TRIM(REPLACE(REPLACE(:APPLY_TEMPLATE, CHR(10), ''), CHR(13), ''))",
  request_id              			CONSTANT 1000,
  created_by               			CONSTANT 1318,
  creation_date            			SYSDATE,
  last_update_date         			SYSDATE,
  last_updated_by          			CONSTANT 1318,
  record_id                			SEQUENCE(MAX,1)
)
