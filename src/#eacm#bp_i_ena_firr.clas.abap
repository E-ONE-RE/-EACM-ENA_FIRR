CLASS /eacm/bp_i_ena_firr DEFINITION
  PUBLIC
  ABSTRACT
  FINAL
  FOR BEHAVIOR OF /EACM/I_ENA_FIRR.

  PUBLIC SECTION.
    CLASS-DATA gt_ena_firr TYPE STANDARD TABLE OF /eacm/ena_firr.

    TYPES:
      BEGIN OF ty_delete_ena_firr,
        bukrs  TYPE bukrs,
        gjahr  TYPE gjahr,
        zcdage TYPE /eacm/ena_firr-zcdage,
        ztpag  TYPE /eacm/ena_firr-paymenttype,
        lifnr  TYPE lifnr,
      END OF ty_delete_ena_firr.

    CLASS-DATA gt_delete TYPE SORTED TABLE OF ty_delete_ena_firr
      WITH UNIQUE KEY bukrs gjahr zcdage ztpag lifnr.
ENDCLASS.



CLASS /EACM/BP_I_ENA_FIRR IMPLEMENTATION.
ENDCLASS.
