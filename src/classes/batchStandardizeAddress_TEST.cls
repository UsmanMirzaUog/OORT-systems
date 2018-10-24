@isTest
public with sharing class batchStandardizeAddress_TEST {
    public class MockHttpResponseGenerator implements HttpCalloutMock {
		public HTTPResponse respond(HTTPRequest req) {
	        String bodyString =
	                '[' +
	                        '{' +
	                            '"AddressLine1": "test",' +
	                            '"AddressLine2": "test",' +
	                            '"AddressLine3": "test",' +
	                            '"City": "test",' +
	                            '"State": "test",' +
	                            '"ZipOrPostalCode": "test"' +
	                        '}' +
	                ']';

	        HttpResponse res = new HttpResponse();
	        res.setHeader('Content-Type', 'application/json');
	        res.setBody(bodyString);
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




	testmethod public static void testProviderScrubOneRecord() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Provider__c p = new Provider__c();
		p.Name = 'Test Provider';
		p.Address__c = '123 Test Address';
		p.Address2__c = 'Unit 22';
		p.Address3__c = 'Test Address3';
		p.City__c = 'Test City';
		p.State__c = 'CA';
		p.Zip__c = '90210';

        Test.startTest();
       	insert p;
       	Test.stopTest();



	}
}