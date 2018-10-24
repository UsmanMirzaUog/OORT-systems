/*
 * LocationFollowUpController: 100%
 */

@isTest
public class LocationFollowUpController_TEST {
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
        TestDataFactory.createAllCustomSettings();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.create_Locations();
        List<Location__c> locationList = new List<Location__c>([SELECT Id, Num_of_Patients__c FROM Location__c]);
        TestDataFactory.create_LocationADMTasks();
        System.debug([SELECT Id FROM RecordType WHERE Name = 'ADM']);
        List<Task> theTasks = new List<Task>([SELECT Id, WhatId, RecordType.Name, Location__c, Location__r.Name FROM Task]);
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        for (Task t : theTasks){
            t.WhatId = o.Id;
            t.Location__c = locationList[0].Id;
        }
        UPDATE theTasks;
        System.debug(theTasks);
        for (Location__c l : locationList){
            l.Num_of_Patients__c = 1;
        }
        UPDATE locationList;
        System.debug(locationList);
    }
    @isTest static void getFollowUpItems() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setCurrentPage(Page.LocationFollowUp);
        LocationFollowUpController ext = new LocationFollowUpController();

        List<LocationFollowUpController.FollowUpItem> followUpItems = LocationFollowUpController.getFollowUpItems();
        System.debug(followUpItems);
        system.assert(followUpItems.size() > 0);
    }

    @istest static void getFollowUpItems2() { //KHB
        //Make sure none get returned with Num of Patients under 1
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setCurrentPage(Page.LocationFollowUp);
        LocationFollowUpController ext = new LocationFollowUpController();


        List<Location__c> locationList = new List<Location__c>([SELECT Id, Num_of_Patients__c FROM Location__c]);
        for (Location__c l : locationList){
            l.Num_of_Patients__c = 0;
        }
        UPDATE locationList;
        System.debug(locationList);

        List<LocationFollowUpController.FollowUpItem> followUpItems = LocationFollowUpController.getFollowUpItems();
        System.debug(followUpItems);
        system.assertEquals(null, followUpItems);
    }

    @istest static void getFollowUpItems3() { //KHB
        //Make sure none get returned with no Documents
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.setCurrentPage(Page.LocationFollowUp);
        LocationFollowUpController ext = new LocationFollowUpController();

        List<Task> theTasks = new List<Task>([SELECT Id, WhatId, RecordType.Name, Location__c, Location__r.Name FROM Task]);
        DELETE theTasks;

        List<LocationFollowUpController.FollowUpItem> followUpItems = LocationFollowUpController.getFollowUpItems();
        System.debug(followUpItems);
        system.assertEquals( null, followUpItems);
    }
}