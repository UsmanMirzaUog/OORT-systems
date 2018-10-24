/**
 * Created by krizia on 6/26/18.
 * trgProvider: 100%
 * trgProviderHandler: 92%
 * BatchStandardizeAddress: 96%
 */
@isTest
public class trgProviderHandler_TEST {


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



    @isTest static void testInsert(){
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
        Provider__c p2 = new Provider__c(
                Name = 'Dangerous Health',
                Address__c = '100 Main St',
                Address2__c = 'Suite A',
                City__c = 'Huntington Beach',
                State__c = 'CA',
                ZIP__c = '92648',
                Address_Verified__c = true
        );
        Provider__c p3 = new Provider__c(
                Name = 'Maintain Health',
                Address__c = '200 Main St',
                Address2__c = 'Suite B',
                City__c = 'Huntington Beach',
                State__c = 'CA',
                ZIP__c = '92648',
                Address_Verified__c = true
        );
        List<Provider__c> pList = new List<Provider__c>();
        pList.add(p);
        pList.add(p2);
        pList.add(p3);

        Test.startTest();
        INSERT pList;
        UPDATE pList;
        Test.stopTest();

        System.debug(pList);
        System.debug([SELECT Id, Location_Key__c FROM Location__c]);
        //Address Verified is true
        System.assert([SELECT Count() FROM Location__c] == 2);
    } //@isTest static void testInsert()

}