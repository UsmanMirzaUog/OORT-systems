/**
 * Created by danielpulache on 11/30/17.
 */
@isTest
public class trgAccountHandler_TEST {
    private static Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('Record created successfully!');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup static void setUpTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.create_Locations();
        TestDataFactory.create_LocationADMTasks();
        TestDataFactory.createAllCustomSettings();
    }
    @isTest static void keepTrackOfBillingAddress() {
        Account thePatient = [SELECT Id, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry FROM Account WHERE IsPersonAccount = true];
        String street = '1234 Test Lane';
        String city = 'San Diego';
        String state = 'CA';
        String zip = '92111';
        String country = 'USA';
        thePatient.BillingStreet = street;
        thePatient.BillingCity = city;
        thePatient.BillingState = state;
        thePatient.BillingPostalCode = zip;
        thePatient.BillingCountry = country;
        test.startTest();
        update thePatient;
        test.stopTest();

        system.assert([SELECT COUNT() FROM Address_Data__c WHERE Account__c =: thePatient.Id AND Type__c = 'Billing' AND Street__c =: street AND City__c =: city AND State_Province__c =: state AND Zip_Postal_Code__c =: zip] == 1);
    }
    @isTest static void keepTrackOfShippingAddress() {
        Account thePatient = [SELECT Id, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry FROM Account WHERE IsPersonAccount = true];
        String street = '456 Exam Road';
        String city = 'San Diego';
        String state = 'CA';
        String zip = '94652';
        String country = 'USA';
        thePatient.ShippingStreet = street;
        thePatient.ShippingCity = city;
        thePatient.ShippingState = state;
        thePatient.ShippingPostalCode = zip;
        thePatient.ShippingCountry = country;
        test.startTest();
        update thePatient;
        test.stopTest();

        system.assert([SELECT COUNT() FROM Address_Data__c WHERE Account__c =: thePatient.Id AND Type__c = 'Shipping' AND Street__c =: street AND City__c =: city AND State_Province__c =: state AND Zip_Postal_Code__c =: zip] == 1);
    }
    @isTest static void keepTrackOfBillingANDShippingAddress() {
        Account thePatient = [SELECT Id, ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode, ShippingCountry FROM Account WHERE IsPersonAccount = true];
        String street = '1234 Test Lane';
        String city = 'San Diego';
        String state = 'CA';
        String zip = '92111';
        String country = 'USA';
        thePatient.ShippingStreet = street;
        thePatient.ShippingCity = city;
        thePatient.ShippingState = state;
        thePatient.ShippingPostalCode = zip;
        thePatient.ShippingCountry = country;
        thePatient.BillingStreet = street;
        thePatient.BillingCity = city;
        thePatient.BillingState = state;
        thePatient.BillingPostalCode = zip;
        thePatient.BillingCountry = country;
        update thePatient;
        delete [SELECT Id FROM Address_Data__c];

        street = '456 Exam Road';
        city = 'San Diego';
        state = 'CA';
        zip = '94652';
        country = 'USA';
        thePatient.ShippingStreet = street;
        thePatient.ShippingCity = city;
        thePatient.ShippingState = state;
        thePatient.ShippingPostalCode = zip;
        thePatient.ShippingCountry = country;
        thePatient.BillingStreet = street;
        thePatient.BillingCity = city;
        thePatient.BillingState = state;
        thePatient.BillingPostalCode = zip;
        thePatient.BillingCountry = country;

        test.startTest();
        update thePatient;
        test.stopTest();

        system.assert([SELECT COUNT() FROM Address_Data__c WHERE Account__c =: thePatient.Id AND Type__c = 'Shipping' AND Street__c =: street AND City__c =: city AND State_Province__c =: state AND Zip_Postal_Code__c =: zip] == 1);
        system.assert([SELECT COUNT() FROM Address_Data__c WHERE Account__c =: thePatient.Id AND Type__c = 'Billing' AND Street__c =: street AND City__c =: city AND State_Province__c =: state AND Zip_Postal_Code__c =: zip] == 1);
    }
    @isTest static void trackingLocationsLastPatientContactDate() {
        Account thePatient = [SELECT Id, Last_Contact_Date__c FROM Account WHERE IsPersonAccount = true];
        thePatient.Last_Contact_Date__c = system.today().addDays(-1);

        test.startTest();
        update thePatient;
        test.stopTest();

        Task theTask = [SELECT Id, Location__r.Last_Patient_Contact_Date__c FROM Task WHERE Location__c != null AND RecordTypeId =: ADMRecordTypeId AND Patient__c =: thePatient.Id LIMIT 1];
        system.debug(theTask.Location__r.Last_Patient_Contact_Date__c);
        system.assert(theTask.Location__r.Last_Patient_Contact_Date__c == thePatient.Last_Contact_Date__c);
    }
}