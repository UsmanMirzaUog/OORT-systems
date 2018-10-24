/**
 * Created by isaac on 10/11/17.
 * addInsurancePayorController: 100%
 */

@isTest
public with sharing class addInsurancePayorController_TEST {
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

        Id pricebookId = Test.getStandardPricebookId();

        List<Product2> productList = new List<Product2>();
        productList.add(new Product2(Name = 'Product1', ProductCode = '1', isActive = true));
        productList.add(new Product2(Name = 'Product2', ProductCode = '2', isActive = true));
        productList.add(new Product2(Name = 'Product3', ProductCode = '3', isActive = true));

        INSERT productList;

        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(0).Id, UnitPrice = 100.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(1).Id, UnitPrice = 150.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(2).Id, UnitPrice = 250.00, IsActive = true));

        INSERT pbEntry;

        List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(0).Id, Quantity = 1, PricebookEntryId = pbEntry.get(0).Id, TotalPrice = pbEntry.get(0).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(0).Id, Quantity = 2, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(1).Id, Quantity = 1, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(2).Id, Quantity = 1, PricebookEntryId = pbEntry.get(2).Id, TotalPrice = pbEntry.get(2).UnitPrice));

        INSERT lineItemList;

        List<Insurance_Payor__c> payorList = new List<Insurance_Payor__c>();
        payorList.add(new Insurance_Payor__c(Name = 'Payor 1'));
        payorList.add(new Insurance_Payor__c(Name = 'Payor 2'));
        payorList.add(new Insurance_Payor__c(Name = 'Payor 3'));
        INSERT payorList;

        List<Insurance_Patient_Junction__c> ipjList = new List<Insurance_Patient_Junction__c>();
        ipjList.add(new Insurance_Patient_Junction__c(Name = 'Insurance Patient 1', Account__c = patient.Id, Insurance__c = payorList.get(0).Id));
        ipjList.add(new Insurance_Patient_Junction__c(Name = 'Insurance Patient 2', Account__c = patient.Id, Insurance__c = payorList.get(1).Id));
        ipjList.add(new Insurance_Patient_Junction__c(Name = 'Insurance Patient 3', Account__c = patient.Id, Insurance__c = payorList.get(2).Id));
        INSERT ipjList;
    }

    @isTest
    static void testInsuranceModal(){
        Opportunity theOpportunity = [SELECT Id, Name, AccountId FROM Opportunity LIMIT 1];
        Insurance_Payor__c payor = [SELECT Id from Insurance_Payor__c LIMIT 1];

        Test.setCurrentPage(Page.Console_OpportunityDetail);
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpportunity);
        extConsole_TopPanel_Insurance insurancePanel = new extConsole_TopPanel_Insurance(sc);
        PageReference pr = insurancePanel.redirect();
        System.assert(pr != NULL);
        
        addInsurancePayorController ipc = new addInsurancePayorController();
        ipc.patient = [SELECT Id, Name FROM Account LIMIT 1];
        ipc.oppty = theOpportunity;
        addInsurancePayorController.getData();
        Boolean result1 = addInsurancePayorController.savePayor(payor.Id, 'Primary', ipc.patient.Id, String.valueOf(System.today()), '');
        System.assertEquals(true, result1);
        Boolean result2 = addInsurancePayorController.savePayor(payor.Id, 'Secondary', ipc.patient.Id, String.valueOf(System.today()), String.valueOf(System.today().addYears(2)));
        System.assertEquals(true, result2);
        Boolean result3 = addInsurancePayorController.savePayor(payor.Id, 'Secondary', ipc.patient.Id, null, '');
        System.assertEquals(false, result3);

        List<Insurance_Patient_Junction__c> ipjList = [SELECT Id from Insurance_Patient_Junction__c];
        System.assertEquals(5, ipjList.size());
        System.assertEquals(null, [SELECT End_Date__c FROM Insurance_Patient_Junction__c WHERE Insurance__c =: payor.Id AND Policy_Level__c = 'Primary' LIMIT 1].End_Date__c);
        System.assertEquals(System.today().addYears(2), [SELECT End_Date__c FROM Insurance_Patient_Junction__c WHERE Insurance__c =: payor.Id AND Policy_Level__c = 'Secondary' LIMIT 1].End_Date__c);
    }
}