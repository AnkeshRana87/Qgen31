CREATE OR REPLACE PACKAGE BODY APPS.xxfil_bom_formula IS
   /***************************************************************************************************
    * Program Name :
    * Language     : PL/SQL
    * Description  : Specks for
    * History      :
    * WHO                                  Version #           WHEN                        WHAT
    * =======================================================================
    *                             1.0                     11-July-2025             Initial Version
    ***************************************************************************************************/

    PROCEDURE get_item_id (
        p_item    IN VARCHAR2,
        l_item_id OUT NUMBER,
        l_desc    OUT VARCHAR2
    ) IS
    BEGIN
        SELECT
            inventory_item_id,
            description
        INTO
            l_item_id,
            l_desc
        FROM
            mtl_system_items_b
        WHERE
                upper(segment1) = upper(p_item)
            AND ROWNUM = 1;

        fnd_file.put_line(fnd_file.log, 'in get_item_id: item='
                                        || p_item
                                        || ', id='
                                        || l_item_id
                                        || ', desc='
                                        || l_desc);

    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'Error in get_item_id: '
                                            || sqlcode
                                            || ' - '
                                            || sqlerrm);

            l_item_id := 0;
            l_desc := NULL;
    END get_item_id;

    PROCEDURE create_formula (
        p_batch_id IN NUMBER
    ) IS

        l_frmla_inst_tbl apps.gmd_formula_pub.formula_insert_hdr_tbl_type;
        l_return_status  VARCHAR2(1);
        l_msg_data       VARCHAR2(4000);
        l_msg_count      NUMBER;
        l_msg_ind        VARCHAR2(240);
        ln_suc_rec_cnt   NUMBER := 0;
        ln_rej_rec_cnt   NUMBER := 0;
        l_user_id        NUMBER := fnd_global.user_id;
        l_user_name      VARCHAR2(100) := fnd_global.user_name;
        l_version        NUMBER;
        l_count          NUMBER;
        l_line_no        NUMBER;
        x_item_id        NUMBER;
        x_desc           VARCHAR2(300);
        x_desc2          VARCHAR2(300);
		
        CURSOR cur_hdr IS
        SELECT
            product,
            SUM(nvl(TO_NUMBER(replace(replace(quantity, '-', ''),
                                      ',',
                                      '')),
                    0)) quantity
        FROM
            xxfil_bom_stg
        WHERE
                1 = 1
            AND upper(status) = 'APPROVED'
            AND batch_id = p_batch_id
            AND rm_code IS NOT NULL
        GROUP BY
            product;

        CURSOR cur_line (
            p_for_no VARCHAR2
        ) IS
        SELECT
            *
        FROM
            xxfil_bom_stg
        WHERE
                product = p_for_no
            AND batch_id = p_batch_id
            AND upper(status) = 'APPROVED'
            AND rm_code IS NOT NULL;

    BEGIN
        fnd_global.apps_initialize(gn_user_id, 22883, 552);
        FOR rec_hdr IN cur_hdr LOOP
         -- reset per header
            l_frmla_inst_tbl.DELETE;
            l_return_status := NULL;
            l_msg_data := NULL;
            l_msg_count := 0;
            l_count := 0;
            l_line_no := 0;
            BEGIN
            -- version
                SELECT
                    nvl(MAX(formula_vers),
                        0) + 1
                INTO l_version
                FROM
                    fm_form_mst
                WHERE
                    formula_no = rec_hdr.product;

            -- header line
                l_count := l_count + 1;
                get_item_id(rec_hdr.product, x_item_id, x_desc);
                l_frmla_inst_tbl(l_count).record_type := 'I';
                l_frmla_inst_tbl(l_count).formula_no := rec_hdr.product;
                l_frmla_inst_tbl(l_count).formula_vers := l_version;
                l_frmla_inst_tbl(l_count).formula_desc1 := x_desc;
                l_frmla_inst_tbl(l_count).total_input_qty := rec_hdr.quantity;         -- check auto calculate
                l_frmla_inst_tbl(l_count).total_output_qty := rec_hdr.quantity;         -- check auto calculate
                l_frmla_inst_tbl(l_count).formula_class := 'JUMBO_B';
                l_frmla_inst_tbl(l_count).inactive_ind := 0;
                l_frmla_inst_tbl(l_count).owner_organization_id := 89;
                l_frmla_inst_tbl(l_count).yield_uom := 'Kgs';
                l_frmla_inst_tbl(l_count).line_type := 1;
                l_frmla_inst_tbl(l_count).line_no := 1;
                l_frmla_inst_tbl(l_count).item_no := x_item_id;
                l_frmla_inst_tbl(l_count).inventory_item_id := x_item_id;
                l_frmla_inst_tbl(l_count).detail_uom := 'Kgs';
                l_frmla_inst_tbl(l_count).release_type := 3;
                l_frmla_inst_tbl(l_count).scrap_factor := 0;
                l_frmla_inst_tbl(l_count).scale_type_hdr := 1;
                l_frmla_inst_tbl(l_count).scale_type_dtl := 1;
                l_frmla_inst_tbl(l_count).cost_alloc := 1;
                l_frmla_inst_tbl(l_count).phantom_type := 0;
                l_frmla_inst_tbl(l_count).rework_type := 0;
                l_frmla_inst_tbl(l_count).buffer_ind := 0;
                l_frmla_inst_tbl(l_count).contribute_yield_ind := 'Y';
                l_frmla_inst_tbl(l_count).scale_uom := 'Y';
                l_frmla_inst_tbl(l_count).contribute_step_qty_ind := 'Y';
                l_frmla_inst_tbl(l_count).qty := rec_hdr.quantity;
                l_frmla_inst_tbl(l_count).user_id := l_user_id;
                l_frmla_inst_tbl(l_count).creation_date := sysdate;
                l_frmla_inst_tbl(l_count).last_update_date := sysdate;
                l_frmla_inst_tbl(l_count).last_update_login := gn_login_id;

            -- ingredient lines
                FOR rec_line IN cur_line(rec_hdr.product) LOOP
                    l_count := l_count + 1;
                    l_line_no := l_line_no + 1;
                    get_item_id(rec_line.rm_code, x_item_id, x_desc2);
                    l_frmla_inst_tbl(l_count).record_type := 'I';
                    l_frmla_inst_tbl(l_count).formula_no := rec_hdr.product;
                    l_frmla_inst_tbl(l_count).formula_vers := l_version;
                    l_frmla_inst_tbl(l_count).formula_desc1 := x_desc;
                    l_frmla_inst_tbl(l_count).total_input_qty := TO_NUMBER ( replace(rec_hdr.quantity, ',', '') );

                    l_frmla_inst_tbl(l_count).total_output_qty := TO_NUMBER ( replace(rec_hdr.quantity, ',', '') );

                    l_frmla_inst_tbl(l_count).formula_class := 'JUMBO_B';
                    l_frmla_inst_tbl(l_count).inactive_ind := 0;
                    l_frmla_inst_tbl(l_count).owner_organization_id := 89;
                    l_frmla_inst_tbl(l_count).yield_uom := 'Kgs';
                    l_frmla_inst_tbl(l_count).line_type := -1;
                    l_frmla_inst_tbl(l_count).line_no := l_line_no;
                    l_frmla_inst_tbl(l_count).item_no := rec_line.rm_code;
                    l_frmla_inst_tbl(l_count).inventory_item_id := x_item_id;
                    l_frmla_inst_tbl(l_count).qty := TO_NUMBER ( replace(rec_line.quantity, ',', '') );

                    l_frmla_inst_tbl(l_count).detail_uom := 'Kgs';
                    l_frmla_inst_tbl(l_count).release_type := 3;
                    l_frmla_inst_tbl(l_count).scrap_factor := 0;
                    l_frmla_inst_tbl(l_count).scale_type_hdr := 1;
                    l_frmla_inst_tbl(l_count).scale_type_dtl := 1;
                    l_frmla_inst_tbl(l_count).cost_alloc := 1;
                    l_frmla_inst_tbl(l_count).phantom_type := 0;
                    l_frmla_inst_tbl(l_count).rework_type := 0;
                    l_frmla_inst_tbl(l_count).buffer_ind := 0;
                    l_frmla_inst_tbl(l_count).contribute_yield_ind := 'Y';
                    l_frmla_inst_tbl(l_count).scale_uom := 'Y';
                    l_frmla_inst_tbl(l_count).contribute_step_qty_ind := 'Y';
                    l_frmla_inst_tbl(l_count).user_id := l_user_id;
                    l_frmla_inst_tbl(l_count).last_update_date := sysdate;
                END LOOP;

            -- call API per header
                apps.gmd_formula_pub.insert_formula(p_api_version => '1.0', p_init_msg_list => 'T', p_commit => 'T', p_called_from_forms => 'NO'
                , x_return_status => l_return_status,
                                                   x_msg_count => l_msg_count, x_msg_data => l_msg_data, p_formula_header_tbl => l_frmla_inst_tbl
                                                   , p_allow_zero_ing_qty => 'FALSE');

            -- log and count
                IF l_return_status = 'S' THEN
                    ln_suc_rec_cnt := ln_suc_rec_cnt + 1;
                    fnd_file.put_line(fnd_file.log, 'Success: '
                                                    || rec_hdr.product
                                                    || '      VERSION: '
                                                    || l_version);    
                    
                 -- update new version of created formula
                    UPDATE xxfil_bom_stg
                    SET
                        version = l_version
                    WHERE
                            batch_id = p_batch_id
                        AND product = rec_hdr.product;

                ELSE
                    ln_rej_rec_cnt := ln_rej_rec_cnt + 1;
                    fnd_file.put_line(fnd_file.log, 'Failed: ' || rec_hdr.product);
                    FOR i IN 1..l_msg_count LOOP
                        apps.fnd_msg_pub.get(p_msg_index => i, p_encoded => 'F', p_data => l_msg_data, p_msg_index_out => l_msg_ind);

                        fnd_file.put_line(fnd_file.log, 'Error: ' || l_msg_data);
                    END LOOP;

                END IF;

            EXCEPTION
                WHEN OTHERS THEN
                    fnd_file.put_line(fnd_file.log, 'Header error: '
                                                    || rec_hdr.product
                                                    || ' - '
                                                    || sqlcode
                                                    || '/'
                                                    || sqlerrm);
            END;

        END LOOP;

        fnd_file.put_line(fnd_file.log, 'Totals - Success:'
                                        || ln_suc_rec_cnt
                                        || ', Reject:'
                                        || ln_rej_rec_cnt);

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'create_formula error: '
                                            || sqlcode
                                            || '/'
                                            || sqlerrm);
    END create_formula;

    PROCEDURE main (
        errbuf     OUT VARCHAR2,
        retcode    OUT NUMBER,
        p_batch_id IN NUMBER
    ) IS
    BEGIN
        fnd_file.put_line(fnd_file.log, 'main start');
        create_formula(p_batch_id);
    EXCEPTION
        WHEN OTHERS THEN
            fnd_file.put_line(fnd_file.log, 'main error: '
                                            || sqlcode
                                            || '/'
                                            || sqlerrm);
    END main;

END xxfil_bom_formula;
/
