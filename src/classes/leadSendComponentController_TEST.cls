@isTest
private class leadSendComponentController_TEST
{
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

    @testSetup static void setUpData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        TestDataFactory.createAllCustomSettings();
    }

	@isTest
	static void getLeadName()
	{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Lead l = new Lead();
		l.FirstName = 'TestFirst';
		l.LastName = 'TestLast';
		l.Date_of_Birth__c = system.today();
		insert l;

		List<Lead_Products__c> lps = new List<Lead_Products__c>();

		Lead_Products__c lp = new Lead_Products__c();
		lps.add(lp);

		insert lps;

		String nameAssert = leadSendComponentController.getLeadName(l.Id);
		system.assertEquals(nameAssert, 'TestFirst TestLast');

		leadSendComponentController.createLeadJson(l, lps);

		leadSendComponentController.sendLeadToHub(l.Id);

	}

	@isTest
	static void createLeadJsonTest()
	{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Lead l = new Lead();
		l.FirstName = 'TestFirst';
		l.LastName = 'TestLast';
		l.Date_of_Birth__c = system.today();
		insert l;

		List<Lead_Products__c> lps = new List<Lead_Products__c>();

		Lead_Products__c lp = new Lead_Products__c();
		lps.add(lp);

		insert lps;

		String jsonString = leadSendComponentController.createLeadJson(l, lps);
		system.assert(jsonString.length() > 0);

		leadSendComponentController.sendLeadToHub(l.Id);

	}

	@isTest
	static void sendLeadToHubTest()
	{
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
		Lead l = new Lead();
		l.FirstName = 'TestFirst';
		l.LastName = 'TestLast';
		l.Date_of_Birth__c = system.today();
		insert l;

		List<Lead_Products__c> lps = new List<Lead_Products__c>();

		Lead_Products__c lp = new Lead_Products__c();
		lps.add(lp);

		insert lps;

		String sendLeadtoHubString = leadSendComponentController.sendLeadToHub(l.Id);
		system.assertEquals(sendLeadtoHubString, 'Success');

	}
}