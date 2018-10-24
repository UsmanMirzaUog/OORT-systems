/**
 * trgTaskHandler_TEST
 * trgTask: 100%
 * trgTaskHandler: 98%
 */


@isTest
public class trgTaskHandler_TEST {
    private static Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
    private static Id CallLogRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Log').getRecordTypeId();
    private static Id OppNoteRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Opp Note').getRecordTypeId();
    private static Id ADMNoteRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();

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
        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_Address_Payor_Provider();
        TestDataFactory.createAllCustomSettings();
    }
    @isTest static void groupTasksUnderLocationBasedOnAddress_CreateNewLocation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
//        Account patient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
//        Address_Data__c addressData = [SELECT Id, Address_Line_2__c, City__c, Primary__c, State_Province__c, Street__c, Zip_Postal_Code__c, Account__c FROM Address_Data__c WHERE Account__c =: patient.Id LIMIT 1];
        Provider__c provider = [SELECT Id, Address__c,Address2__c, City__c, State__c, Zip__c FROM Provider__c LIMIT 1];
        List<Location__c> theLocationList = new List<Location__c>();
        List<Task> theTaskList = new List<Task>();
        for(Integer i = 0 ; i < 3 ; i++) {
            Location__c theLocation = new Location__c(of_Medical_Group_Task_Set__c = 50 * i, Provider_Rules_Score__c = 'Strict', Priority__c = '1 - New Customer',
                    Num_of_Patients__c = 5 * i,Address_Line_1__c = String.valueOf(i)+' Test Lane', Address_Line_2__c = 'Suite '+String.valueOf(i)+'00', City__c = 'San Diego', State__c = 'CA', Zip_Code__c = '92111');
            theLocationList.add(theLocation);
        }
        INSERT theLocationList;
        Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        for(Location__c theLocation : theLocationList) {
            for(Integer i = 0 ; i < 3 ; i++) {
                Task theTask = new Task(RecordTypeId = ADMRecordTypeId, Subject = 'Test ' + String.valueOf(i), Priority = 'Normal', Status = 'Not Started', Provider__c = provider.Id);
                theTaskList.add(theTask);
            }
        }
        test.startTest();
        INSERT theTaskList;
        test.stopTest();
        String locationKey = provider.Address__c +'!'+ provider.Address2__c +'!'+ provider.City__c +'!'+ provider.State__c +'!'+ provider.Zip__c;
        Location__c theNewLocation = [SELECT Id FROM Location__c WHERE Location_Key__c = : locationKey LIMIT 1];
        theTaskList = [SELECT Id, WhatId, Location__c FROM Task WHERE Id IN : theTaskList];
        for(Task theTask : theTaskList) {
            system.assert(theTask.Location__c == theNewLocation.Id);
        }
    }
    @isTest static void groupTasksUnderLocationBasedOnAddress_MatchExistingLocation() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Provider__c provider = [SELECT Id, Address__c,Address2__c, City__c, State__c, Zip__c FROM Provider__c LIMIT 1];
        Location__c theLocation = new Location__c(of_Medical_Group_Task_Set__c = 50, Provider_Rules_Score__c = 'Strict', Priority__c = '1 - New Customer', Num_of_Patients__c = 1,
                Address_Line_1__c = provider.Address__c, Address_Line_2__c = provider.Address2__c, City__c = provider.City__c, State__c = provider.State__c, Zip_Code__c = provider.Zip__c);
        INSERT theLocation;

        List<Task> theTaskList = new List<Task>();
        Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        for(Integer i = 0 ; i < 3 ; i++) {
            Task theTask = new Task(RecordTypeId = ADMRecordTypeId, Subject = 'Test ' + String.valueOf(i), Priority = 'Normal', Status = 'Not Started', Provider__c = provider.Id);
            theTaskList.add(theTask);
        }
        test.startTest();
        INSERT theTaskList;
        test.stopTest();
        theTaskList = [SELECT Id, WhatId, Location__c FROM Task WHERE Id IN : theTaskList];
        for(Task theTask : theTaskList) {
            system.assert(theTask.Location__c == theLocation.Id);
        }
    }
    @isTest static void groupTasksUnderLocationBasedOnAddress_MatchExistingLocation_OnUpdate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Provider__c provider = [SELECT Id, Address__c,Address2__c, City__c, State__c, Zip__c FROM Provider__c LIMIT 1];
        Location__c theLocation = new Location__c(of_Medical_Group_Task_Set__c = 50, Provider_Rules_Score__c = 'Strict', Priority__c = '1 - New Customer', Num_of_Patients__c = 1,
                Address_Line_1__c = provider.Address__c, Address_Line_2__c = provider.Address2__c, City__c = provider.City__c, State__c = provider.State__c, Zip_Code__c = provider.Zip__c);
        INSERT theLocation;

        List<Task> theTaskList = new List<Task>();
        Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        for(Integer i = 0 ; i < 3 ; i++) {
            Task theTask = new Task(RecordTypeId = ADMRecordTypeId, Subject = 'Test ' + String.valueOf(i), Priority = 'Normal', Status = 'Not Started');
            theTaskList.add(theTask);
        }
        INSERT theTaskList;
        test.startTest();
        for(Task theTask : theTaskList) {
            theTask.Provider__c = provider.Id;
        }
        UPDATE theTaskList;
        test.stopTest();
        theTaskList = [SELECT Id, WhatId, Location__c FROM Task WHERE Id IN : theTaskList];
        for(Task theTask : theTaskList) {
            system.assert(theTask.Location__c == theLocation.Id);
        }
    }
    @isTest static void TrackPatientsLastContactDate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        Task taskToInsert = new Task(RecordTypeId = CallLogRecordTypeId, Patient__c = patient.Id, Status = 'Completed', ActivityDate = system.today());
        test.startTest();
        INSERT taskToInsert;
        test.stopTest();

        patient = [SELECT Id, Last_Contact_Date__c FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        system.assert(patient.Last_Contact_Date__c == system.today());
    }
    @isTest static void TrackPatientsLastContactDate_NEGATIVETEST() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        Task taskToInsert1 = new Task(Status = 'Completed', Patient__c = patient.Id, RecordTypeId = OppNoteRecordType, ActivityDate = system.today());
        Task taskToInsert2 = new Task(RecordTypeId = CallLogRecordTypeId, Status = 'Completed', ActivityDate = system.today());
        test.startTest();
        INSERT new List<Task>{taskToInsert1,taskToInsert2};
        test.stopTest();

        patient = [SELECT Id, Last_Contact_Date__c FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        system.assert(patient.Last_Contact_Date__c != system.today());
    }

    @isTest static void testUpdateFollowUpDate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account patient = [SELECT Id FROM Account WHERE RecordTypeId = :recordTypeId LIMIT 1];
        Location__c location = new Location__c(Address_Line_1__c = '123 Main St');
        insert location;
        Request__c request = new Request__c(Name = 'Test Request', Patient__c = patient.Id);
        insert request;
        System.debug('location: ' + location);
        Task taskToInsert1 = new Task(RecordTypeId = ADMNoteRecordType, Location__c = location.Id, Status = 'Open', Request__c = request.Id, ActivityDate = system.today().addDays(3));
        Task taskToInsert2 = new Task(RecordTypeId = ADMNoteRecordType, Location__c = location.Id, Status = 'Open', Request__c = request.Id, ActivityDate = system.today().addDays(-2));
        INSERT new List<Task>{
                taskToInsert1, taskToInsert2
        };
        test.startTest();
        request.Completed__c = true;
        update request;
        location = new Location__c();
        location = [SELECT Id, Follow_Up_Date__c from Location__c];
        System.debug(location);
        System.assert(location.Follow_Up_Date__c != null);
        System.assertEquals(Date.today().addDays(2), location.Follow_Up_Date__c);
        test.stopTest();
    }

    @isTest static void SendNoteToSolaraHubOnTaskInsert() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account a = new Account();
        a.Name = 'Test Testington';
        a.External_Id__c = '1111111';
        insert a;

        Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.today();
        o.Amount = 10000;
        o.Tracker_External_Id__c = '1234-5678-90123';
        insert o;

        //Account patient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
       // Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Task trackerIdTask = new Task(WhatId = o.AccountId, Opportunity__c = o.Id, Tracker_External_Id__c = '1234-5678-90123', Status = 'Completed', Patient__c = a.Id, RecordTypeId = OppNoteRecordType, ActivityDate = system.today());
        insert trackerIdTask;
        Task taskToInsert2 = new Task(WhatId = o.AccountId, Opportunity__c = o.Id, RecordTypeId = OppNoteRecordType, Status = 'Completed', ActivityDate = system.today(), Send_To_Hub__c = true, Description = 'Note to the hub');
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        INSERT new List<Task>{taskToInsert2};
        Test.stopTest();

        List<Task> taskList = [SELECT Id FROM Task WHERE Successful_Send_To_Hub__c = true];
        system.assertEquals(taskList.size(), 1);
    }





    @isTest static void SendNoteToSolaraHubOnInsertADM(){
        //#157294726 KHB also send any tasks that are of type ADM
        Account a = new Account();
        a.Name = 'Test Testington';
        a.External_Id__c = '22222222';
        insert a;

        Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.today();
        o.Amount = 10000;
        o.Tracker_External_Id__c = '22222222';
        insert o;

        Location__c l = new Location__c(
                City__c = 'Huntington Beach',
                State__c = 'CA'
        );
        INSERT l;

        TestDataFactory.createAllCustomSettings();

        List<Task> theTasks = new List<Task>();
        Task trackerIdTaskADM = new Task(
                WhatId = o.AccountId,
                Opportunity__c = o.Id,
                Tracker_External_ID__c = '4444-2222-92648',
                Status = 'Completed',
                Patient__c = a.Id,
                RecordTypeId = ADMNoteRecordType,
                ActivityDate = system.today(),
                Send_To_Hub__c = true,
                Description = 'ADM Note to the hub 1',
                Location__c = l.Id
        );
        theTasks.add(trackerIdTaskADM);
        Task trackerIdTaskADM2 = new Task(
                WhatId = o.AccountId,
                Opportunity__c = o.Id,
                Tracker_External_ID__c = '4444-2222-92648',
                Status = 'Completed',
                Patient__c = a.Id,
                RecordTypeId = ADMNoteRecordType,
                ActivityDate = system.today(),
                Description = 'ADM Note to the hub 2',
                Location__c = l.Id
        );
        theTasks.add(trackerIdTaskADM2);


        test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
      //  INSERT theTasks;
        INSERT trackerIdTaskADM;
        INSERT trackerIdTaskADM2;
        test.stopTest();

        System.debug(trackerIdTaskADM.Id);
        System.debug(trackerIdTaskADM2.Id);
        System.debug(trackerIdTaskADM.WhatId);
        System.debug(trackerIdTaskADM2.WhatId);

        List<Task> taskList = [SELECT Id, Description, RecordType.Name FROM Task WHERE Successful_Send_To_Hub__c = true];
        System.debug(taskList);
        System.debug(taskList.size());
        system.assertEquals(taskList.size(), 2);
    }






    @isTest static void obtainTrackerIdFromTask() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // this method will insert a task with a tracker Id
        // and confirm it is written to the Opportunity

        Account patient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Task taskToInsert1 = new Task(WhatId = opp.AccountId, Opportunity__c = opp.Id, Tracker_External_Id__c = '1234-5678-90123', Status = 'Completed', Patient__c = patient.Id, RecordTypeId = OppNoteRecordType, ActivityDate = system.today());
        insert taskToInsert1;
        Task taskToInsert2 = new Task(WhatId = opp.AccountId, Opportunity__c = opp.Id, RecordTypeId = OppNoteRecordType, Status = 'Completed', ActivityDate = system.today());
        insert taskToInsert2;
        opp = [SELECT Id, Tracker_External_Id__c FROM Opportunity WHERE Id = :opp.Id];
        system.assertEquals(opp.Tracker_External_Id__c, '1234-5678-90123');


    }
    
    @isTest static void updateOppFollowUpDate() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        // this method will insert a task with a tracker Id
        // and confirm it is written to the Opportunity

        Account patient = [SELECT Id FROM Account WHERE RecordTypeId =: recordTypeId LIMIT 1];
        Opportunity opp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];
        Task taskToInsert1 = new Task(WhatId = opp.AccountId, Opportunity__c = opp.Id, Tracker_External_Id__c = '1234-5678-90123', Status = 'Completed', Patient__c = patient.Id, RecordTypeId = OppNoteRecordType, ActivityDate = system.today());
        insert taskToInsert1;
        Task taskToInsert2 = new Task(WhatId = opp.AccountId, Opportunity__c = opp.Id, RecordTypeId = OppNoteRecordType, Status = 'Completed', ActivityDate = system.today(), Follow_Up_Date__c = Date.newInstance(2018, 09, 01));
        insert taskToInsert2;
        opp = [SELECT Id, Tracker_External_Id__c, Next_Follow_Up_Date__c FROM Opportunity WHERE Id = :opp.Id];
        system.assertEquals(opp.Tracker_External_Id__c, '1234-5678-90123');
        system.assertEquals(opp.Next_Follow_Up_Date__c, Date.newInstance(2018, 09, 01));


    }
}