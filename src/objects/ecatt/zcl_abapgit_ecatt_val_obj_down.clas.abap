CLASS zcl_abapgit_ecatt_val_obj_down DEFINITION
  PUBLIC
  INHERITING FROM cl_apl_ecatt_download
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS:
      download REDEFINITION,

      get_xml_stream
        RETURNING
          VALUE(rv_xml_stream) TYPE xstring,

      get_xml_stream_size
        RETURNING
          VALUE(rv_xml_stream_size) TYPE int4.

  PROTECTED SECTION.
    DATA:
      li_objects_node TYPE REF TO if_ixml_element.

    METHODS:
      download_data REDEFINITION.

  PRIVATE SECTION.
    " downport missing types
    TYPES:
      BEGIN OF ecvo_bus_msg.
        INCLUDE TYPE etobj_key.
    TYPES:
      bus_msg_no   TYPE   etvo_msg_no,
      arbgb        TYPE   arbgb,
      msgnr        TYPE   msgnr,
      bus_msg_text TYPE etvo_bus_msg_text,
      otr_key      TYPE   sotr_conc,
      msg_type     TYPE   etvo_msg_type,
      END OF ecvo_bus_msg,

      etvo_bus_msg_tabtype   TYPE STANDARD TABLE OF ecvo_bus_msg,
      etvo_invert_validation TYPE c LENGTH 1,
      etvo_error_prio        TYPE n LENGTH 1,

      BEGIN OF etvoimpl_det,
        impl_name    TYPE c LENGTH 30,  " etvo_impl_name
        impl_type    TYPE c LENGTH 1,   " etvo_impl_type
        impl_subtype TYPE c LENGTH 4,   " etvo_impl_subtype
        impl_package TYPE c LENGTH 255, " etvo_package
      END OF etvoimpl_det.

    DATA:
      mv_xml_stream      TYPE xstring,
      mv_xml_stream_size TYPE int4.

    METHODS:
      set_ecatt_impl_detail,
      set_ecatt_flags,
      set_business_msgs.

ENDCLASS.



CLASS zcl_abapgit_ecatt_val_obj_down IMPLEMENTATION.


  METHOD download.

    " We inherit from CL_APL_ECATT_DOWNLOAD because CL_APL_ECATT_VO_DOWNLOAD
    " doesn't exist in 702

    " Downport

    DATA: lv_partyp TYPE string.

    load_help = im_load_help.
    typ = im_object_type.

    TRY.
        cl_apl_ecatt_object=>show_object(
          EXPORTING
            im_obj_type = im_object_type
            im_name     = im_object_name
            im_version  = im_object_version
          IMPORTING
            re_object   = ecatt_object ).
      CATCH cx_ecatt INTO ex_ecatt.
        RETURN.
    ENDTRY.

    lv_partyp = cl_apl_ecatt_const=>params_type_par.

    set_attributes_to_template( ).
    ecatt_vo ?= ecatt_object.
    set_ecatt_impl_detail( ).
    set_ecatt_flags( ).
    set_business_msgs( ).
    get_general_params_data( im_params = ecatt_vo->params
                             im_ptyp   = lv_partyp ).
    LOOP AT parm INTO wa_parm.
      set_general_params_data_to_dom( ).
      IF NOT wa_parm-val_type IS INITIAL.
        set_deep_stru_to_dom( ecatt_vo->params ).
        set_deep_data_to_dom( im_params = ecatt_vo->params
                              im_pindex = wa_parm-pindex ).
      ENDIF.
    ENDLOOP.

    set_variants_to_dom( ecatt_vo->params ).

    download_data( ).

  ENDMETHOD.


  METHOD download_data.

    " Downport

    zcl_abapgit_ecatt_helper=>download_data(
      EXPORTING
        ii_template_over_all = template_over_all
      IMPORTING
        ev_xml_stream        = mv_xml_stream
        ev_xml_stream_size   = mv_xml_stream_size ).

  ENDMETHOD.


  METHOD get_xml_stream.

    rv_xml_stream = mv_xml_stream.

  ENDMETHOD.


  METHOD get_xml_stream_size.

    rv_xml_stream_size = mv_xml_stream_size.

  ENDMETHOD.


  METHOD set_business_msgs.

    DATA:
      lt_buss_msg_ref   TYPE etvo_bus_msg_tabtype,
      li_element        TYPE REF TO if_ixml_element,
      li_insert_objects TYPE REF TO if_ixml_element.

    li_objects_node = template_over_all->create_simple_element(
                                           name   = 'BUSINESS_MESSAGES'
                                           parent = root_node ).

    ecatt_vo->get_bussiness_msg(
      IMPORTING
        ex_buss_msg_ref = lt_buss_msg_ref ).

    CALL FUNCTION 'SDIXML_DATA_TO_DOM'
      EXPORTING
        name         = 'ETVO_MSG'
        dataobject   = lt_buss_msg_ref
      IMPORTING
        data_as_dom  = li_element
      CHANGING
        document     = template_over_all
      EXCEPTIONS
        illegal_name = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    li_insert_objects = template_over_all->find_from_name( 'BUSINESS_MESSAGES' ).

    li_insert_objects->append_child( new_child = li_element ).

  ENDMETHOD.


  METHOD set_ecatt_flags.

    DATA:
      lv_invert_validation TYPE etvo_invert_validation,
      lv_error_prio        TYPE etvo_error_prio,
      li_element           TYPE REF TO if_ixml_element,
      li_insert_objects    TYPE REF TO if_ixml_element.

    li_objects_node = template_over_all->create_simple_element(
                                           name   = 'VO_FLAGS'
                                           parent = root_node ).

    lv_invert_validation = ecatt_vo->get_invert_validation_flag( ).

    CALL FUNCTION 'SDIXML_DATA_TO_DOM'
      EXPORTING
        name         = 'INVERT_VALIDATION'
        dataobject   = lv_invert_validation
      IMPORTING
        data_as_dom  = li_element
      CHANGING
        document     = template_over_all
      EXCEPTIONS
        illegal_name = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    li_insert_objects = template_over_all->find_from_name( 'VO_FLAGS' ).

    li_insert_objects->append_child( new_child = li_element ).

    lv_error_prio = ecatt_vo->get_error_priority( ).

    CALL FUNCTION 'SDIXML_DATA_TO_DOM'
      EXPORTING
        name         = 'ERROR_PRIORITY'
        dataobject   = lv_error_prio
      IMPORTING
        data_as_dom  = li_element
      CHANGING
        document     = template_over_all
      EXCEPTIONS
        illegal_name = 1
        OTHERS       = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    li_insert_objects = template_over_all->find_from_name( 'VO_FLAGS' ).

    li_insert_objects->append_child( new_child = li_element ).

  ENDMETHOD.


  METHOD set_ecatt_impl_detail.

    DATA:
      ls_impl_details   TYPE etvoimpl_det,
      li_element        TYPE REF TO if_ixml_element,
      li_insert_objects TYPE REF TO if_ixml_element.

    li_objects_node = template_over_all->create_simple_element(
                                           name   = 'IMPL_DETAILS'
                                           parent = root_node ).

    ls_impl_details = ecatt_vo->get_impl_details( ).

    CALL FUNCTION 'SDIXML_DATA_TO_DOM'
      EXPORTING
        name         = 'IMPL_DET'
        dataobject   = ls_impl_details
      IMPORTING
        data_as_dom  = li_element
      CHANGING
        document     = template_over_all
      EXCEPTIONS
        illegal_name = 1
        OTHERS       = 2.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    li_insert_objects = template_over_all->find_from_name( 'IMPL_DETAILS' ).

    li_insert_objects->append_child( new_child = li_element ).

  ENDMETHOD.
ENDCLASS.
