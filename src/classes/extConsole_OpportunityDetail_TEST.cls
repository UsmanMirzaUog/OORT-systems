/**
 * Created by isaac on 10/10/17.
 */

@isTest
public class extConsole_OpportunityDetail_TEST {
    @testSetup
    static void setup(){

        TestDataFactory.create_Oppties_with_Patient();
        TestDataFactory.create_OpptyLineItems();
//        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
//        Account patient = new Account(FirstName = 'John', LastName = 'Smith', RecordTypeId = recordTypeId);
//        INSERT patient;
//
//        List<Opportunity> opportunityList = new List<Opportunity>();
//        opportunityList.add(new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New'));
//        opportunityList.add(new Opportunity(Name = 'Open Opportunity', CloseDate = Date.today().addDays(7), StageName = 'Open'));
//        opportunityList.add(new Opportunity(Name = 'Closed Opportunity', CloseDate = Date.today(), StageName = 'Closed Won'));
//
//        INSERT opportunityList;
//
//        Id pricebookId = Test.getStandardPricebookId();
//
//        List<Product2> productList = new List<Product2>();
//        productList.add(new Product2(Name = 'Product1', ProductCode = '1', isActive = true));
//        productList.add(new Product2(Name = 'Product2', ProductCode = '2', isActive = true));
//        productList.add(new Product2(Name = 'Product3', ProductCode = '3', isActive = true));
//
//        INSERT productList;
//
//        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
//        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(0).Id, UnitPrice = 100.00, IsActive = true));
//        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(1).Id, UnitPrice = 150.00, IsActive = true));
//        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(2).Id, UnitPrice = 250.00, IsActive = true));
//
//        INSERT pbEntry;
//
//        List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
//        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(0).Id, Quantity = 1, PricebookEntryId = pbEntry.get(0).Id, TotalPrice = pbEntry.get(0).UnitPrice));
//        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(0).Id, Quantity = 2, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));
//        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(1).Id, Quantity = 1, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));
//        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(2).Id, Quantity = 1, PricebookEntryId = pbEntry.get(2).Id, TotalPrice = pbEntry.get(2).UnitPrice));
//
//        INSERT lineItemList;

    }

    @isTest
    static void testOpportunityDetails(){
        
        Account patient = [SELECT Id, Name FROM Account LIMIT 1];
        List<Opportunity> newOpportunity = [SELECT Id, AccountId, Name FROM Opportunity];
        
           
        newOpportunity[0].Status__c = 'Documentation Needed';
        UPDATE newOpportunity[0];
        
        Date followUpDate = system.Today().addDays(Integer.valueOf(Label.FollowUp_Email));
        Id RecordTypeIdContact = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Vendor').getRecordTypeId();
        
        list<contact> contList = new list<contact>();
        
        contact cont = new Contact( title = 'CEO', Salutation = 'Mr.', Lastname='Contact 1', Email='test1@test.com', recordtypeid=RecordTypeIdContact, Follow_Up_30_Day__c = followUpDate, Dinner_Meeting_90_Day__c = system.Today() );
        contList.add(cont);
        
        contact cont2 = new Contact( title = 'CEO', Salutation = 'Mr.', Lastname='Contact 2',  Email='test2@test.com', recordtypeid=RecordTypeIdContact, Follow_Up_30_Day__c = system.Today(), Dinner_Meeting_90_Day__c = followUpDate );
        contList.add(cont2);
        
        insert contList;

        Test.setCurrentPage(Page.Console_OpportunityDetail);
        ApexPages.StandardController sc = new ApexPages.StandardController(newOpportunity.get(0));
        extConsole_OpportunityDetail ext = new extConsole_OpportunityDetail(sc);

        System.debug('opp amount: ' + ext.opportunityAmount);
        System.debug('prod list: ' + ext.opportunityProductList);
        System.assertEquals(400, ext.opportunityAmount); //Total amount should be 100
        System.assertEquals(2, ext.opportunityProductList.size()); //Should be 2 item in list

        for (OpportunityLineItem o : ext.opportunityProductList){
            if(o.Quantity == 1){
                ext.toUnselect = o.Id; //Set toUnselect to OpportunityProduct Id; tells controller which item to remove
                break;
            }
        }
        ext.removeFromShoppingCart(); //Remove Opportunity Product
        
        List<String> theOrderedDateTimes = new List<String>();
        List<Datetime> theDatetimes = new List<Datetime>();
        theDatetimes.add(Datetime.now());
        theOrderedDateTimes.add('08/30/2018 3:27 pm');
        
        ext.reverseOrderOfDatetimes(theDatetimes);
        
        ext.reverseOrderOfDatetimes(theOrderedDateTimes);
        
        ext.save();
        
        ext.saveDocSetRequest();
        
        ext.createDocSetRequest();
        
        extConsole_OpportunityDetail.docSetRequest();
        
        extConsole_OpportunityDetail.docSetCreateRequest(string.valueOf(newOpportunity[0].Id), 'qwertyuioplkjhgfd', 'Test');

        System.debug('opp amount after: ' + ext.opportunityAmount);
        System.debug('prod list after: ' + ext.opportunityProductList);
        System.assertEquals(1, ext.opportunityProductList.size()); //Should be 1 item in shopping cart after removing from cart
        System.assertEquals(300, ext.opportunityAmount); //
        
        
        
        Test.startTest();
        
        
        FollowUpSchedule sh1 = new FollowUpSchedule();
        String sch = '0 0 1 * * ?'; system.schedule('Test Follow Up Check', sch, sh1); 
        
        //FollowUpBatch folloUpBt = new FollowUpBatch();
        //database.executeBatch(folloUpBt);
        Test.stopTest();
        
        
    }

}