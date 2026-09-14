@EndUserText.label: 'Parametri calcolo ENA/FIRR'
define abstract entity /EACM/A_ENA_FIRR_CALC_PARAM
{
  @EndUserText.label: 'Societa'
  CompanyCode : bukrs;

  @EndUserText.label: 'Esercizio'
  FiscalYear : gjahr;

  @EndUserText.label: 'Agente'
  Zcdaz : /eacm/zcdaz; 

  @EndUserText.label: 'Tipo pagamento'
  Ztpag : /eacm/ztpag;

  @EndUserText.label: 'Fornitore'
  Lifnr : lifnr;
}
