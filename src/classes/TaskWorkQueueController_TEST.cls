/**
 * Created by danielpulache on 11/7/17.
 * TaskWorkQueueController: 91%
 * TaskWorkQueueController_TEST: 92%
 */
@isTest
public class TaskWorkQueueController_TEST {

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

    @testSetup static void setupTestData() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.createUrgentRequestItems();

        Insurance_Patient_Junction__c ipj = new Insurance_Patient_Junction__c(
                Requires_PAR__c = true,
                Account__c = [SELECT Patient__c FROM Request__c LIMIT 1].Patient__c,
                Insurance__c = [SELECT Id FROM Insurance_Payor__c LIMIT 1].Id
        );
        INSERT ipj;

        List<Task> theTasks = [SELECT Id, WhatId, Request__c FROM Task];
        Id theReqId = [SELECT Id FROM Request__c LIMIT 1].Id;
        for (Task t : theTasks) {
            t.Request__c = theReqId;
            t.WhatId = theReqId;
        }
        UPDATE theTasks;

        TestDataFactory.createAllCustomSettings();
        TaskWorkQueueController controller = new TaskWorkQueueController();
    }

    @isTest static void testWorkQueueItems() {
        system.assert(!TaskWorkQueueController.getWIPStateOptions().isEmpty());

        List<TaskWorkQueueController.QueueItems> queueItems = TaskWorkQueueController.getWorkQueueItems('all');
        system.assert(!queueItems.isEmpty());

        queueItems = TaskWorkQueueController.getWorkQueueItems('3 - Reorder');
        system.assert(queueItems.size() == 1);
    }

    @isTest static void testUpdateRequest() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id requestId = [SELECT Id FROM Request__c LIMIT 1].Id;
        TaskWorkQueueController.updateRequest(requestId, true);
        system.assert([SELECT Completed__c FROM Request__c LIMIT 1].Completed__c == true);
    }

    @isTest static void testUrgentRequestQueue() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<TaskWorkQueueController.UrgentQueueItems> urgentQueueItems = TaskWorkQueueController.getUrgentQueueItems('');
        System.debug('***** UrgentQueueItems: ' + urgentQueueItems);
        System.assert(!urgentQueueItems.isEmpty());
        System.assertEquals('Doctor Assistance', urgentQueueItems[0].urgentReason);
        System.assertEquals('Sheldon Cooper', urgentQueueItems[0].providerName);
        System.assertEquals('Call', urgentQueueItems[0].tasktype);
    }

    @isTest static void testUpdateRequestOwner() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id requestId = [SELECT Id FROM Request__c LIMIT 1].Id;

        TaskWorkQueueController.updateRequestOwner(requestId);
        Request__c testRequest = [SELECT ADM_Rep__c from Request__c WHERE Id = :requestId LIMIT 1];
        System.debug('Rep: '+ testRequest.ADM_Rep__c);
        System.debug('User: '+ UserInfo.getUserId());
        System.assertEquals(UserInfo.getUserId(), testRequest.ADM_Rep__c);
    }

    @isTest static void testUpdateTask() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id taskId = [SELECT Id FROM Task LIMIT 1].Id;

        TaskWorkQueueController.updateTask(taskId, false);
        Task testTask = [SELECT Status from Task WHERE Id = :taskId LIMIT 1];
        System.debug('Task Complete? : '+ testTask.Status);
        System.assertEquals('Not Started', testTask.Status);

        TaskWorkQueueController.updateTask(taskId, true);
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

    @isTest static void testInsurers() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id ptId = [SELECT Id FROM Account LIMIT 1].Id;

        List<Insurance_Payor__c> payors = new List<Insurance_Payor__c>();
        payors.add(new Insurance_Payor__c(Name = 'Primary Insurance'));
        payors.add(new Insurance_Payor__c(Name = 'Secondary Insurance'));

        INSERT payors;

        List<Insurance_Patient_Junction__c> insurers = new List<Insurance_Patient_Junction__c>();
        insurers.add(new Insurance_Patient_Junction__c(Insurance__c = payors[0].Id, Account__c = ptId, Policy_Level__c = 'Primary'));
        insurers.add(new Insurance_Patient_Junction__c(Insurance__c = payors[1].Id, Account__c = ptId, Policy_Level__c = 'Secondary'));

        INSERT insurers;

        Insurance_Patient_Junction__c primary = ADMPatientModalDetailModalController.getPrimaryInsurance(ptId);
        Insurance_Patient_Junction__c secondary = ADMPatientModalDetailModalController.getSecondaryInsurance(ptId);

        System.assertEquals('Primary Insurance', primary.Insurance__r.Name);
        System.assertEquals('Secondary Insurance', secondary.Insurance__r.Name);
    }

    @isTest static void testGetPatientNameForADMNoteModal() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Id ptId = [SELECT Id FROM Account LIMIT 1].Id;
        Account pt = TaskWorkQueueController.getPatientNameForADMNoteModal(ptId);

        System.assertEquals('John Smith', pt.Name);
    }

    @isTest static void testGetMaufacturerList() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<SelectOption> manufacturers = TaskWorkQueueController.getManufacturerList();

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
        String result = TaskWorkQueueController.saveADMNote(ptId, requestId, 'Test note body', true, 'Claycom');
        System.debug('result from saveADMNote: ' + result);

        List<Task> tasks = [SELECT Id, Subject, Description, WhatId, Request__c, Send_to_Manufacturer__c, Manufacturer__c, Status
                FROM Task WHERE WhatId = :o.AccountId AND Subject = 'ADM Note'];
        System.debug(tasks);

        System.assert(!tasks.isEmpty());
        System.assertEquals('ADM Note', tasks[0].Subject);
        System.assertEquals('Test note body', tasks[0].Description);
        System.assertEquals(o.AccountId, tasks[0].WhatId);
        System.assertEquals(requestId, tasks[0].Request__c);
        System.assertEquals(true, tasks[0].Send_to_Manufacturer__c);
        System.assertEquals('Claycom', tasks[0].Manufacturer__C);
        System.assertEquals('Completed', tasks[0].Status);
    }


    //#158017071 Location Rules buttons
    @isTest static void testGetLocationRules() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Locations();
        TestDataFactory.create_Requests();
        TestDataFactory.createUrgentRequestItems();

        TaskWorkQueueController.getWorkQueueItems('all');

        TestDataFactory.create_LocationRules();
        TestDataFactory tdf = new TestDataFactory();
        Test.startTest();
        //tdf.createBiggerSampleSize();
        Test.stopTest();
        TaskWorkQueueController.getWorkQueueItems('all');

        Id locationId = [SELECT Id FROM Location__c LIMIT 1].Id;
        List<Location_Rule__c> rules = TaskWorkQueueController.getLocationRules(locationId);

        System.debug(rules);
        System.assert(rules.size() > 0);
    }
}