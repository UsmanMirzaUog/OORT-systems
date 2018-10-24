public with sharing class SolaraHubIntegration {
	
    public static String apiBaseUrl = BrightTree__c.getInstance('apiBaseUrl') == null ? '' : BrightTree__c.getInstance('apiBaseUrl').Value__c;
    public static Map<Id, Account> mapIdToAccount;
    public static Map<Id, List<OpportunityLineItem>> mapOppIdToLineItemList;

    public SolaraHubIntegration() {
    }


    @future(callout=true)
    public static void callHubService(String serviceCustomSettingName, String verbMethod, String theJson) {

        // this method is a future method where a response wouldn't be expected

        Map<String, String> optionsMap = createOptionsMap(serviceCustomSettingName, verbMethod);
        
        HttpRequest req = createHttpRequest(optionsMap, thejson);
        HttpResponse res = sendHttpRequest(req);

        if (res != null && res.getStatusCode() != 200  && (!Test.isRunningTest())) {
            Utils.logIntegrationIssue(thejson, 'Status: ' + res.getStatusCode() + ': ' + res.getStatus() + '<br><br>' + res.getBody(), serviceCustomSettingName);
        } 
    }

    @future(callout=true)
    public static void callHubService(String serviceCustomSettingName, String verbMethod, String theJson, Id theTaskId, Boolean taskUpdate) {

        // this method is a future method where a response wouldn't be expected

        Map<String, String> optionsMap = createOptionsMap(serviceCustomSettingName, verbMethod);
        
        HttpRequest req = createHttpRequest(optionsMap, thejson);
        HttpResponse res = sendHttpRequest(req);

        if (res != null && res.getStatusCode() != 200  && (!Test.isRunningTest())) {
            Utils.logIntegrationIssue(thejson, 'Status: ' + res.getStatusCode() + ': ' + res.getStatus() + '<br><br>' + res.getBody(), serviceCustomSettingName);
        } else {
            Task t = new Task();
            t.Id = theTaskId;
            t.Successful_Send_To_Hub__c = true;
            update t;
        }
    }

    public static void callHubService(String serviceCustomSettingName, String verbMethod, String theJson, Id theProviderId) {

        // this method is an overload future method where a response with provider data would be expected

        Map<String, String> optionsMap = createOptionsMap(serviceCustomSettingName, verbMethod);
        
        HttpRequest req = createHttpRequest(optionsMap, thejson);
        HttpResponse res = sendHttpRequest(req);

        if (res != null && (res.getStatusCode() != 200 && res.getStatusCode() != 404)  && (!Test.isRunningTest())) {
            System.debug('should have emailed');
            Utils.logIntegrationIssue(thejson, 'Status: ' + res.getStatusCode() + ': ' + res.getStatus() + '<br><br>' + res.getBody(), serviceCustomSettingName);
        } else {
            if (serviceCustomSettingName == 'getStandardAddress'  && (!Test.isRunningTest())){
                System.debug('should have handled');
                handleProviderAddressResponse(res.getBody(), theProviderId);
            }
        }
    }

    public static String callHubService(String serviceCustomSettingName, String verbMethod, String theJson, String theParams) {

        // this method is a overload synchronous method where a response would be expected
        // takes in params where necessary

        Map<String, String> optionsMap = new Map<String, String>();

        if (theParams != '') {
            optionsMap = createOptionsMap(serviceCustomSettingName, verbMethod, theParams);
        } else {
            optionsMap = createOptionsMap(serviceCustomSettingName, verbMethod);
        }


        
        HttpRequest req = createHttpRequest(optionsMap, thejson);
        HttpResponse res = sendHttpRequest(req);

        if (res != null && res.getStatusCode() != 200  && (!Test.isRunningTest())) {
            Utils.logIntegrationIssue(thejson, 'Status: ' + res.getStatusCode() + ': ' + res.getStatus() + '<br><br>' + res.getBody(), serviceCustomSettingName);
            return null;
        } else {
            return res.getBody();
        }
    }

    @future(callout=true)
    public static void createSalesOrderUpdateOptions(String jsonInfo) {
        //extract opp Id
        List<Object> infoList = (List<Object>)JSON.deserializeUntyped(jsonInfo);

        //TODO: If this needs to process multiple sales order, then wrap the infoList in a for loop. Watch out for API callout limits

        Map<String, Object> infoMap = (Map<String, Object>)infoList[0];

        Id theOpportunityId = (Id)infoMap.get('oppId');
        Id theBillingId = (Id)infoMap.get('addressId');
        Id theDeliveryId = (Id)infoMap.get('deliveryAddressId');
        Id thePrescribingProviderId = (Id)infoMap.get('orderingProviderId');
        Id thePCPId = (Id)infoMap.get('primaryProviderId');

        system.debug(theOpportunityId);
        system.debug(theBillingId);
        system.debug(theDeliveryId);
        system.debug(thePrescribingProviderId);
        system.debug(thePCPId);

        /*Map of opps*/
        Map<Id, Opportunity> mapOppIdToOpp = new Map<Id, Opportunity>([SELECT Id, BrightTree_Order_Id__c, SolaraPatientID__c, AccountId, External_Id__c, CreatedDate, CreatedById, CreatedBy.Name FROM Opportunity WHERE Id =: theOpportunityId]);
        mapIdToAccount = new Map<Id, Account>([
                SELECT Id, FirstName, LastName, ShippingStreet, ShippingCity, ShippingPostalCode, ShippingState, ShippingCountry, Active__c, External_Id__c,
                        Date_Of_Birth__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry, Phone, Preferred_Method_of_Contact__c,
                        Email__c, Gender__c, AccountNumber, PersonEmail, PersonHomePhone, Preferred_Name__pc, Preferred_Communication__pc, PersonBirthDate, Gender__pc, Brand_of_Test_Strips__c, Current_Pump__c, Times_Injecting_per_Day__c, Times_Testing_per_Day__c
                FROM Account
                WHERE Id IN (SELECT AccountId FROM Opportunity WHERE Id =: theOpportunityId)]);
        Map<Id, OpportunityLineItem> mapIdToLineItemList = new Map<Id, OpportunityLineItem>([SELECT Id, Quantity, External_Id__c, OpportunityId, Product2.External_Id__c, Product2.Name, Product2.Item_ID__c FROM OpportunityLineItem WHERE OpportunityId IN : mapOppIdToOpp.keySet()]);
        mapOppIdToLineItemList = new Map<Id, List<OpportunityLineItem>>();
        for(Id oppId : mapOppIdToOpp.keySet()) {
            mapOppIdToLineItemList.put(oppId, new List<OpportunityLineItem>());
        }
        for(OpportunityLineItem lineItem : mapIdToLineItemList.values()) {
            mapOppIdToLineItemList.get(lineItem.OpportunityId).add(lineItem);
        }
        /*Addresses, Providers, and Payors*/
        //theOpportunityId will always be (006) (Opportunity)
        //theBillingId will always be (a02) (Address_Data__c)
        //theDeliveryId can be (a08,a02) (Provider,Address_Data__c)
        //thePrescribingProviderId will always be (a08) (Provider)
        //thePCPId will always be (a08) (Provider)

        Set<Id> providerIdSet = new Set<Id>{thePrescribingProviderId,thePCPId};
        Set<Id> addressIdSet = new Set<Id>{theBillingId};
        if(Schema.Provider__c.SObjectType == theDeliveryId.getSobjectType()) {
            providerIdSet.add(theDeliveryId);
        } else {
            addressIdSet.add(theDeliveryId);
        }

        Map<Id, Provider__c> mapProviderId = new Map<Id, Provider__c>([SELECT Id, Name, State__c, City__c, Address__c, Address2__c, Zip__c, External_Id__c FROM Provider__c WHERE Id IN : providerIdSet]);
        Map<Id, Address_Data__c> mapAddressDataId = new Map<Id, Address_Data__c>([SELECT Id, Name, State_Province__c, City__c, Street__c, Zip_Postal_Code__c, Primary__c FROM Address_Data__c WHERE Id IN : addressIdSet]);
        Map<Id, Insurance_Patient_Junction__c> mapPayorJunctionId = new Map<Id, Insurance_Patient_Junction__c>([SELECT Insurance__c, Account__c, External_Id__c, Policy_Level__c, Account__r.External_Id__c, Insurance__r.External_Id__c, Insurance__r.Insurance_Co_Name__c FROM Insurance_Patient_Junction__c WHERE Account__c IN : mapIdToAccount.keySet()]);

        Map<Id, SObject> mapIdToSObject = new Map<Id, SObject>();
        for(Provider__c theProvider : mapProviderId.values()) {
            mapIdToSObject.put(theProvider.Id, theProvider);
        }
        for(Address_Data__c theAddressData : mapAddressDataId.values()) {
            mapIdToSObject.put(theAddressData.Id, theAddressData);
        }

        /* The Address Data */
        List<addresses> theAddresses = new List<addresses>();
        theAddresses.add(new addresses(mapIdToSObject.get(theBillingId), 'BillingAddress'));
        theAddresses.add(new addresses(mapIdToSObject.get(theDeliveryId), 'ShippingAddress'));

        /* The Provider Data */
        List<patientProviders> theProviders = new List<patientProviders>();
        if(thePrescribingProviderId == thePCPId) {
            theProviders.add(new patientProviders(mapIdToAccount.values()[0], (Provider__c)mapIdToSObject.get(thePrescribingProviderId), 'Prescribing,PCP'));
        } else {
            theProviders.add(new patientProviders(mapIdToAccount.values()[0], (Provider__c)mapIdToSObject.get(thePrescribingProviderId), 'Prescribing'));
            theProviders.add(new patientProviders(mapIdToAccount.values()[0], (Provider__c)mapIdToSObject.get(thePCPId), 'PCP'));
        }

        /* The Payor Data */
        List<patientPayors> thePayors = new List<patientPayors>();
        for(Insurance_Patient_Junction__c thePayorJunction : mapPayorJunctionId.values()) {
            thePayors.add(new patientPayors(thePayorJunction));
        }

        /*Set Endpoint*/
        String apiBaseUrl = BrightTree__c.getInstance('apiBaseUrl') == null ? '' : BrightTree__c.getInstance('apiBaseUrl').Value__c;
        String createPatientSalesOrder = BrightTree__c.getInstance('createPatientSalesOrder') == null ? '' : BrightTree__c.getInstance('createPatientSalesOrder').Value__c;
        String updatePatient = BrightTree__c.getInstance('updatePatient') == null ? '' : BrightTree__c.getInstance('updatePatient').Value__c;
        if(apiBaseUrl == '' || createPatientSalesOrder == '') return;
        String endpointUpdateSalesOrder =  apiBaseUrl + createPatientSalesOrder;
        String endpointUpdatePatient =  apiBaseUrl + updatePatient;
        //String endpointDexcomLead = apiBaseUrl + update

        /*Authorization Header*/
        String username = BrightTree__c.getInstance('username') == null ? '' : BrightTree__c.getInstance('username').Value__c;
        String password = BrightTree__c.getInstance('password') == null ? '' : BrightTree__c.getInstance('password').Value__c;
        if(username == '' || password == '') return;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);

        /*Map of options for http callout*/
        Map<String, String> optionsMap = new Map<String, String>{'endpointUpdateSalesOrder' => endpointUpdateSalesOrder,'endpointUpdatePatient' =>  endpointUpdatePatient, 'verbMethod' => 'POST', 'timeout' => '20000', 'authorizationHeader' => authorizationHeader, 'cache-control' => 'no-cache', 'Content-Type' => 'application/json'};


        /*Constructing the request body and sending it*/
        for(Opportunity theOppty : mapOppIdToOpp.values()) { //There will only be 1 in the map
            updatePatient(optionsMap, mapIdToAccount.values()[0]);
            updatePatientSalesOrderWithOptions(optionsMap, theOppty, theAddresses, theProviders, thePayors);
        }
    }

    public static void updatePatient(Map<String, String> optionsMap, Account theAccount) {
        HttpRequest req = createHttpRequest(optionsMap, theAccount);
        HttpResponse res = sendHttpRequest(req);
    }

    public static void updatePatientSalesOrderWithOptions(Map<String, String> optionsMap, Opportunity theOppty, List<addresses> theAddresses, List<patientProviders> theProviders, List<patientPayors> thePayors){
        HttpRequest req = createHttpRequest(optionsMap, theOppty, theAddresses, theProviders, thePayors);
        HttpResponse res = sendHttpRequest(req);
    }

    public static HttpRequest createHttpRequest(Map<String, String> optionsMap, Opportunity theOpportunity, List<addresses> theAddresses, List<patientProviders> theProviders, List<patientPayors> thePayors) {
        //Creating Body Request
        SalesOrderWrapper theOrder = new SalesOrderWrapper(theOpportunity, theProviders, thePayors, theAddresses);

        //Creating the Http Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(optionsMap.get('endpointUpdateSalesOrder'));
        req.setMethod(optionsMap.get('verbMethod'));
        req.setTimeout(Integer.valueOf(optionsMap.get('timeout')));
        req.setHeader('Authorization', optionsMap.get('authorizationHeader'));
        req.setHeader('cache-control', optionsMap.get('cache-control'));
        req.setHeader('Content-Type', optionsMap.get('Content-Type'));
        req.setBody(JSON.serialize(theOrder, true));
        system.debug(JSON.serialize(theOrder, true));
        return req;
    }

    public static HttpRequest createHttpRequest(Map<String, String> optionsMap, Account theAccount) {
        //Creating Body Request
        thePatientWrapper thePatient = new thePatientWrapper(theAccount);
        //Creating the Http Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(optionsMap.get('endpointUpdatePatient'));
        req.setMethod(optionsMap.get('verbMethod'));
        req.setTimeout(Integer.valueOf(optionsMap.get('timeout')));
        req.setHeader('Authorization', optionsMap.get('authorizationHeader'));
        req.setHeader('cache-control', optionsMap.get('cache-control'));
        req.setHeader('Content-Type', optionsMap.get('Content-Type'));
        req.setBody(JSON.serialize(thePatient, true));
        system.debug(JSON.serialize(thePatient, true));
        return req;
    }

    public static void handleProviderAddressResponse(String theResponseJson, String providerId) {
        System.debug(theResponseJson);
        System.debug(providerId);

        AddressResponseWrapper addResp;

            List<Provider__c> updateProvs = new List<Provider__c>();


            if (theResponseJson != null) {
                addResp = AddressResponseWrapper.parse(theResponseJson);
            }
            System.debug(String.valueOf(addResp));
            System.debug(addResp);

            Provider__c providerUpdate = new Provider__c();
            providerUpdate.Id = providerId;
            providerUpdate.Address_Clean__c = addResp.AddressLine1;
            providerUpdate.Address2_Clean__c = addResp.AddressLine2;
            providerUpdate.Address3_Clean__c = addResp.AddressLine3;
            providerUpdate.City_Clean__c = addResp.City;
            providerUpdate.State_Clean__c = addResp.State;
            providerUpdate.Zip_Clean__c = addResp.ZipOrPostalCode;
            providerUpdate.Address_Verified__c = addResp.AddressVerified;
            providerUpdate.Message__c = addResp.Message;


            updateProvs.add(providerUpdate);

            if (updateProvs.size() > 0) update updateProvs;
    }

    public static Map<String, String> createOptionsMap(String serviceCustomSettingName, String verbMethod) {
        String serviceURL = BrightTree__c.getInstance(serviceCustomSettingName) == null ? '' : BrightTree__c.getInstance(serviceCustomSettingName).Value__c;
        if(apiBaseUrl == '' || serviceURL == '') return null;
    
        String endpointWithService = apiBaseUrl + serviceURL;
        String username = BrightTree__c.getInstance('username') == null ? '' : BrightTree__c.getInstance('username').Value__c;
        String password = BrightTree__c.getInstance('password') == null ? '' : BrightTree__c.getInstance('password').Value__c;
        if(username == '' || password == '') return null;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        system.debug (authorizationHeader);
        Map<String, String> optionsMap = new Map<String, String>{'endpoint' => endpointWithService,'verbMethod' => verbMethod, 'timeout' => '20000', 'authorizationHeader' => authorizationHeader, 'cache-control' => 'no-cache', 'Content-Type' => 'application/json'};
        return optionsMap;

    }

    public static Map<String, String> createOptionsMap(String serviceCustomSettingName, String verbMethod, String params) {
        String serviceURL = BrightTree__c.getInstance(serviceCustomSettingName) == null ? '' : BrightTree__c.getInstance(serviceCustomSettingName).Value__c;
        if(apiBaseUrl == '' || serviceURL == '') return null;
    
        String endpointWithServiceAndParams = apiBaseUrl + serviceURL + params;
        String username = BrightTree__c.getInstance('username') == null ? '' : BrightTree__c.getInstance('username').Value__c;
        String password = BrightTree__c.getInstance('password') == null ? '' : BrightTree__c.getInstance('password').Value__c;
        if(username == '' || password == '') return null;
        Blob headerValue = Blob.valueOf(username + ':' + password);
        String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
        system.debug (authorizationHeader);
        Map<String, String> optionsMap = new Map<String, String>{'endpoint' => endpointWithServiceAndParams,'verbMethod' => verbMethod, 'timeout' => '20000', 'authorizationHeader' => authorizationHeader, 'cache-control' => 'no-cache', 'Content-Type' => 'application/json'};
        return optionsMap;

    }


    public static HttpRequest createHttpRequest(Map<String, String> optionsMap, String theJson) {
        //Creating the Http Request
        HttpRequest req = new HttpRequest();
        req.setEndpoint(optionsMap.get('endpoint'));
        req.setMethod(optionsMap.get('verbMethod'));
        req.setTimeout(Integer.valueOf(optionsMap.get('timeout')));
        req.setHeader('Authorization', optionsMap.get('authorizationHeader'));
        req.setHeader('cache-control', optionsMap.get('cache-control'));
        req.setHeader('Content-Type', optionsMap.get('Content-Type'));
        req.setBody(thejson);
        system.debug(thejson);
        return req;
    }

    public static HttpResponse sendHttpRequest(HttpRequest req) {
        Http h = new Http();
        try {
            HttpResponse res = h.send(req);
            System.debug('Response Body: ' + res.getBody()+ '\nResponse Status: ' +res.getStatus()+ '\nResponse Status Code: ' +res.getStatusCode());
            return res;
        }
        catch(CalloutException e) {
            System.debug('Exception Message: ' + e.getMessage() + '\nException Type: ' + e.getTypeName());
        }
        return null;
    }



 public class thePatientWrapper {
        public Integer PatientID {get; set;}
        public Integer fk_BranchID {get; set;}
        public String fk_BranchName {get; set;}
        public Integer fk_MarketingRepID {get; set;}
        public String fk_MarketingRepName {get; set;}
        public Integer fk_FacilityID {get; set;}
        public String fk_FacilityName {get; set;}
        public Integer fk_TaxZoneID {get; set;}
        public String fk_TaxZoneName {get; set;}
        public Integer fk_CustomerTypeID {get; set;}
        public String fk_CustomerTypeName {get; set;}
        public Integer fk_BillingCountyID {get; set;}
        public String fk_BillingCountyName {get; set;}
        public Integer fk_BillingCountryID {get; set;}
        public String fk_BillingCountryName {get; set;}
        public Integer fk_MaritalStatusID {get; set;}
        public String fk_MaritalStatusName {get; set;}
        public Integer fk_DeliveryCountyID {get; set;}
        public String fk_DeliveryCountyName {get; set;}
        public Integer fk_DeliveryCountryID {get; set;}
        public String fk_DeliveryCountryName {get; set;}
        public Integer fk_DeliveryStateID {get; set;}
        public String fk_DeliveryStateName {get; set;}
        public Integer fk_ECCountryID {get; set;}
        public String fk_ECCountryName {get; set;}
        public Integer fk_ECStateID {get; set;}
        public String fk_ECStateName {get; set;}
        public Integer fk_ECRelationshipID {get; set;}
        public String fk_ECRelationshipName {get; set;}
        public Integer fk_RPRelationshipID {get; set;}
        public String fk_RPRelationshipName {get; set;}
        public Integer fk_RPCountryID {get; set;}
        public String fk_RPCountryName {get; set;}
        public Integer fk_RPStateID {get; set;}
        public String fk_RPStateName {get; set;}
        public Integer fk_PenTipsOrSyringesID {get; set;}
        public String fk_PenTipsOrSyringesName {get; set;}
        public Integer fk_InjectionsPerDayID {get; set;}
        public String fk_InjectionsPerDayName {get; set;}
        public Integer fk_IPSSupplierID {get; set;}
        public String fk_IPSSupplierName {get; set;}
        public Integer fk_CGMSupplierID {get; set;}
        public String fk_CGMSupplierName {get; set;}
        public Integer fk_TestStripModelID {get; set;}
        public String fk_TestStripModelName {get; set;}
        public Integer fk_TimesTestingID {get; set;}
        public String fk_TimesTestingName {get; set;}
        public Integer fk_CurrentPumpModelID {get; set;}
        public String fk_CurrentPumpModelName {get; set;}
        public Integer fk_CGMModelID {get; set;}
        public String fk_CGMModelName {get; set;}
        public Integer fk_PreferredMethodOfContactID {get; set;}
        public String fk_PreferredMethodOfContactName {get; set;}
        public Integer fk_PreferredMethodOfReorderID {get; set;}
        public String fk_PreferredMethodOfReorderName {get; set;}
        public Integer fk_NcpdpPtResidenceCodeID {get; set;}
        public String fk_NcpdpPtResidenceCodeName {get; set;}
        public Integer fk_GenderID {get; set;}
        public String fk_GenderName {get; set;}
        public Integer fk_EmploymentID {get; set;}
        public String fk_EmploymentName {get; set;}
        public Integer fk_FunctionalAbilityID {get; set;}
        public String fk_FunctionalAbilityName {get; set;}
        public Integer fk_POSID {get; set;}
        public String fk_POSName {get; set;}
        public Integer fk_PractitionerID {get; set;}
        public String fk_PractitionerName {get; set;}
        public Integer fk_PTSecurityGroupID {get; set;}
        public String fk_PTSecurityGroupName {get; set;}
        public String MiddleName {get; set;}
        public String FaxNumber {get; set;}
        public String EmailAddress {get; set;}
        public String MobilePhone {get; set;}
        public String Suffix {get; set;}
        public String DOD {get; set;}
        public String DateOfAdmission {get; set;}
        public String DateOfDischarge {get; set;}
        public String DateOfOnset {get; set;}
        public String StateOfAutoAccident {get; set;}
        public String SSN {get; set;}
        public Boolean HoldAcct {get; set;}
        public String Height {get; set;}
        public String Weight {get; set;}
        public String Employment {get; set;}
        public Integer DiscountPct {get; set;}
        public String AccountNumber {get; set;}
        public Integer AlternateTypeID {get; set;}
        public String DelivAddress1 {get; set;}
        public String DelivAddress2 {get; set;}
        public String DeliveryCity {get; set;}
        public String DeliveryZip {get; set;}
        public String DeliveryPhone {get; set;}
        public Integer DocumentID {get; set;}
        public String ECLastName {get; set;}
        public String ECFirstName {get; set;}
        public String ECMiddleName {get; set;}
        public String ECAddress1 {get; set;}
        public String ECAddress2 {get; set;}
        public String ECCity {get; set;}
        public String ECPostalCode {get; set;}
        public String ECMobile {get; set;}
        public String ECPhoneNumber {get; set;}
        public String ECFax {get; set;}
        public String ECEmail {get; set;}
        public String ReferralType {get; set;}
        public Integer ReferralKey {get; set;}
        public String ReferringProviderType {get; set;}
        public String RenderingProviderType {get; set;}
        public String RPLastName {get; set;}
        public String RPFirstName {get; set;}
        public String RPMiddleName {get; set;}
        public String RPAddress1 {get; set;}
        public String RPAddress2 {get; set;}
        public String RPCity {get; set;}
        public String RPPostalCode {get; set;}
        public String RPMobile {get; set;}
        public String RPPhoneNumber {get; set;}
        public String RPFax {get; set;}
        public String RPEmail {get; set;}
        public Boolean HIPPASignatureOnFile {get; set;}
        public Boolean PatientConditionDiabetes {get; set;}
        public Boolean OptOut_Email {get; set;}
        public Boolean OptOut_EmailText {get; set;}
        public Boolean OptOut_IVRCall {get; set;}
        public Boolean OptOut_Text {get; set;}
        public Boolean OptOut_Web {get; set;}
        public Integer CreatedBy {get; set;}
        public String CreatedDate {get; set;}
        public Integer ModifiedBy {get; set;}
        public String ModifiedDate {get; set;}
        public Boolean SendToSF {get; set;}
        public String PatientHubID {get; set;}
        public String FirstName {get; set;}
        public String LastName {get; set;}
        public Date DOB {get; set;}
        public String BillingAddress1 {get; set;}
        public String BillingAddress2 {get; set;}
        public String BillingCity {get; set;}
        public String BillingZip {get; set;}
        public String BillingPhone {get; set;}
        public Integer fk_BillingStateID {get; set;}
        public String fk_BillingStateName {get; set;}
        public Integer fk_AccountGroupID {get; set;}
        public String fk_AccountGroupName {get; set;}
        public thePatientWrapper(Account theAccount) {
            patientWrapper pWrapHub = patientWrapper.parse(SolaraHubIntegration.callHubService('endpointGetPatient','GET','',theAccount.External_Id__c));
            this.PatientHubID = theAccount.External_Id__c;
            this.FirstName = theAccount.FirstName;
            this.LastName = theAccount.LastName;
            this.DOB = theAccount.PersonBirthDate;
            this.BillingAddress1 = String.isNotBlank(theAccount.BillingStreet) && theAccount.BillingStreet.contains('\n') ? theAccount.BillingStreet.split('\n')[0] : theAccount.BillingStreet;
            this.BillingAddress2 = String.isNotBlank(theAccount.BillingStreet) && theAccount.BillingStreet.contains('\n') ? theAccount.BillingStreet.split('\n')[1] : '';
            this.BillingCity = theAccount.BillingCity;
            this.fk_BillingStateName =   theAccount.BillingState;
            this.BillingZip = theAccount.BillingPostalCode;
            this.fk_BillingCountryName =  theAccount.BillingCountry;
            this.DelivAddress1 = String.isNotBlank(theAccount.ShippingStreet) && theAccount.ShippingStreet.contains('\n') ? theAccount.ShippingStreet.split('\n')[0] : theAccount.ShippingStreet;
            this.DelivAddress2 = String.isNotBlank(theAccount.ShippingStreet) && theAccount.ShippingStreet.contains('\n') ? theAccount.ShippingStreet.split('\n')[1] : '';
            this.DeliveryCity = theAccount.ShippingCity;
            this.fk_DeliveryStateName = theAccount.ShippingState;
            this.DeliveryZip = theAccount.ShippingPostalCode;
            this.fk_DeliveryCountyName = theAccount.ShippingCountry;
            this.BillingPhone = theAccount.PersonHomePhone;
            this.fk_PreferredMethodOfContactName = theAccount.Preferred_Method_of_Contact__c;
            this.EmailAddress = theAccount.PersonEmail;
            this.fk_GenderName = theAccount.Gender__pc;
            this.AccountNumber = theAccount.AccountNumber;
            this.fk_TestStripModelName = theAccount.Brand_of_Test_Strips__c;
            this.fk_CurrentPumpModelName = theAccount.Current_Pump__c;
            this.fk_InjectionsPerDayName = String.valueOf(theAccount.Times_Injecting_per_Day__c);
            this.fk_TimesTestingName = String.valueOf(theAccount.Times_Testing_per_Day__c);
            if (pWrapHub.ECFirstName != null) this.ECFirstName = pWrapHub.ECFirstName;
            if (pWrapHub.ECMiddleName != null) this.ECMiddleName = pWrapHub.ECMiddleName;
            if (pWrapHub.ECAddress1 != null) this.ECAddress1 = pWrapHub.ECAddress1;
            if (pWrapHub.ECAddress2 != null) this.ECAddress2 = pWrapHub.ECAddress2;
            if (pWrapHub.ECCity != null) this.ECCity = pWrapHub.ECCity;
            if (pWrapHub.ECPostalCode != null) this.ECPostalCode = pWrapHub.ECPostalCode;
            if (pWrapHub.ECMobile != null) this.ECMobile = pWrapHub.ECMobile;
            if (pWrapHub.ECPhoneNumber != null) this.ECPhoneNumber = pWrapHub.ECPhoneNumber;
            if (pWrapHub.ECFax != null) this.ECFax = pWrapHub.ECFax;
            if (pWrapHub.ECEmail != null) this.ECEmail = pWrapHub.ECEmail;
            if (pWrapHub.RPLastName != null) this.RPLastName = pWrapHub.RPLastName;
            if (pWrapHub.RPFirstName != null) this.RPFirstName = pWrapHub.RPFirstName;
            if (pWrapHub.RPMiddleName != null) this.RPMiddleName = pWrapHub.RPMiddleName;
            if (pWrapHub.RPAddress1 != null) this.RPAddress1 = pWrapHub.RPAddress1;
            if (pWrapHub.RPAddress2 != null) this.RPAddress2 = pWrapHub.RPAddress2;
            if (pWrapHub.RPCity != null) this.RPCity = pWrapHub.RPCity;
            if (pWrapHub.RPPostalCode != null) this.RPPostalCode = pWrapHub.RPPostalCode;
            if (pWrapHub.RPMobile != null) this.RPMobile = pWrapHub.RPMobile;
            if (pWrapHub.RPPhoneNumber != null) this.RPPhoneNumber = pWrapHub.RPPhoneNumber;
            if (pWrapHub.RPFax != null) this.RPFax = pWrapHub.RPFax;
            if (pWrapHub.RPEmail != null) this.RPEmail = pWrapHub.RPEmail;

        }
    }


        public class SalesOrderWrapper {
            public SalesOrderInfo salesOrder {get;set;}
            public List<patientProviders> patientProviders {get;set;}
            public List<patientPayors> patientPayors {get;set;}
            public List<addresses> addresses {get;set;}

            public SalesOrderWrapper(Opportunity theOpportunity, List<patientProviders> patientProviders, List<patientPayors> patientPayors, List<addresses> addresses) {
                this.salesOrder = new SalesOrderInfo(theOpportunity);
                this.patientProviders = patientProviders;
                this.patientPayors = patientPayors;
                this.addresses = addresses;
            }            
        }


    


        public class addresses {
            public string Id {get;set;}
            public string Address1 {get;set;}
            public string Address2 {get;set;}
            public string City {get;set;}
            public Integer fk_StateID;
            public string fk_StateName {get;set;}
            public string PostalCode {get;set;}
            //public string Type {get;set;}
            public Boolean Selected {get;set;}
            public addresses(SObject theData, String type) {
                if(theData.getSObjectType() == Schema.Provider__c.SObjectType) {
                    Provider__c theProvider = (Provider__c)theData;
                    this.Id = theProvider.Id == null ? '' : theProvider.Id;
                    this.Address1 = theProvider.Address__c == null ? '' : theProvider.Address__c;
                    this.Address2 = theProvider.Address2__c == null ? '' : theProvider.Address2__c;
                    this.City = theProvider.City__c == null ? '' : theProvider.City__c;
                    this.fk_StateName = theProvider.State__c == null ? '' : theProvider.State__c;
                    this.PostalCode = theProvider.Zip__c == null ? '' : theProvider.Zip__c;
                    //this.fk_StateID = null;
                    //this.Type = type;
                    this.Selected = true;
                } else if(theData.getSObjectType() == Schema.Address_Data__c.SObjectType)  {
                    Address_Data__c theAddressData = (Address_Data__c)theData;
                    this.Id = theAddressData.Id == null ? '' : theAddressData.Id;
                    this.Address1 = theAddressData.Street__c.contains('\n') ? theAddressData.Street__c.split('\n')[0] : theAddressData.Street__c;
                    this.Address2 = theAddressData.Street__c.contains('\n') ? theAddressData.Street__c.split('\n')[1] : '';
                    this.City = theAddressData.City__c == null ? '' : theAddressData.City__c;
                    this.fk_StateName = theAddressData.State_Province__c == null ? '' : theAddressData.State_Province__c;
                    this.PostalCode = theAddressData.Zip_Postal_Code__c == null ? '' : theAddressData.Zip_Postal_Code__c;
                    //this.fk_StateID = null;
                    //this.Type = type;
                    this.Selected = true;
                }
            }
        }
    
        public class Patient_DiagnosisCodesList {
            public Integer ID {get; set;}
            public Integer fk_PatientID {get; set;}
            public Integer fk_DiagnosisID {get; set;}
            public Integer fk_ICDCodeTypeID {get; set;}
            public String fk_ICDCodeTypeName {get; set;}
            public String ICDCode {get; set;}
            public String ShortDescription {get; set;}
            public Integer PtDiagKey {get; set;}
        }

        public class patientPayors {
            public string Patient_PayorID {get;set;} //thePayor.Id //What is this field suppose to be?
            public string PatientPayorHubID {get;set;} //thePayor.External_Id__c
            public string PatientHubID {get;set;} //theMember.External_Id__c
            public String PayorHubID {get; set;} //thePayor.External_Id__c
            public Integer fk_PayorID {get;set;} 
            public String fk_PayorName {get;set;} 
            public String InsuranceCompanyName {get;set;} 
            public Integer fk_PayorLevelID {get;set;} 
            public String fk_PayorLevelName {get;set;} 
            public Integer fk_PolicyHolderGenderID {get;set;} 
            public Integer BrightreePatientPayorKey {get;set;} 
            public String PolicyNo {get;set;} 
            public String PolicyHolderName {get;set;} 
            public String PolicyHolderDOB {get;set;} 
            public String Bin {get;set;} 
            public String GroupNo {get;set;} 
            public String Pcn {get;set;} 
            public String PrimaryBrightreeInsurance {get;set;} 
            public String PrimaryBrightreeInsurancePhone {get;set;} 
            public String NCDPDPolicyNo {get;set;} 
            public String NCPDPGroupNo {get;set;} 
            public String RelationshipToPolicyHolder {get;set;} 
            public String InsuredFirstName {get;set;} 
            public String InsuredLastName {get;set;} 
            public String InsuredPhone {get;set;} 
            public String PolicyStartDate {get;set;} 
            public String PolicyEndDate {get;set;} 
            public Boolean Active {get;set;} 
            public Integer CreatedBy {get;set;} 
            public String CreatedDate {get;set;} 
            public Integer ModifiedBy {get;set;} 
            public String ModifiedDate {get;set;} 
            public Integer PayPercent {get;set;} 
            public Integer Deductible {get;set;} 
            public String GroupName {get;set;} 
            public String PayorContact {get;set;} 
            public Boolean Selected {get;set;} 
            public patientPayors(Insurance_Patient_Junction__c thePayorJunction) {
                // TODO: PatientPayorHubId? 
                this.Patient_PayorID = thePayorJunction.Insurance__c;
                this.PayorHubID = thePayorJunction.Insurance__r.External_Id__c;
                this.PatientHubID = thePayorJunction.Account__r.External_Id__c;
                this.InsuranceCompanyName = thePayorJunction.Insurance__r.Insurance_Co_Name__c;
                if (thePayorJunction.Policy_Level__c == 'Primary') {
                    this.fk_PayorLevelID = 1;
                } else if (thePayorJunction.Policy_Level__c == 'Secondary') {
                    this.fk_PayorLevelID = 2;
                } else if (thePayorJunction.Policy_Level__c == 'Tertiary') {
                    this.fk_PayorLevelID = 3;
                }
  
            }
        }

        public class SalesOrderItems {
            public Integer Quantity {get;set;}
            public string ItemHubID {get;set;}
            public string ItemId {get;set;}
            public String ItemName {get; set;}
            public SalesOrderItems(OpportunityLineItem lineItem) {
                this.Quantity = Integer.valueOf(lineItem.Quantity);
                this.ItemHubID = lineItem.Product2.External_Id__c;
                this.ItemId = lineItem.Product2.Item_ID__c;
                this.itemName = lineItem.Product2.Name;
            }
        }

        public class patientProviders {
            public string patientProviderHubID {get;set;}
            public string patientHubID {get;set;}
            public string providerHubID {get;set;}
            public Boolean isPrescribing {get;set;}
            public Boolean ispcp {get;set;}
            public Boolean selected {get;set;}
            public patientProviders(Account theMember, Provider__c theProvider, String type) {
                //this.patientProviderHubID = ''; //What is this field suppose to be??
                this.patientHubID = theMember.External_Id__c;
                this.providerHubID = theProvider.External_Id__c;
                this.isPrescribing = type.contains('Prescribing') ? true : false;
                this.ispcp = type.contains('PCP') ? true : false;
                this.selected = true;
            }
        }

    public class SalesOrderInfo {
        public String SalesOrderHubID {get; set;}
        public String PatientHubID {get; set;}
        public String PatientLastName {get; set;}
        public String PatientFirstName {get; set;}
        public String SF_OpportunityID {get; set;}
        public String BrightreeID {get; set;}
        public Integer fk_BranchID {get; set;}
        public String fk_BranchName {get; set;}
        public Integer fk_TaxZone {get; set;}
        public String fk_TaxZoneName {get; set;}
        public Integer fk_PractitionerID {get; set;}
        public String fk_PractitionerName {get; set;}
        public Integer fk_WIPStateID {get; set;}
        public String fk_WIPStateName {get; set;}
        public Integer fk_WIPAssignedToID {get; set;}
        public String fk_WIPAssignedToName {get; set;}
        public Integer fk_MarketingReferralID {get; set;}
        public String fk_MarketingReferralName {get; set;}
        public Integer fk_POSID {get; set;}
        public String fk_POSName {get; set;}
        public Integer fk_OrderingDoctorID {get; set;}
        public String fk_OrderingDoctorName {get; set;}
        public Integer fk_DeliveryAddrStateID {get; set;}
        public String fk_DeliveryAddrStateName {get; set;}
        public Integer fk_SourceOfOrderID {get; set;}
        public String SOStatus {get; set;}
        public String SOScheduleDeliveryDate {get; set;}
        public String SOActualDeliveryDate {get; set;}
        public Integer ReferralKey {get; set;}
        public String ReferralType {get; set;}
        public String SOType {get; set;}
        public String DeliveryAddrStreet {get; set;}
        public String DeliveryAddrCity {get; set;}
        public String DeliveryAddrZip {get; set;}
        public String DeliveryNote {get; set;}
        public String ShippingMethodPref {get; set;}
        public String PONumber {get; set;}
        public Boolean InsVerified {get; set;}
        public Boolean CovVerified {get; set;}
        public String SOClassification {get; set;}
        public String CommissionableEvent1 {get; set;}
        public String CommissionableEvent2 {get; set;}
        public String CommissionableEvent3 {get; set;}
        public String CommissionableEvent4 {get; set;}
        public String CommissionableEvent5 {get; set;}
        public String CommissionableEvent6 {get; set;}
        public String OrderOwner {get; set;}
        public String SignatureRqd {get; set;}
        public String Note {get; set;}
        public String CustNeedDate {get; set;}
        public String SaturdayDelivery {get; set;}
        public String IsDuplicated_ExcludeFromMfgRPT {get; set;}
        public String CreatedDate {get; set;}
        public String CreatedBy {get; set;}
        public Boolean Active {get; set;}
        public String QAError1 {get; set;}
        public Integer ItemExcluded {get; set;}
        public String QAError2 {get; set;}
        public String ErrorComments {get; set;}
        public String PumpSale {get; set;}
        public String CustomerTypeFromManufacturer {get; set;}
        public String CurrentInsulinDeliveryMethod {get; set;}
        public String ReferredToRetail {get; set;}
        public String NewToCGMTherapy {get; set;}
        public String ADMFollowup {get; set;}
        public String ADMRequest {get; set;}
        public String ADMAuthFollowUp {get; set;}
        public String WIPDateNeeded {get; set;}
        public String DateOfAdmission {get; set;}
        public String DateOfDischarge {get; set;}
        public String SOStopDt {get; set;}
        public Integer LocKey {get; set;}
        public String Reference {get; set;}
        public String DeliveryPhoneNumber {get; set;}
        public String DeliveryMobilePhoneNumber {get; set;} 
        public String SolaraSOError_RespParty {get; set;}
        public List<SalesOrderItems> SalesOrderItems {get; set;}
        public List<Patient_DiagnosisCodesList> Patient_DiagnosisCodesList {get; set;}
        public SalesOrderInfo(Opportunity theCurrentOpportunity) {
            Account theAccount = mapIdToAccount.get(theCurrentOpportunity.AccountId);
            this.SalesOrderHubID = theCurrentOpportunity.External_Id__c;
            this.PatientHubID = theAccount.External_Id__c;
            this.PatientLastName = theAccount.LastName;
            this.PatientFirstName = theAccount.FirstName;
            this.SF_OpportunityID = theCurrentOpportunity.Id;
            this.BrightreeID = theCurrentOpportunity.BrightTree_Order_Id__c;
            this.DeliveryAddrStreet = theAccount.ShippingStreet;
            this.DeliveryAddrCity = theAccount.ShippingCity;
            this.DeliveryAddrZip = theAccount.ShippingPostalCode;
            this.CreatedDate = String.valueOf(theCurrentOpportunity.CreatedDate);
            this.CreatedBy = theCurrentOpportunity.CreatedById;
            this.Active = theAccount.Active__c == 'Yes' ? true : false;
            this.SalesOrderItems = new List<SalesOrderItems>();
            this.Patient_DiagnosisCodesList = new List<Patient_DiagnosisCodesList>();
            for(OpportunityLineItem lineItem : mapOppIdToLineItemList.get(theCurrentOpportunity.Id)) {
                SalesOrderItems salesOrderItem = new SalesOrderItems(lineItem);
                this.SalesOrderItems.add(salesOrderItem);
            }
        }
    }

    public class dexcomLeadWrapper {

        public String DistributorActivityNotes {get; set;}
        public String CloseReason {get; set;}
        public String Document1 {get; set;}
        public String Document2 {get; set;}
        public String Document3 {get; set;}
        public String Document4 {get; set;}
        public String Document5 {get; set;}
        public String Document6 {get; set;}
        public Integer EstimatedSensorCost {get; set;}
        public Integer EstimatedStartUpCost {get; set;}
        public Date FollowUpDate {get; set;}
        public Date LastActivityDate {get; set;}
        public String Name {get; set;}
        public String OpportunityOwnerC {get; set;}
        public String OpportunityType {get; set;}
        public Date PatientDOB {get; set;}
        public String Payer1C {get; set;}
        public String Payer2C {get; set;}
        public String Payer3C {get; set;}
        public String HomePhone {get; set;}
        public String PhysicianC {get; set;}
        public String ReqDoc1 {get; set;}
        public String ReqDoc2 {get; set;}
        public String ReqDoc3 {get; set;}
        public String ReqDoc4 {get; set;}
        public String ReqDoc5 {get; set;}
        public String ReqDoc6 {get; set;}
        public String Stage {get; set;}
        public String Status {get; set;}
        public String DistCreatedDate {get; set;}
        public String DistOppID {get; set;}
        public String MobilePhone {get; set;}
        public String DistOppShipToAddress {get; set;}
        public String Email {get; set;}
        public String Gender {get; set;}
        public String DistOppBillToAddress {get; set;}
        public String SFOppID {get; set;}
        public String DistAccountNumber {get; set;}

        public dexcomLeadWrapper(Opportunity o) {
            this.DistributorActivityNotes = o.Opportunity_Notes__c;
            this.CloseReason = o.Close_Reason__c;
            this.Document1 = o.Doc_1_Status__c;
            this.Document2 = o.Doc_2_Status__c;
            this.Document3 = o.Doc_3_Status__c;
            this.Document4 = o.Doc_4_Status__c;
            this.Document5 = o.Doc_5_Status__c;
            this.Document6 = o.Doc_6_Status__c;
            this.EstimatedSensorCost = o.Estimated_Sensor_Cost__c == null ? 0 : Integer.valueOf(o.Estimated_Sensor_Cost__c);
            this.EstimatedStartUpCost = o.Estimated_Start_Up_Cost__c == null ? 0 : Integer.valueOf(o.Estimated_Start_Up_Cost__c);
            this.FollowUpDate = o.Next_Follow_Up_Date__c;
            this.LastActivityDate = o.Last_Note_Created_Date__c;
            this.Name = o.Name;
            this.OpportunityOwnerC = o.Opportunity_Owner_Name__c;
            this.OpportunityType = o.Dexcom_Opportunity_Type__c;
            this.PatientDOB = o.Patient_DOB__c == null ? Date.newInstance(1800, 01, 01) : o.Patient_DOB__c;
            this.Payer1C = o.Dexcom_Primary__c;
            this.Payer2C = o.Dexcom_Secondary__c;
            this.Payer3C = o.Dexcom_Secondary__c;
            this.HomePhone = o.Dexcom_Patient_Home_Phone__c;
            this.PhysicianC = o.Dexcom_Doctor__c;
            this.ReqDoc1 = o.Doc_1_Type__c;
            this.ReqDoc2 = o.Doc_2_Type__c;
            this.ReqDoc3 = o.Doc_3_Type__c;
            this.ReqDoc4 = o.Doc_4_Type__c;
            this.ReqDoc5 = o.Doc_5_Type__c;
            this.ReqDoc6 = o.Doc_6_Type__c;
            this.Stage = o.StageName;
            this.Status = o.Status__c;
            //this.DistCreatedDate = o.Dexcom_Dis
            this.DistOppID = o.Dexcom_Opp_Id__c;
            this.MobilePhone = o.Dexcom_Patient_Mobile_Phone__c;
            this.DistOppShipToAddress = o.Dexcom_Patient_Ship_To_Address__c;
            this.Email = o.Dexcom_Patient_Email__c;
            this.Gender = o.Dexcom_Gender__c;
            this.DistOppBillToAddress = o.Dexcom_Patient_Ship_To_Address__c;
            this.SFOppID = o.Id;
            this.DistAccountNumber = o.Dexcom_Account_Number__c;
        }
    }    

}