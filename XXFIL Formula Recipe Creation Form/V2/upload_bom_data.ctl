options (skip=1)
LOAD DATA
INFILE '/a01/install/DEV/fs1/EBSapps/appl/xxfil/12.0.0/bin/UPLOAD_BOM_DATA_TEST.csv'
INTO TABLE XXFIL_BOM_STG
APPEND
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
  Product,
  RM_Code							"TRIM(:RM_Code)",
  RM_Description					"TRIM(:RM_Description)",
  Quantity							"TRIM(:Quantity)",
  Avg_Speed							"TRIM(:Avg_Speed)",
  Width 							"TRIM(:Width)",
  PRODUCTION_LINE 						"TRIM(:PRODUCTION_LINE)"
)
