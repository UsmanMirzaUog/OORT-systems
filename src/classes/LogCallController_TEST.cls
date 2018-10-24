@isTest
public class LogCallController_TEST {
    private static LogCallController ext;
    
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
    @testSetup static void setup() {

        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        TestDataFactory.createAllCustomSettings();
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        Account patient = new Account(FirstName = 'John', LastName = 'Smith', RecordTypeId = recordTypeId, External_Id__c = '111');
        INSERT patient;

        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList.add(new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New', Tracker_External_Id__c = '111', AccountId = patient.Id));
        opportunityList.add(new Opportunity(Name = 'Open Opportunity', CloseDate = Date.today().addDays(7), StageName = 'Open', Tracker_External_Id__c = '111', AccountId = patient.Id));
        opportunityList.add(new Opportunity(Name = 'Closed Opportunity', CloseDate = Date.today(), StageName = 'Closed Won', Tracker_External_Id__c = '111', AccountId = patient.Id));
        INSERT opportunityList;
    }
    @isTest static void instantiateController() {
        Opportunity theOpp = [SELECT Id FROM Opportunity WHERE StageName = 'Closed Won'];
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new LogCallController(sc);
    }
    @isTest static void getCallOutcomes_TEST() {
        instantiateController();
        ext.getCallOutcomes();
        ext.foo();
    }

    @isTest static void validateErrors() {
        Opportunity theOpp = [SELECT Id,Call_Outcome__c, Call_Disposition__c FROM Opportunity WHERE StageName = 'Closed Won'];
        theOpp.Call_Disposition__c = null;
        theOpp.Call_Outcome__c = null;
        theOpp.Log_Type__c = null;
        update theOpp;
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new LogCallController(sc);
        ext.followUpDate = null;
        ext.save();
        //system.assert(); ERROR = Follow Up Date cannot be blank

        ext.followUpDate = system.today().addDays(-10);
        ext.save();
        //system.assert(); ERROR = Follow Up Date cannot be before

        ext.followUpDate = system.today().addDays(10);
        ext.save();
        //system.assert(); ERROR = Please enter a valid Call Outcome & Call Disposition

        Boolean fuDateCannotBeBlank = false;
        Boolean ValidCallDispoANDCallOutcome = false;
        Boolean fuDateCannotBeBefore = false;
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        for(Apexpages.Message msg:msgs) {
            if(msg.getDetail().contains('Follow Up Date cannot be blank')) fuDateCannotBeBlank = true;
            if(msg.getDetail().contains('Please enter a valid Call Outcome & Call Disposition')) ValidCallDispoANDCallOutcome = true;
            if(msg.getDetail().contains('Follow Up Date cannot be before')) fuDateCannotBeBefore = true;
        }
        system.assert(fuDateCannotBeBlank && ValidCallDispoANDCallOutcome && fuDateCannotBeBefore);
    }

    @isTest static void doSave_ToOpp() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity theOpp = [SELECT Id,Call_Outcome__c, Call_Disposition__c, Log_Type__c FROM Opportunity WHERE StageName = 'Closed Won'];
        theOpp.Call_Disposition__c = 'Voicemail Full';
        theOpp.Call_Outcome__c = 'Spoke to Customer';
        theOpp.Log_Type__c = 'Call Log';
        update theOpp;
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new LogCallController(sc);
        ext.notes = 'blah';
        ext.followUpDate = system.today().addDays(10);
        ext.save();

        system.assert([SELECT COUNT() FROM Task WHERE Opportunity__c =: theOpp.Id] > 0);
    }

    @isTest static void doSave_ToOpp_NotifyManufacturer() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity theOpp = [SELECT Id, Call_Outcome__c, Tracker_External_Id__c, Account.External_Id__c, Call_Disposition__c, Log_Type__c, Send_To_Manufacturer__c,  Manufacturer__c FROM Opportunity WHERE StageName = 'Closed Won'];
        theOpp.Call_Disposition__c = 'Voicemail Full';
        theOpp.Call_Outcome__c = 'Spoke to Customer';
        theOpp.Log_Type__c = 'Call Log';
        theOpp.Send_To_Manufacturer__c = true;
        theOpp.Manufacturer__c = 'test';
        update theOpp;
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new LogCallController(sc);
        ext.notes = 'blah';
        ext.followUpDate = system.today().addDays(10);
        ext.save();

        system.assert([SELECT COUNT() FROM Task WHERE Opportunity__c =: theOpp.Id] > 0);
    }

    @isTest static void doSave_PatientNote() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Opportunity theOpp = [SELECT Id,Call_Outcome__c, Tracker_External_Id__c, Account.External_Id__c, Call_Disposition__c, Log_Type__c FROM Opportunity WHERE StageName = 'Closed Won'];
        theOpp.Call_Disposition__c = 'Needs Follow Up';
        theOpp.Call_Outcome__c = 'Call Failed';
        theOpp.Log_Type__c = 'Patient Note';
        update theOpp;
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new LogCallController(sc);
        ext.notes = 'blah';
        ext.followUpDate = system.today().addDays(10);
        ext.save();

        system.assert([SELECT COUNT() FROM Task WHERE WhatId =: theOpp.AccountId] > 0);
    }
}