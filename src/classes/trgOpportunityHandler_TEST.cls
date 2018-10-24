/**
 * trgOpportunity: 100%
 * trgOpportunityHandler: 96%
 * BatchOpportunityInsert: 90%
 **/

@isTest
private class trgOpportunityHandler_TEST
{
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
    @testSetup public static void SetUpData() {

        TestDataFactory.createAllCustomSettings();

        List<AsyncApexJob> batchIds = new List<AsyncApexJob>([SELECT Id FROM AsyncApexJob]);
        for (AsyncApexJob b : batchIds){
            System.abortJob(b.Id);
            System.debug('Aborting job in trgOpportunityHandler_TEST');
        }
  }

    @isTest
        static void testOpportunityInsertAssign() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                FirstName = 'Clayton',
                LastName = 'Boss',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
                //UserRoleId = r.Id
        );

        insert u;

        User u2 = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'BossHog',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
                //UserRoleId = r.Id
        );

        insert u2;

        Account a = new Account();
        a.Name = 'Clays Account';
        a.External_Id__c = '1232342-234243234-2342342';
        insert a;


        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.Name = 'Test Opp';
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Order_Owner__c = 'Boss, Clayton';

        insert o;

        Task t = new Task();
        t.Subject='Whats up';
        t.Description='Description';
        t.whatId = o.AccountId;
        t.Opportunity__c = o.Id;
        t.status='Completed';
        insert t;

        Opportunity opp = [SELECT OwnerId FROM Opportunity];
        system.assertEquals(opp.OwnerId, u.Id);

    }

    @isTest
    static void testOpportunityUpdateAssign() {
        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                FirstName = 'Clayton',
                LastName = 'Boss',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
                //UserRoleId = r.Id
        );

        insert u;

        User u2 = new User(

                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                FirstName = 'Clay',
        LastName = 'BossHog',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
                //UserRoleId = r.Id

        );

        insert u2;

        Account a = new Account();
        a.Name = 'Clays Account';
        a.External_Id__c = '1232342-234243234-2342342';
        insert a;


        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.Name = 'Test Opp';
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Order_Owner__c = 'Boss, Clayton';

        insert o;

        o.Order_Owner__c = 'BossHog, Clay';
        update o;


        Task t = new Task();
        t.Subject='Whats up';
        t.Description='Description';
        t.whatId = o.AccountId;
        t.Opportunity__c = o.Id;
        t.status='Completed';
        insert t;

        Opportunity opp = [SELECT OwnerId FROM Opportunity];
        system.assertEquals(opp.OwnerId, u2.Id);

    }


    @isTest
    static void testOpportunityInsertAssignNoMatchUsers() {

        User u = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                FirstName = 'Clayton',
                LastName = 'Boss',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
                //UserRoleId = r.Id
        );

        insert u;

        User u2 = new User(
                ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                LastName = 'BossHog',
                Email = 'puser000@amamama.com',
                Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                CompanyName = 'TEST',
                Title = 'title',
                Alias = 'alias',
                TimeZoneSidKey = 'America/Los_Angeles',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US'
                //UserRoleId = r.Id
        );

        insert u2;


        Account a = new Account();
        a.Name = 'The Man';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.Name = 'Test Opp';
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Order_Owner__c = 'BossMaximus, Clay';
        insert o;

        system.assertNotEquals(o.OwnerId, u.Id);
        system.assertNotEquals(o.OwnerId, u2.Id);

    }
    @isTest
    static void testDexcomOpportunityDoctorString()
    {

        // format: Concatenate: Full Name - Address - NPI: - PH: [] Fx: []

    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account a = new Account();
        a.Name = 'Test Person';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Name = 'Clays Test Opp';
        o.Amount = 1000;
        //o.Manufacturer__c = 'Dexcom';
        O.Dexcom_Opp_ID__c = '123456';
        insert o;

        Provider__c p = new Provider__c();
        p.Name = 'Jones';
        p.Address__c='100 River Drive';
        p.Address2__c='Suite 1000';
        p.City__c = 'Pittsburgh';
        p.Zip__c = '90210';
        p.State__c = 'PA';
        p.Email__c = 'test@test.com';
        p.Phone__c = '412-555-1212';
        p.NPI__c = '1122334455';
        p.Fax__c = '412-666-2222';

        insert p;

        Provider_Patient_Junction__c ppj = new Provider_Patient_Junction__c();
        ppj.Provider__c = p.Id;
        ppj.Patient__c = a.Id;
        ppj.PCP__c = true;
        insert ppj;

        o.StageName = 'Closed/Lost';
        update o;

        Opportunity dexcomOpp = [SELECT Dexcom_Doctor__c FROM Opportunity WHERE Id = :o.Id];
        system.debug (dexcomOpp);
        system.assertEquals(dexcomOpp.Dexcom_Doctor__c, 'Jones - 100 River Drive Suite 1000 Pittsburgh PA 90210 - NPI:1122334455 - Ph:[412-555-1212] - FX:[412-666-2222]');

    }
    @isTest
    static void testDexcomOpportunityPrimaryInsurance()
    {

        // Concatenate: Payor Name - ID:[customer ID]

    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Account a = new Account();
        a.Name = 'Test Person';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Name = 'Clays Test Opp';
        o.Amount = 1000;
        o.Dexcom_Opp_Id__c = '111111';
        //o.Manufacturer__c = 'Dexcom';
        insert o;

        Provider__c p = new Provider__c();
        p.Name = 'Jones';
        p.Address__c='100 River Drive';
        p.Address2__c='Suite 1000';
        p.City__c = 'Pittsburgh';
        p.Zip__c = '90210';
        p.State__c = 'PA';
        p.Email__c = 'test@test.com';
        p.Phone__c = '412-555-1212';
        p.NPI__c = '1122334455';
        p.Fax__c = '412-666-2222';

        insert p;

        Insurance_Payor__c i = new Insurance_Payor__c();
        i.Name = 'Payor 1';
        insert i;

        Insurance_Patient_Junction__c ipj = new Insurance_Patient_Junction__c();
        ipj.Account__c = a.Id;
        ipj.Insurance__c = i.Id;
        ipj.Policy_Level__c = 'Primary';
        ipj.Policy_Id__c = 911;
        insert ipj;

        Insurance_Patient_Junction__c ipj2 = new Insurance_Patient_Junction__c();
        ipj2.Account__c = a.Id;
        ipj2.Insurance__c = i.Id;
        ipj2.Policy_Level__c = 'Secondary';
        ipj2.Policy_Id__c = 1000;
        insert ipj2;


        Provider_Patient_Junction__c ppj = new Provider_Patient_Junction__c();
        ppj.Provider__c = p.Id;
        ppj.Patient__c = a.Id;
        ppj.PCP__c = true;
        insert ppj;

        o.StageName = 'Closed/Lost';
        update o;
        system.debug(o);

        Opportunity dexcomOpp = [SELECT Dexcom_Primary__c FROM Opportunity WHERE Id = :o.Id];
        system.debug (dexcomOpp);
        system.assertEquals(dexcomOpp.Dexcom_Primary__c, 'Payor 1 - ID:[911]');

    }

    @isTest
    static void testDexcomOpportunitySecondaryInsurance()
    {

        // Concatenate: Payor Name - ID:[customer ID]

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account a = new Account();
        a.Name = 'Test Person';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Name = 'Clays Test Opp';
        o.Amount = 1000;
        //o.Manufacturer__c = 'Dexcom';
        o.Dexcom_Opp_Id__c = '111111';
        insert o;

        Provider__c p = new Provider__c();
        p.Name = 'Jones';
        p.Address__c='100 River Drive';
        p.Address2__c='Suite 1000';
        p.City__c = 'Pittsburgh';
        p.Zip__c = '90210';
        p.State__c = 'PA';
        p.Email__c = 'test@test.com';
        p.Phone__c = '412-555-1212';
        p.NPI__c = '1122334455';
        p.Fax__c = '412-666-2222';

        insert p;

        Insurance_Payor__c i = new Insurance_Payor__c();
        i.Name = 'Payor 1';
        insert i;

        Insurance_Payor__c i2 = new Insurance_Payor__c();
        i2.Name = 'Payor 2';
        insert i2;

        Insurance_Patient_Junction__c ipj = new Insurance_Patient_Junction__c();
        ipj.Account__c = a.Id;
        ipj.Insurance__c = i.Id;
        ipj.Policy_Level__c = 'Primary';
        ipj.Policy_Id__c = 911;
        insert ipj;

        Insurance_Patient_Junction__c ipj2 = new Insurance_Patient_Junction__c();
        ipj2.Account__c = a.Id;
        ipj2.Insurance__c = i2.Id;
        ipj2.Policy_Level__c = 'Secondary';
        ipj2.Policy_Id__c = 1000;
        insert ipj2;


        Provider_Patient_Junction__c ppj = new Provider_Patient_Junction__c();
        ppj.Provider__c = p.Id;
        ppj.Patient__c = a.Id;
        ppj.PCP__c = true;
        insert ppj;

        o.StageName = 'Closed/Lost';
        update o;

        Opportunity dexcomOpp = [SELECT Dexcom_Secondary__c FROM Opportunity WHERE Id = :o.Id];
        system.debug (dexcomOpp);
        system.assertEquals(dexcomOpp.Dexcom_Secondary__c, 'Payor 2 - ID:[1000]');

    }

    @isTest
    static void testDexcomOpportunityNotesDexcom() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account a = new Account();
        a.Name = 'Test Person';
        a.External_Id__c = '66666-666666-6666';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Name = 'Clays Test Opp';
        o.Amount = 1000;
        //o.Manufacturer__c = 'Dexcom';
        o.Dexcom_Opp_Id__c = '111111';
        insert o;

        Task t = new Task();
        t.Patient__c = a.Id;
        t.Subject = 't1';
        t.Description = 'd1';
        t.Status = 'Completed';
        t.WhatId = o.AccountId;
        t.Opportunity__c = o.Id;
        t.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Task' AND Name = 'Opp Note'].Id;
        insert t;


        Task t2 = new Task();
        t2.Patient__c = a.Id;
        t2.Subject = 't2';
        t2.Description = 'd2';
        t2.Status = 'Completed';
        t2.WhatId = o.AccountId;
        t2.Opportunity__c = o.Id;
        t2.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Task' AND Name = 'Opp Note'].Id;

        insert t2;

        Task t3 = new Task();
        t3.Patient__c = a.Id;
        t3.Subject = 't3';
        t3.Description = 'd3';
        t3.Status = 'Completed';
        t3.WhatId = o.AccountId;
        t3.Opportunity__c = o.Id;
        t3.RecordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Task' AND Name = 'Opp Note'].Id;
        insert t3;

        Test.setCreatedDate(t.Id, DateTime.newInstance(2018,1,1));
        Test.setCreatedDate(t2.Id, DateTime.newInstance(2018,1,2));
        Test.setCreatedDate(t3.Id, DateTime.newInstance(2018,1,3));

        o.StageName = 'Closed/Lost';
        update o;

        Test.startTest();

        Opportunity dexcomOpp = [SELECT Opportunity_Notes__c FROM Opportunity WHERE Id = :o.Id];
        t = [SELECT CreatedDate FROM Task WHERE Id = :t.Id];
        t2 = [SELECT CreatedDate FROM Task WHERE Id = :t2.Id];
        t3 = [SELECT CreatedDate FROM Task WHERE Id = :t3.Id];

        String tDate = t.CreatedDate.format();
        String t2Date = t2.CreatedDate.format();
        String t3Date = t3.CreatedDate.format();

        system.debug (dexcomOpp);
        //system.assertEquals(dexcomOpp.Opportunity_Notes__c, 'Date: ' + t3Date + '\n' + 'Subject: t3\nDescription: d3\nRecord Type: Opp Note\n\nDate: ' + t2Date + '\n' + 'Subject: t2\nDescription: d2\nRecord Type: Opp Note\n\nDate: ' + tDate + '\n' + 'Subject: t1\nDescription: d1\nRecord Type: Opp Note');
        system.assertEquals('Date: 1/3/2018 12:00 AM' + '\n' + 'Subject: t3\nDescription: d3\nRecord Type: Opp Note\n\nDate: 1/2/2018 12:00 AM' + '\n' + 'Subject: t2\nDescription: d2\nRecord Type: Opp Note\n\nDate: 1/1/2018 12:00 AM' + '\n' + 'Subject: t1\nDescription: d1\nRecord Type: Opp Note', 'Date: ' + t3Date + '\n' + 'Subject: t3\nDescription: d3\nRecord Type: Opp Note\n\nDate: ' + t2Date + '\n' + 'Subject: t2\nDescription: d2\nRecord Type: Opp Note\n\nDate: ' + tDate + '\n' + 'Subject: t1\nDescription: d1\nRecord Type: Opp Note');

        Test.stopTest();

    }

    @isTest
    static void testDexcomCloseReasons() {
    Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account a = new Account();
        a.Name = 'Test Person';
        a.External_Id__c = '66666-666666-6666';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Name = 'Clays Test Opp';
        o.Amount = 1000;
        //o.Manufacturer__c = 'Dexcom';
        o.Dexcom_Opp_Id__c = '111111';
        o.StageName = 'Test Stage';
        o.Status__c = 'Test Status';
        insert o;


        Close_Reason__c cr1 = new Close_Reason__c();
        cr1.Stage__c = 'Test Stage';
        cr1.Status__c = 'Test Status';
        cr1.Close_Reason__c = 'Test Success';
        insert cr1;

        Close_Reason__c cr2 = new Close_Reason__c();
        cr2.Stage__c = 'Test Stage 2';
        cr2.Status__c = 'Test Status 2';
        cr2.Close_Reason__c = 'Test Success 2';
        insert cr2;

        List<Close_Reason__c> crs = [SELECT Id, Status__c, Close_Reason__c FROM Close_Reason__c];
        system.debug('crs :: ' + crs);

        o.StageName = 'Closed/Lost';
        update o;



        Opportunity dexcomOpp = [SELECT Close_Reason__c FROM Opportunity WHERE Id = :o.Id];
        system.debug (dexcomOpp);
        system.assertEquals(dexcomOpp.Close_Reason__c, 'Test Success');

    }

    @isTest
    static void testAssignPriceBook() {

        Account a = new Account();
        a.Name = 'Test Person';
        insert a;

        Opportunity o = new Opportunity();
        o.AccountId = a.Id;
        o.StageName = 'New Opportunity';
        o.CloseDate = system.Today();
        o.Name = 'Clays Test Opp';
        o.Amount = 1000;
        o.Manufacturer__c = 'Claycom';
        insert o;

        Id pb = Test.getStandardPricebookId();

        Id oppBP = [SELECT PriceBook2Id FROM Opportunity LIMIT 1].PriceBook2Id;

        system.assertEquals(pb, oppBP);
    }


    @isTest
    static void testDexcomNotesInsert(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //Clear the board
        //  List<Account> aList = [SELECT Id FROM Account];
        List<Opportunity> oList = [SELECT Id FROM Opportunity];
        List<Task> tList = [SELECT Id FROM Task];
        //  if (aList.size() > 0) DELETE aList;
        if (oList.size() > 0) DELETE oList;
        if (tList.size() > 0) DELETE tList;

        Account a = new Account(
                Name = 'Drover-Stark Tech Industries'
        );
        INSERT a;

        Opportunity o = new Opportunity(
                AccountId = a.Id,
                StageName = 'New Opportunity',
                CloseDate = system.Today(),
                Name = 'Test Opp',
                Amount = 8888,
                Manufacturer__c = 'Claycom',
                Dexcom_Opp_Id__c = '1508',
                Dexcom_Opportunity_Notes__c = 'I am a note that should be a task.'
        );
        INSERT o;

        System.debug([SELECT Id, Subject, Description FROM Task]);
        System.assert(1 == [SELECT Count() FROM Task Where Opportunity__c =: o.Id]);
    }//@isTest static void testDexcomNotesInsert()


    //#157528613 KHB Opportunity Dexcom Notes as Tasks
    @isTest
    static void testDexcomNotesUpdate(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        //Clear the board
    //  List<Account> aList = [SELECT Id FROM Account];
        List<Opportunity> oList = [SELECT Id FROM Opportunity];
        List<Task> tList = [SELECT Id FROM Task];
    //  if (aList.size() > 0) DELETE aList;
        if (oList.size() > 0) DELETE oList;
        if (tList.size() > 0) DELETE tList;

        Account a = new Account(
                Name = 'Drover-Stark Tech Industries'
        );
        INSERT a;
        Opportunity o2 = new Opportunity(
                AccountId = a.Id,
                StageName = 'New Opportunity',
                CloseDate = system.Today(),
                Name = 'Test Opp2',
                Amount = 2222,
                Manufacturer__c = 'Claycom',
                Dexcom_Opp_Id__c = '12555'
        );
        INSERT o2;


        //Now testing an update of an Opp that didn't create a Task on insert
        o2 = [SELECT Id, Amount, Dexcom_Opportunity_Notes__c, Dexcom_Opp_Id__c FROM Opportunity WHERE Amount = 2222 LIMIT 1];
        System.debug(o2);
        o2.Dexcom_Opportunity_Notes__c = 'I am a note on an updated opp that should be the first task.';
        UPDATE o2;
        System.debug(o2);

        //UPDATE of o2 should have triggered a first time Dexcom Opp note
        System.debug([SELECT Id, Subject, Description, WhatId FROM Task WHERE Opportunity__c =: o2.Id]);
        System.assert(1 == [SELECT Count() FROM Task WHERE Opportunity__c =: o2.Id]);
    } //@isTest static void testDexcomNotesUpdate()

    //#157295832 KHB Tasks update Opportunity Note field on Opp
    @isTest static void testCreateTaskAsOppNote(){
        //Clear the board
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        List<Opportunity> oppList = [SELECT Id FROM Opportunity];
        if (oppList.size() > 0) { DELETE oppList; }
        List<Task> taskList = [SELECT Id FROM Task];
        if (taskList.size() > 0) { DELETE taskList; }

        Account a = new Account(
                Name = 'Drover Industries',
                External_Id__c = '1111'
        );
        INSERT a;

        Opportunity o = new Opportunity(
                AccountId = a.Id,
                StageName = 'New Opportunity',
                CloseDate = system.Today(),
                Name = 'Test Opp',
                Amount = 8888,
                Manufacturer__c = 'Claycom',
                Dexcom_Opp_Id__c = '1508',
                Dexcom_Opportunity_Notes__c = 'I am a note that should be a task.',
                Opportunity_Notes__c = null,
                Tracker_External_Id__c = '111'
        );
        INSERT o;
        Id recordTypeId = [SELECT Id FROM RecordType WHERE SobjectType = 'Task' AND Name = 'ADM' LIMIT 1].Id;

        o = [SELECT Id, AccountId, Opportunity_Notes__c FROM Opportunity WHERE Id =: o.Id LIMIT 1];
        System.assertEquals(null, o.Opportunity_Notes__c);
        Task t = new Task(
                WhatId = o.AccountId,
                Opportunity__c = o.Id,
                Description = 'I am an ADM task that should be sent to Dexcom. ',
                RecordTypeId = recordTypeId,
                Status = 'Open',
                Patient__c = a.Id
        );
        INSERT t;
        o = [SELECT Id, Opportunity_Notes__c FROM Opportunity WHERE Id =: o.Id LIMIT 1];
        System.debug(o.Opportunity_Notes__c);
        //System.assertNotEquals(o.Opportunity_Notes__c, null);
        // System.assertNotEquals(null, null);
    } //@isTest static void testCreateTaskAsOppNote()


    @isTest static void testCreateNewRequestAndTaskUnderNeedsDocumentationStatus() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId(); // Create person account
        a.FirstName = 'John';
        a.LastName = 'Smith';
        a.External_Id__c = '523891p3';
        insert a;

        Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
        o.AccountId = a.id;
        o.CloseDate = Date.today();
        o.StageName = 'In Process';
        o.Tracker_External_Id__c = '3289-4932-0';
        insert o;

        Provider__c p = new Provider__c();
        p.Name = 'Marcus Welby';
        p.NPI__c = '1234567890';
        p.Address__c = '123 Main St';
        p.City__c = 'Palookaville';
        p.State__c = 'GA';
        p.Zip__c = '12345';
        insert p;

        Provider_Patient_Junction__c ppj =  new Provider_Patient_Junction__c();
        ppj.Provider__c = p.Id;
        ppj.Patient__c = a.Id;
        insert ppj;

        List<Request__c> requestList = [SELECT Id FROM Request__c];
        List<Task> taskList = [SELECT Id FROM Task];

        System.assertEquals(0, requestList.size());
        System.assertEquals(0, taskList.size());

        o.Status__c = 'Documentation Needed';

        TestDataFactory.createAllCustomSettings();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        update o;
        Test.stopTest();

        requestList = [SELECT Id, Opportunity__c, Completed__c From Request__c];
        taskList = [SELECT Id, Patient__c, Request__c, WhatId from Task WHERE Successful_Send_To_Hub__c = true];

        System.assertEquals(1, requestList.size());
        System.assertEquals(o.Id, requestList[0].Opportunity__c);
        System.assertEquals(false, requestList[0].Completed__c);
        System.assertEquals(1, taskList.size());
        System.assertEquals(a.Id, taskList[0].Patient__c);
        System.assertEquals(requestList[0].Id, taskList[0].Request__c);
    }

    @isTest static void testCreateNewRequestAndTaskUnderNeedsDocumentationStatus_WrongStatus() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());

        Account a = new Account();
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId(); // Create person account
        a.FirstName = 'John';
        a.LastName = 'Smith';
        insert a;

        Opportunity o = new Opportunity();
        o.Name = 'Test Opp';
        o.AccountId = a.id;
        o.CloseDate = Date.today();
        o.StageName = 'In Process';
        insert o;

        Provider__c p = new Provider__c();
        p.Name = 'Marcus Welby';
        p.NPI__c = '1234567890';
        p.Address__c = '123 Main St';
        p.City__c = 'Palookaville';
        p.State__c = 'GA';
        p.Zip__c = '12345';
        insert p;

        Provider_Patient_Junction__c ppj =  new Provider_Patient_Junction__c();
        ppj.Provider__c = p.Id;
        ppj.Patient__c = a.Id;
        insert ppj;

        List<Request__c> requestList = [SELECT Id FROM Request__c];
        List<Task> taskList = [SELECT Id FROM Task];

        System.assertEquals(0, requestList.size());
        System.assertEquals(0, taskList.size());

        o.StageName = 'Re-work';

        update o;

        requestList = [SELECT Id, Opportunity__c, Completed__c From Request__c];
        taskList = [SELECT Id, Patient__c, Request__c, WhatId from Task];

        System.assertEquals(0, requestList.size());
        System.assertEquals(0, taskList.size());
    }



    @isTest static void testClosedLostOpp() {
        TestDataFactory tdf = new TestDataFactory();
        tdf.createPatients();
        tdf.createOpportunities();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());


        Opportunity o = [SELECT Id, AccountId, StageName FROM Opportunity LIMIT 1];
        System.debug(o);
    //  o.StageName = 'In Process';
    //  UPDATE o;

        Task theTask = new Task(
            Subject = 'Whats up',
            Description = 'Description',
            WhatId = o.AccountId,
            Opportunity__c = o.Id,
            Status = 'Open'
        );
        INSERT theTask;
        System.debug(theTask);


//      Test.startTest();
        o.StageName = 'Closed Lost';
        UPDATE o;
        System.debug(o);
        System.debug([SELECT Id, AccountId, StageName FROM Opportunity WHERE Id =: o.Id LIMIT 1]);
//      Test.stopTest();

        //Check Tracker Note

        //Check SO

        //Check Tasks
        List<Task> theTasks = new List<Task>([SELECT Id, WhatId, Status, Opportunity__c FROM Task WHERE Opportunity__c =: o.Id]);
        System.debug(theTasks);
        for (Task t : theTasks) {
            System.assertEquals('Closed', t.Status);
        }
        System.debug(theTasks);
    }


    @isTest static void testBatchOpportunityInsert(){
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        List<Opportunity> opps = new List<Opportunity>();
        Integer i = 0;
        //    for (Integer i = 0; i < 300; i++){
        Opportunity o = new Opportunity(
                Dexcom_Opp_Id__c = String.valueOf(i),
                Name = 'Test ' + String.valueOf(i),
                StageName = 'New Opportunity',
                CloseDate = System.today().addDays(20)
        );
        opps.add(o);
        //    }
        INSERT opps;


        System.assertEquals(1, opps.size());

    } //@isTest static void testBatchOpportunityInsert()

}