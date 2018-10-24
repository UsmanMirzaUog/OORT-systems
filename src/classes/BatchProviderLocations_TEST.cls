/**
 * Created by krizia on 6/28/18.
 * BatchProviderLocations: 100%
 */
@isTest
public class BatchProviderLocations_TEST {


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



    @isTest static void testInsert() {
        TestDataFactory.createAllCustomSettings();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Provider__c p = new Provider__c(
                Name = 'Maximum Health',
                Address__c = '100 Main St',
                Address2__c = 'Suite A',
                City__c = 'Huntington Beach',
                State__c = 'CA',
                ZIP__c = '92648',
                Address_Verified__c = true
        );

        Test.startTest();
        INSERT p;
        System.debug(p);


        BatchProviderLocations handler = new BatchProviderLocations();
        Database.executeBatch(handler);
        Test.stopTest();


        //Address Verified is true
        System.assert([SELECT Count() FROM Location__c] == 1);
    }
}