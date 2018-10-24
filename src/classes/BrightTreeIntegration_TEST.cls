@isTest
public class BrightTreeIntegration_TEST {

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Test" : "Blah"}');
            res.setStatus('Success');
            res.setStatusCode(200);
            return res;
        }
    }
    @testSetup public static void SetUpData() {

        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.createAllCustomSettings();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_OpptyLineItems();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    }

    //@isTest static void BrightTreeIntegration_DeliveredToAddress() {
    //    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    //    Id oppId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Id;
    //    Id addressId = [SELECT Id FROM Address_Data__c LIMIT 1].Id;
    //    Id providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;
    //    Id payorId = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id;

    //    Provider__c theProvider = new Provider__c(Name = 'Leonard Hofstadter', Phone__c = '9254152639', Email__c = 'leonard.hofstadter@revcult.com', Address__c = '101112 Trailhead Court', Address2__c = 'Apt 32', City__c = 'San Diego', State__c = 'CA', Zip__c = '92111');
    //    INSERT theProvider;

    //    List<Map<String, object>> infoList = new List<Map<String, object>>();
    //    Map<String, object> infoMap = new Map<String, object>();
    //    infoMap.put('oppId', oppId);
    //    infoMap.put('addressId', addressId);
    //    infoMap.put('deliveryAddressId', addressId);
    //    infoMap.put('orderingProviderId', providerId);
    //    infoMap.put('primaryProviderId', theProvider.Id);
    //    infoList.add(infoMap);
    //    String theJSONString = JSON.serialize(infoList);

    //    Test.startTest();
    //    BrightTreeIntegration.testBrightTreeIntegration(theJSONString);
    //    Test.stopTest();

    //    //system.assert missing because integration is not finished yet
    //}
    //@isTest static void BrightTreeIntegration_DifferentPrescribingAndPCPs() {
    //    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    //    Id oppId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Id;
    //    Id addressId = [SELECT Id FROM Address_Data__c LIMIT 1].Id;
    //    Id providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;
    //    Id payorId = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id;
    //    List<Map<String, object>> infoList = new List<Map<String, object>>();
    //    Map<String, object> infoMap = new Map<String, object>();
    //    infoMap.put('oppId', oppId);
    //    infoMap.put('addressId', addressId);
    //    infoMap.put('deliveryAddressId', addressId);
    //    infoMap.put('orderingProviderId', providerId);
    //    infoMap.put('primaryProviderId', providerId);
    //    infoList.add(infoMap);
    //    String theJSONString = JSON.serialize(infoList);

    //    Test.startTest();
    //    BrightTreeIntegration.testBrightTreeIntegration(theJSONString);
    //    Test.stopTest();

    //    //system.assert missing because integration is not finished yet
    //}
    //@isTest static void BrightTreeIntegration_DeliveredToProvider() {
    //    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    //    Id oppId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Id;
    //    Id addressId = [SELECT Id FROM Address_Data__c LIMIT 1].Id;
    //    Id providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;
    //    Id payorId = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id;
    //    List<Map<String, object>> infoList = new List<Map<String, object>>();
    //    Map<String, object> infoMap = new Map<String, object>();
    //    infoMap.put('oppId', oppId);
    //    infoMap.put('addressId', addressId);
    //    infoMap.put('deliveryAddressId', providerId);
    //    infoMap.put('orderingProviderId', providerId);
    //    infoMap.put('primaryProviderId', providerId);
    //    infoList.add(infoMap);
    //    String theJSONString = JSON.serialize(infoList);

    //    Test.startTest();
    //    BrightTreeIntegration.testBrightTreeIntegration(theJSONString);
    //    Test.stopTest();

    //    //system.assert missing because integration is not finished yet
    //}

    //@isTest static void BrightTreeIntegration_IntgegrateWithDexComLeadsOnInsert() {
    //    //Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    //    Id oppId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Id;
    //    Id addressId = [SELECT Id FROM Address_Data__c LIMIT 1].Id;
    //    Id providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;
    //    Id payorId = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id;
    //    List<Map<String, object>> infoList = new List<Map<String, object>>();
    //    Map<String, object> infoMap = new Map<String, object>();
    //    infoMap.put('oppId', oppId);
    //    infoList.add(infoMap);
    //    String theJSONString = JSON.serialize(infoList);

    //    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());


    //    Opportunity o = new Opportunity();
    //    o.Name = 'Test Opportunity';
    //    o.CloseDate = system.Today();
    //    o.StageName = 'New';
    //    o.Manufacturer__c = 'Dexcom';
        
    //    Test.startTest();
    //    insert o;
    //    Test.stopTest();



    //    //system.assert missing because integration is not finished yet
    //}

    //@isTest static void BrightTreeIntegration_IntgegrateWithDexComLeads() {
    //    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    //    Id oppId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Id;
    //    Id addressId = [SELECT Id FROM Address_Data__c LIMIT 1].Id;
    //    Id providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;
    //    Id payorId = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id;
    //    List<Map<String, object>> infoList = new List<Map<String, object>>();
    //    Map<String, object> infoMap = new Map<String, object>();
    //    infoMap.put('oppId', oppId);
    //    infoList.add(infoMap);
    //    String theJSONString = JSON.serialize(infoList);

    //    //Test.startTest();
    //    BrightTreeIntegration.integrateSolaraHubDexcomLead(theJSONString);
    //    //Test.stopTest();

    //    //system.assert missing because integration is not finished yet
    //}

    //@isTest static void BrightTreeIntegration_IntgegrateWithGenericLeads() {
    //    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    //    Id oppId = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'].Id;
    //    Id addressId = [SELECT Id FROM Address_Data__c LIMIT 1].Id;
    //    Id providerId = [SELECT Id FROM Provider__c LIMIT 1].Id;
    //    Id payorId = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id;
    //    List<Map<String, object>> infoList = new List<Map<String, object>>();
    //    Map<String, object> infoMap = new Map<String, object>();
    //    infoMap.put('oppId', oppId);
    //    infoList.add(infoMap);
    //    String theJSONString = JSON.serialize(infoList);

    //    BrightTreeIntegration.integrateSolaraHubDexcomLead(theJSONString);

    //}

}