/**
 * Created by isaac on 10/12/17.
 */

@isTest
public with sharing class addProductModalController_TEST {
    @testSetup
    static void setup(){
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        Account patient = new Account(FirstName = 'John', LastName = 'Smith', RecordTypeId = recordTypeId);
        INSERT patient;

        List<Opportunity> opportunityList = new List<Opportunity>();
        opportunityList.add(new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New'));
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
    static void testAddProduct(){
        Opportunity theOpportunity = [SELECT Id, Name, AccountId FROM Opportunity LIMIT 1];
//        Map<Id, Product2> productMap = [SELECT Id, Name from Product2];

//        Test.setCurrentPage(Page.Console_OpportunityDetail);
//        ApexPages.StandardController sc = new ApexPages.StandardController(theOpportunity);
//        extConsole_TopPanel_Prod insurancePanel = new extConsole_TopPanel_Insurance(sc);
//        PageReference pr = insurancePanel.redirect();
//        System.assert(pr != NULL);

        addProductModalController con = new addProductModalController();
        con.patient = [SELECT Id, Name FROM Account LIMIT 1];
        con.oppty = theOpportunity;

        List<addProductModalController.productWrapper> productList = addProductModalController.getProducts();
        System.debug(productList);
        System.assertEquals(3, productList.size());

        Map<Id, addProductModalController.productWrapper> productsToAddMap = new Map<Id, addProductModalController.productWrapper>();
        for(addProductModalController.productWrapper p : productList){
            productsToAddMap.put(p.Id, p);
        }
        System.debug(productsToAddMap);

        addProductModalController.doSave(productsToAddMap, con.oppty.Id, Test.getStandardPricebookId());

        List<OpportunityLineItem> opportunityLineItemsList = [SELECT Id, Name FROM OpportunityLineItem];

        System.assertEquals(5, opportunityLineItemsList.size()); //There were two items in the opportunity, we added 3. Now there are 5.
        System.debug(opportunityLineItemsList);




    }
}