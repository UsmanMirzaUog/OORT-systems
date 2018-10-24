@isTest
public with sharing class Typeahead_TEST {
    
    @isTest static void testQuery() {
        list<Account> aa = new list<Account>{
                new Account(Name='Test Account'),
                new Account(Name='Another Account', BillingCity='Test City'),
                new Account(Name='Third Account')
        };
        insert aa;

        // crazy, but you have to fake this
        list<Id> fixedSearchResults= new list<Id>{aa[0].id, aa[1].id};
        Test.setFixedSearchResults(fixedSearchResults);

        Test.startTest();
        list<sObject> accts = Typeahead.searchRecords( 'test', 'Account', null, null, null, null, null );
        Test.stopTest();

        system.assertEquals(2, accts.size());
        system.assertEquals('Another Account', accts[0].get('Name'));
        system.assertEquals('Test Account', accts[1].get('Name'));
    }
    @isTest static void test_data_test_factory_bigger_sample_size() {
        //TestDataFactory data = new TestDataFactory();
        //data.createBiggerSampleSize();
        //system.assert([SELECT COUNT() FROM Account] > 0);
        //system.assert([SELECT COUNT() FROM Provider__c] > 0);
        //system.assert([SELECT COUNT() FROM Opportunity] > 0);
        //system.assert([SELECT COUNT() FROM Address_Data__c] > 0);
        //system.assert([SELECT COUNT() FROM Location_Rule__c] > 0);
        //system.assert([SELECT COUNT() FROM Insurance_Payor__c] > 0);
        //system.assert([SELECT COUNT() FROM Request__c] > 0);
        //system.assert([SELECT COUNT() FROM Task] > 0);
        //system.assert([SELECT COUNT() FROM Location__c] > 0);
    }
}