/**
 * Created by krizia on 8/1/18.
 *
 * trgInsurancePatientJunction: 100%
 * trgInsurancePatientJunctionHandler: 97%
 *
 */
@isTest
private class trgInsurancePatientJunction_TEST {

    @testSetup
    static void setup(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        Account patient = new Account(FirstName = 'John', LastName = 'Smith', RecordTypeId = recordTypeId);
        INSERT patient;

        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList.add(new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New'));
        opportunityList.add(new Opportunity(Name = 'Open Opportunity', CloseDate = Date.today().addDays(7), StageName = 'Open'));
        opportunityList.add(new Opportunity(Name = 'Closed Opportunity', CloseDate = Date.today(), StageName = 'Closed Won'));

        INSERT opportunityList;

        List<Insurance_Payor__c> payorList = new List<Insurance_Payor__c>();
        payorList.add(new Insurance_Payor__c(Name = 'Payor 1'));
        payorList.add(new Insurance_Payor__c(Name = 'Payor 2'));
        payorList.add(new Insurance_Payor__c(Name = 'Payor 3'));
        INSERT payorList;
    }

    @isTest static void succeed(){
        Account thePatient = [SELECT Id FROM Account LIMIT 1];
        List<Insurance_Payor__c> thePayorList = [SELECT Id FROM Insurance_Payor__c];

        List<Insurance_Patient_Junction__c> ipjList = new List<Insurance_Patient_Junction__c>();
        ipjList.add(new Insurance_Patient_Junction__c(Name = 'Insurance Patient 1', Account__c = thePatient.Id, Insurance__c = thePayorList.get(0).Id, Policy_Level__c = 'Primary'));
        ipjList.add(new Insurance_Patient_Junction__c(Name = 'Insurance Patient 2', Account__c = thePatient.Id, Insurance__c = thePayorList.get(1).Id, Policy_Level__c = 'Secondary', Start_Date__c = System.today().addDays(-14)));
        Test.startTest();
        INSERT ipjList;
        Test.stopTest();
        System.debug('now insert the one to force an end date');
        INSERT new Insurance_Patient_Junction__c(Name = 'Insurance Patient 3', Account__c = thePatient.Id, Insurance__c = thePayorList.get(2).Id, Policy_Level__c = 'Secondary', Start_Date__c = System.today());


        List<Insurance_Patient_Junction__c> ipjResultList = [SELECT Id FROM Insurance_Patient_Junction__c];
        System.assertEquals(3, ipjResultList.size());
        Insurance_Patient_Junction__c endDateIPJ = [SELECT End_Date__c FROM Insurance_Patient_Junction__c WHERE Name = 'Insurance Patient 2' LIMIT 1];
        System.assertEquals(System.today().addDays(-1), endDateIPJ.End_Date__c);
    }


}