@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dichiarazione versamenti Enasarco'
@Metadata.allowExtensions: true
define root view entity /EACM/C_ENA_FIRR
  provider contract transactional_query
  as projection on /EACM/I_ENA_FIRR
{
  @UI.lineItem: [
    { position: 10, label: 'Societa' },
    { type: #FOR_ACTION, dataAction: 'CalculateAndCreatePdfs', label: 'Calcola e crea PDF' }
  ]
  @UI.selectionField: [{ position: 10 }]
  key CompanyCode,

  @UI.lineItem: [{ position: 20, label: 'Esercizio' }]
  @UI.selectionField: [{ position: 20 }]
  key FiscalYear,

  @UI.lineItem: [{ position: 30, label: 'Agente' }]
  @UI.selectionField: [{ position: 30 }]
  key AgentCode,

  @UI.lineItem: [{ position: 40, label: 'Fornitore' }]
  @UI.selectionField: [{ position: 50 }]
  key Supplier,

  CompanyName,
  CompanyCountry,
  CompanyCity,
  CompanyPostCode,
  CompanyStreet,
  CompanyHouseNumber,
  CompanyRegion,
  CompanyVatNumber,

  TransactionCurrency,

  @UI.lineItem: [{ position: 50, label: 'Nome agente' }]
  AgentName,

  AgentCountry,
  AgentCity,
  AgentPostCode,
  AgentStreet,
  AgentHouseNumber,
  AgentRegion,
  AgentVatNumber,

  @UI.selectionField: [{ position: 40 }]
  PaymentType,
  EnasarcoScope,

  @UI.lineItem: [{ position: 60, label: 'FIRR maturato' }]
  FirrMaturedCommission,

  @UI.lineItem: [{ position: 70, label: 'FIRR contributo' }]
  FirrContribution,

  HasFirrContribution,
  FirrRate,

  @UI.lineItem: [{ position: 80, label: 'Enasarco agente' }]
  EnasarcoAgentContribution,

  @UI.lineItem: [{ position: 90, label: 'Versato' }]
  EnasarcoPaidAmount,

  CessationDate,
  IsCessationInYear,
  ServiceDescription,

  @UI.hidden: true
  FileName,

  @UI.hidden: true
  MimeType,

  @UI.lineItem: [{ position: 100, label: 'PDF' }]
  Attachment
}
