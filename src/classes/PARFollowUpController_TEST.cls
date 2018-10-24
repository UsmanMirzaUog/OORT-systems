/**
 * Created by krizia on 6/6/18.
 * PARFollowUpController: 94%
 */
@isTest
public class PARFollowUpController_TEST {
    private static Id PARNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PAR').getRecordTypeId();

    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req)
        {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"Test" : "Blah"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @testSetup static void setUpTestData() {
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.create_Locations();
        TestDataFactory.create_LocationADMTasks();
        TestDataFactory.createAllCustomSettings();
        List<Request__c> requests = [SELECT Id, ADM_Completed__c, PAR_Completed__c, Completed__c FROM Request__c];
        for (Request__c r : requests) {
            r.ADM_Completed__c = true;
            r.PAR_Request_Completed__c = true;
            r.Completed__c = false;
        }
        UPDATE requests;
        System.debug(requests);
        List<Task> parTasks = [SELECT Id, RecordTypeId FROM Task];
        for (Task t : parTasks) {
            t.RecordTypeId = PARNoteRecordTypeId;
            t.Status = 'Open';
        }
        UPDATE parTasks;
        System.debug(parTasks);
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
    }
    @isTest static void getFollowUpItems() {


        List<PARFollowUpController.QueueItems> followUpItems = PARFollowUpController.getWorkQueueItems('');
        system.assert(followUpItems.size() > 0);
    }




//    @isTest static void testUpdateRequest() {
//        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
//        Id requestId = [SELECT Id FROM Request__c LIMIT 1].Id;
//        PARFollowUpController.updateRequest(requestId, true);
//        system.assert([SELECT Completed__c FROM Request__c LIMIT 1].Completed__c == true);
//    }

//    @isTest static void testUrgentRequestQueue() {
//        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
//        List<PARFollowUpController.UrgentQueueItems> urgentQueueItems = TaskWorkQueueController.getUrgentQueueItems('');
//        System.debug('***** UrgentQueueItems: ' + urgentQueueItems);
//        System.assert(!urgentQueueItems.isEmpty());
//        System.assertEquals('Doctor Assistance', urgentQueueItems[0].urgentReason);
//        System.assertEquals('Sheldon Cooper', urgentQueueItems[0].providerName);
//        System.assertEquals('Call', urgentQueueItems[0].tasktype);
//    }


    @isTest static void testGetPatientNameForADMNoteModal() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id ptId = [SELECT Id FROM Account LIMIT 1].Id;
        Account pt = PARFollowUpController.getPatientNameForADMNoteModal(ptId);

        System.assertEquals('John Smith', pt.Name);
    }

    @isTest static void testUpdateRequestOwner() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id requestId = [SELECT Id FROM Request__c LIMIT 1].Id;
        Request__c r = [SELECT Id, PAR_Completed__c FROM Request__c WHERE Id =: requestId LIMIT 1 ];
        r.PAR_Completed__c = true;
        UPDATE r;

        PARFollowUpController.updateRequestOwner(requestId);
        Request__c testRequest = [SELECT ADM_Rep__c from Request__c WHERE Id = :requestId LIMIT 1];
        System.debug('Rep: '+ testRequest.ADM_Rep__c);
        System.debug('User: '+ UserInfo.getUserId());
        System.assertEquals(UserInfo.getUserId(), testRequest.ADM_Rep__c);
    }

    @isTest static void testUpdateTask() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id taskId = [SELECT Id FROM Task LIMIT 1].Id;

        PARFollowUpController.updateTask(taskId, false);
        Task testTask = [SELECT Status from Task WHERE Id = :taskId LIMIT 1];
        System.debug('Task Complete? : '+ testTask.Status);
        System.assertEquals('Not Started', testTask.Status);

        PARFollowUpController.updateTask(taskId, true);
        testTask = [SELECT Status from Task WHERE Id = :taskId LIMIT 1];
        System.debug('Task Complete 2? : '+ testTask.Status);
        System.assertEquals('Completed', testTask.Status);
    }

    @isTest static void testGetPatient() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id ptId = [SELECT Id FROM Account LIMIT 1].Id;

        Account pt = ADMPatientModalDetailModalController.getPatient(ptId);

        System.assertEquals('John Smith', pt.Name);
        System.assertEquals('123 Test Lane', pt.BillingStreet);
        System.assertEquals('San Diego', pt.BillingCity);
        System.assertEquals('CA', pt.BillingState);
        System.assertEquals('92111', pt.BillingPostalCode);
    }

    @isTest static void testGetMaufacturerList() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<SelectOption> manufacturers = PARFollowUpController.getManufacturerList();

        System.assert(!manufacturers.isEmpty());
    }

    @isTest static void testSaveADMNote() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account a = [SELECT Id FROM Account LIMIT 1];
        Request__c r = [SELECT Id, Opportunity__c, Patient__c FROM Request__c LIMIT 1];
        Opportunity o = new Opportunity(
                Name = 'test',
                AccountId = a.Id,
                CloseDate = System.today(),
                StageName = 'New Opportunity',
                Tracker_External_Id__c = '483290-89-1'
        );
        INSERT o;
        r.Opportunity__c = o.Id;
        UPDATE r;
        Id ptId = a.Id;
        Id requestId = r.Id;
        String result = PARFollowUpController.saveADMNote(ptId, requestId, 'Test note body', true, 'Claycom');
        System.debug('result from saveADMNote: ' + result);

        List<Task> tasks = [SELECT Id, Subject, Description, WhatId, Request__c, Send_to_Manufacturer__c, Manufacturer__c, Status
        FROM Task WHERE WhatId = :o.Id AND Subject = 'Patient Note'];
        System.debug(tasks);

        System.assert(!tasks.isEmpty());
        System.assertEquals('Patient Note', tasks[0].Subject);
        System.assertEquals('Test note body', tasks[0].Description);
        System.assertEquals(o.Id, tasks[0].WhatId);
        System.assertEquals(requestId, tasks[0].Request__c);
        System.assertEquals(true, tasks[0].Send_to_Manufacturer__c);
        System.assertEquals('Claycom', tasks[0].Manufacturer__C);
        System.assertEquals('Completed', tasks[0].Status);
    }


//    //#158017071 Location Rules buttons
//    @isTest static void testGetLocationRules() {
//        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
//
//        TestDataFactory.create_Oppties_with_Patient();
//        TestDataFactory.create_Address_Payor_Provider();
//        TestDataFactory.create_Locations();
//        TestDataFactory.create_Requests();
//        TestDataFactory.createUrgentRequestItems();
//
//        TaskWorkQueueController.getWorkQueueItems('all');
//
//        TestDataFactory.create_LocationRules();
//        TestDataFactory tdf = new TestDataFactory();
//        Test.startTest();
//        //tdf.createBiggerSampleSize();
//        Test.stopTest();
//        TaskWorkQueueController.getWorkQueueItems('all');
//
//        Id locationId = [SELECT Id FROM Location__c LIMIT 1].Id;
//        List<Location_Rule__c> rules = TaskWorkQueueController.getLocationRules(locationId);
//
//        System.debug(rules);
//        System.assert(rules.size() > 0);
//    }

}