public class patientWrapper {

  public Integer PatientID;
  public Integer fk_BranchID;
  public String fk_BranchName;
  public Integer fk_MarketingRepID;
  public String fk_MarketingRepName;
  public Integer fk_FacilityID;
  public String fk_FacilityName;
  public Integer fk_TaxZoneID;
  public String fk_TaxZoneName;
  public Integer fk_CustomerTypeID;
  public String fk_CustomerTypeName;
  public Integer fk_BillingCountyID;
  public String fk_BillingCountyName;
  public Integer fk_BillingCountryID;
  public String fk_BillingCountryName;
  public Integer fk_MaritalStatusID;
  public String fk_MaritalStatusName;
  public Integer fk_DeliveryCountyID;
  public String fk_DeliveryCountyName;
  public Integer fk_DeliveryCountryID;
  public String fk_DeliveryCountryName;
  public Integer fk_DeliveryStateID;
  public String fk_DeliveryStateName;
  public Integer fk_ECCountryID;
  public String fk_ECCountryName;
  public Integer fk_ECStateID;
  public String fk_ECStateName;
  public Integer fk_ECRelationshipID;
  public String fk_ECRelationshipName;
  public Integer fk_RPRelationshipID;
  public String fk_RPRelationshipName;
  public Integer fk_RPCountryID;
  public String fk_RPCountryName;
  public Integer fk_RPStateID;
  public String fk_RPStateName;
  public Integer fk_PenTipsOrSyringesID;
  public String fk_PenTipsOrSyringesName;
  public Integer fk_InjectionsPerDayID;
  public String fk_InjectionsPerDayName;
  public Integer fk_IPSSupplierID;
  public String fk_IPSSupplierName;
  public Integer fk_CGMSupplierID;
  public String fk_CGMSupplierName;
  public Integer fk_TestStripModelID;
  public String fk_TestStripModelName;
  public Integer fk_TimesTestingID;
  public String fk_TimesTestingName;
  public Integer fk_CurrentPumpModelID;
  public String fk_CurrentPumpModelName;
  public Integer fk_CGMModelID;
  public String fk_CGMModelName;
  public Integer fk_PreferredMethodOfContactID;
  public String fk_PreferredMethodOfContactName;
  public Integer fk_PreferredMethodOfReorderID;
  public String fk_PreferredMethodOfReorderName;
  public Integer fk_NcpdpPtResidenceCodeID;
  public String fk_NcpdpPtResidenceCodeName;
  public Integer fk_GenderID;
  public String fk_GenderName;
  public Integer fk_EmploymentID;
  public String fk_EmploymentName;
  public Integer fk_FunctionalAbilityID;
  public String fk_FunctionalAbilityName;
  public Integer fk_POSID;
  public String fk_POSName;
  public Integer fk_PractitionerID;
  public String fk_PractitionerName;
  public Integer fk_PTSecurityGroupID;
  public String fk_PTSecurityGroupName;
  public String MiddleName;
  public String FaxNumber;
  public String EmailAddress;
  public String MobilePhone;
  public String Suffix;
  public String DOD;
  public String DateOfAdmission;
  public String DateOfDischarge;
  public String DateOfOnset;
  public String StateOfAutoAccident;
  public String SSN;
  public Boolean HoldAcct;
  public String Height;
  public String Weight;
  public String Employment;
  public Integer DiscountPct;
  public String AccountNumber;
  public Integer AlternateTypeID;
  public String DelivAddress1;
  public String DelivAddress2;
  public String DeliveryCity;
  public String DeliveryZip;
  public String DeliveryPhone;
  public Integer DocumentID;
  public String ECLastName;
  public String ECFirstName;
  public String ECMiddleName;
  public String ECAddress1;
  public String ECAddress2;
  public String ECCity;
  public String ECPostalCode;
  public String ECMobile;
  public String ECPhoneNumber;
  public String ECFax;
  public String ECEmail;
  public String ReferralType;
  public Integer ReferralKey;
  public String ReferringProviderType;
  public String RenderingProviderType;
  public String RPLastName;
  public String RPFirstName;
  public String RPMiddleName;
  public String RPAddress1;
  public String RPAddress2;
  public String RPCity;
  public String RPPostalCode;
  public String RPMobile;
  public String RPPhoneNumber;
  public String RPFax;
  public String RPEmail;
  public Boolean HIPPASignatureOnFile;
  public Boolean PatientConditionDiabetes;
  public Boolean OptOut_Email;
  public Boolean OptOut_EmailText;
  public Boolean OptOut_IVRCall;
  public Boolean OptOut_Text;
  public Boolean OptOut_Web;
  public Integer CreatedBy;
  public String CreatedDate;
  public Integer ModifiedBy;
  public String ModifiedDate;
  public Boolean SendToSF;
  public List<ExternalAppIDs> ExternalAppIDs;
  public List<Manufacturers> Manufacturers;
  public List<Patient_DiagnosisCodesList> Patient_DiagnosisCodesList;
  public String PatientHubID;
  public String FirstName;
  public String LastName;
  public String DOB;
  public String BillingAddress1;
  public String BillingAddress2;
  public String BillingCity;
  public String BillingZip;
  public String BillingPhone;
  public Integer fk_BillingStateID;
  public String fk_BillingStateName;
  public Integer fk_AccountGroupID;
  public String fk_AccountGroupName;

  public class Patient_DiagnosisCodesList {
    public Integer ID;
    public Integer fk_PatientID;
    public Integer fk_DiagnosisID;
    public Integer fk_ICDCodeTypeID;
    public String fk_ICDCodeTypeName;
    public String ICDCode;
    public String ShortDescription;
    public Integer PtDiagKey;
  }

  public class ExternalAppIDs {
    public Integer AppID;
    public String AppName;
    public String ExternalID;
    public String ExternalKey;
  }

  public class Manufacturers {
    public Integer PatientToManufacturerID;
    public Integer ManufacturerID;
    public String PatientNumber;
  }

  
  public static PatientWrapper parse(String json) {
    return (PatientWrapper) System.JSON.deserialize(json, PatientWrapper.class);
  }
}