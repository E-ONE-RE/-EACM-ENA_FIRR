@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Dichiarazione versamenti Enasarco'
@Metadata.allowExtensions: true
@ObjectModel.supportedCapabilities: [ #OUTPUT_FORM_DATA_PROVIDER ]
define root view entity /EACM/I_ENA_FIRR
  as select from /eacm/ena_firr
{
  key bukrs as CompanyCode,
  key gjahr  as FiscalYear,
  key zcdage as AgentCode,
  key lifnr  as Supplier,

  bukrs_name       as CompanyName,
  bukrs_country    as CompanyCountry,
  bukrs_city       as CompanyCity,
  bukrs_post_code  as CompanyPostCode,
  bukrs_street     as CompanyStreet,
  bukrs_house_num  as CompanyHouseNumber,
  bukrs_region     as CompanyRegion,
  bukrs_piva       as CompanyVatNumber,

  currency as TransactionCurrency,

  age_name       as AgentName,
  age_country    as AgentCountry,
  age_city       as AgentCity,
  age_post_code  as AgentPostCode,
  age_street     as AgentStreet,
  age_house_num  as AgentHouseNumber,
  age_region     as AgentRegion,
  age_piva       as AgentVatNumber,

  paymenttype   as PaymentType,
  enasarcoscope as EnasarcoScope,

  @Semantics.amount.currencyCode: 'TransactionCurrency'
  firrmaturedcommission as FirrMaturedCommission,

  @Semantics.amount.currencyCode: 'TransactionCurrency'
  firrcontribution as FirrContribution,

  hasfirrcontribution as HasFirrContribution,
  firrrate            as FirrRate,

  @Semantics.amount.currencyCode: 'TransactionCurrency'
  enasarcoagentcontribution as EnasarcoAgentContribution,

  @Semantics.amount.currencyCode: 'TransactionCurrency'
  enasarcopaidamount as EnasarcoPaidAmount,

  cessationdate      as CessationDate,
  iscessationinyear  as IsCessationInYear,
  servicedescription as ServiceDescription,

  @UI.hidden: true
  filename as FileName,

  @UI.hidden: true
  @Semantics.mimeType: true
  mime_type as MimeType,

  @Semantics.largeObject: {
    mimeType: 'MimeType',
    fileName: 'FileName',
    acceptableMimeTypes: [ 'application/pdf' ],
    contentDispositionPreference: #ATTACHMENT
  }
  attachment as Attachment
}

