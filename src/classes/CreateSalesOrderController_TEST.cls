@isTest
public class CreateSalesOrderController_TEST {

    @testSetup
    static void setUpTestData() {
        BrightTreeIntegration_TEST.SetUpData();
        TestDataFactory.createAllCustomSettings();
    }

    @isTest
    static void test_getData() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        Account thePatient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        Opportunity theOppty = [SELECT Id FROM Opportunity LIMIT 1];

        CreateSalesOrderController controller = new CreateSalesOrderController();
        controller.patient = thePatient;
        controller.oppty = theOppty;
        
        test.startTest();
        CreateSalesOrderController.Data dataHolder = CreateSalesOrderController.getSalesOrderData(thePatient.Id);
        test.stopTest();

        system.assert(dataHolder.addresses != null && !dataHolder.addresses.isEmpty());
        system.assert(dataHolder.providers != null && !dataHolder.providers.isEmpty());
    }

    @isTest
    static void test_CreateSalesOrder() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        Account thePatient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        Opportunity theOppty = [SELECT Id FROM Opportunity LIMIT 1];
        Insurance_Payor__c thePayor = [SELECT Id FROM Insurance_Payor__c LIMIT 1];
        Address_Data__c theAddress = [SELECT Id FROM Address_Data__c LIMIT 1];
        Provider__c theProvider = [SELECT Id FROM Provider__c LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new BrightTreeIntegration_TEST.MockHttpResponseGenerator());

        test.startTest();
        CreateSalesOrderController.goCreateSalesOrder(theOppty.Id, theAddress.Id, theAddress.Id, theProvider.Id, theProvider.Id);
        test.stopTest();

        theOppty = [SELECT Id, StageName FROM Opportunity WHERE Id =: theOppty.Id LIMIT 1];
        system.assert(theOppty.StageName == 'Closed Won');
    }
}