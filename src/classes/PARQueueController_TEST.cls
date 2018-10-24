/**
 * Created by krizia on 6/6/18.
 * PARQueueController: 95%
 */
@isTest
public class PARQueueController_TEST {
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



    @testSetup static void setupTestData() {
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.create_Requests();
        TestDataFactory.createAllCustomSettings();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<Request__c> requests = new List<Request__c>();
        requests = [SELECT Id, Patient__c FROM Request__c];
        List<Task> PARTasks = new List<Task>();

        for (Request__c r : requests){
            Task t = new Task(
                    RecordTypeId = PARNoteRecordTypeId,
                    WhatId = r.Patient__c,
                    Request__c = r.Id
            );
            PARTasks.add(t);
        }
        System.debug(PARTasks);
        INSERT PARTasks;

        PARQueueController controller = new PARQueueController();
    }

    @isTest static void testPARQueueItems() {
        //system.assert(!PARQueueController.getWIPStateOptions().isEmpty());

        //List<PARQueueController.PARQueueItems> queueItems = PARQueueController.getPARQueueItems('all');
        //system.assert(!queueItems.isEmpty());

        //queueItems = PARQueueController.getPARQueueItems('3 - Reorder');
        //system.assert(queueItems.size() == 1);
    }

    @isTest static void testUpdateRequest() {
        Id requestId = [SELECT Id FROM Request__c LIMIT 1].Id;
        PARQueueController.updateRequest(requestId, true);
        system.assert([SELECT PAR_Request_Completed__c FROM Request__c LIMIT 1].PAR_Request_Completed__c == true);
    }

//    @isTest static void testUrgentPARRequestQueue() {
//        List<PARQueueController.UrgentPARQueueItems> urgentPARQueueItems = PARQueueController.getUrgentPARQueueItems('');
//        System.debug('***** UrgentPARQueueItems: ' + urgentPARQueueItems);
//        System.assert(!urgentPARQueueItems.isEmpty());
//        System.assertEquals('Doctor Assistance', urgentPARQueueItems[0].urgentReason);
//        System.assertEquals('Sheldon Cooper', urgentPARQueueItems[0].providerName);
//        System.assertEquals('Call', urgentPARQueueItems[0].tasktype);
//    }

    @isTest static void testUpdateRequestOwner() {
        Id requestId = [SELECT Id FROM Request__c LIMIT 1].Id;

        PARQueueController.updateRequestOwner(requestId);
        Request__c testRequest = [SELECT ADM_Rep__c from Request__c WHERE Id = :requestId LIMIT 1];
        System.debug('Rep: '+ testRequest.ADM_Rep__c);
        System.debug('User: '+ UserInfo.getUserId());
        System.assertEquals(UserInfo.getUserId(), testRequest.ADM_Rep__c);
    }

    @isTest static void testUpdateTask() {
        Id taskId = [SELECT Id FROM Task LIMIT 1].Id;

        PARQueueController.updateTask(taskId, false);
        Task testTask = [SELECT Status from Task WHERE Id = :taskId LIMIT 1];
        System.debug('Task Complete? : '+ testTask.Status);
        System.assertEquals('Not Started', testTask.Status);

        PARQueueController.updateTask(taskId, true);
        testTask = [SELECT Status from Task WHERE Id = :taskId LIMIT 1];
        System.debug('Task Complete 2? : '+ testTask.Status);
        System.assertEquals('Completed', testTask.Status);
    }

    @isTest static void testGetPatient() {
        Id ptId = [SELECT Id FROM Account LIMIT 1].Id;

        Account pt = ADMPatientModalDetailModalController.getPatient(ptId);

        System.assertEquals('John Smith', pt.Name);
        System.assertEquals('123 Test Lane', pt.BillingStreet);
        System.assertEquals('San Diego', pt.BillingCity);
        System.assertEquals('CA', pt.BillingState);
        System.assertEquals('92111', pt.BillingPostalCode);
    }

    @isTest static void testInsurers() {
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
        Id ptId = [SELECT Id FROM Account LIMIT 1].Id;
        Account pt = PARQueueController.getPatientNameForADMNoteModal(ptId);

        System.assertEquals('John Smith', pt.Name);
    }

    @isTest static void testGetMaufacturerList() {
        List<SelectOption> manufacturers = PARQueueController.getManufacturerList();

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
        String result = PARQueueController.saveADMNote(ptId, requestId, 'Test note body', true, 'Claycom');
        System.debug('result from saveADMNote: ' + result);

        List<Task> tasks = [SELECT Id, Subject, Description, WhatId, Request__c, Send_to_Manufacturer__c, Manufacturer__c, Status
        FROM Task WHERE WhatId = :o.AccountId AND Subject = 'PAR Note'];
        System.debug(tasks);

        System.assert(!tasks.isEmpty());
        System.assertEquals('PAR Note', tasks[0].Subject);
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
        //     TestDataFactory.createUrgentRequestItems();

        PARQueueController.getPARQueueItems('all');

        TestDataFactory.create_LocationRules();
        TestDataFactory tdf = new TestDataFactory();
        //   tdf.createBiggerSampleSize();
        PARQueueController.getPARQueueItems('all');

        Id locationId = [SELECT Id FROM Location__c LIMIT 1].Id;
        List<Location_Rule__c> rules = PARQueueController.getLocationRules(locationId);

        System.debug(rules);
        System.assert(rules.size() > 0);
    }




}