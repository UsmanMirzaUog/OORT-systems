/**
 * Created by isaac on 10/13/17.
 */

@isTest
public class patientModalController_TEST {
    @testSetup
    static void setup(){
        Id recTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();

        Account patient = new Account(FirstName = 'John', LastName = 'Smith', RecordTypeId = recTypeId);
        INSERT patient;

        Account patientContact = new Account(LastName = 'Jones', FirstName = 'Martha', Phone = '5555551234', Primary_Contact__c = true, RecordTypeId = recTypeId);
        INSERT patientContact;

        patientContact = [SELECT Id, PersonContactId FROM Account WHERE Id = :patientContact.Id];

        update new Contact(Id = patientContact.PersonContactId, Primary_Contact__c = true, Responsible_Party__c = true);

        Account p = [SELECT PersonContactId from Account where Id = :patientContact.Id LIMIT 1];
        insert new AccountContactRelation(ContactId = p.PersonContactId, AccountId = patient.Id);

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

    }

    @isTest
    static void testGetPrimaryContact(){
        Account thePatient = [SELECT Id, LastName, IsPersonAccount FROM Account WHERE LastName = 'Smith'];
        System.debug('*** patient = ' + thePatient);

        Contact thePatientContact = [SELECT Id, LastName from Contact WHERE LastName = 'Jones'];
        System.debug('*** Contact = ' + thePatientContact);

        AccountContactRelation theAcr = [SELECT Id, Account.LastName, Contact.LastName from AccountContactRelation];
        System.debug('*** acr = ' + theAcr);

        List<Address_Data__c> addys = [SELECT Id, Street__c, Account__c FROM Address_Data__c];
        System.debug('*** addys = ' + addys);

        System.assertEquals(theAcr.AccountId, thePatient.Id);
        System.assertEquals(theAcr.ContactId, thePatientContact.Id);

        patientModalController con = new patientModalController();
        con.patient = thePatient;

        List<Address_Data__c> theAddressList = con.getAddresses();


        System.debug('*** addyList = ' + theAddressList);
        System.assertEquals(thePatientContact.Id, con.primaryContact.Id);
    }

    @isTest
    static void testGetResponsibleParty(){
        Account thePatient = [SELECT Id, LastName, IsPersonAccount FROM Account WHERE LastName = 'Smith'];
        System.debug('*** patient = ' + thePatient);

        Contact thePatientContact = [SELECT Id, LastName from Contact WHERE LastName = 'Jones'];
        System.debug('*** Contact = ' + thePatientContact);

        AccountContactRelation theAcr = [SELECT Id, Account.LastName, Contact.LastName from AccountContactRelation];
        System.debug('*** acr = ' + theAcr);

        List<Address_Data__c> addys = [SELECT Id, Street__c, Account__c FROM Address_Data__c];
        System.debug('*** addys = ' + addys);

        patientModalController con = new patientModalController();
        con.patient = thePatient;

        System.assertEquals(thePatientContact.Id, con.responsibleParty.Id);

    }

    @isTest
    static void testGetAddress(){
        Account thePatient = [SELECT Id, LastName, IsPersonAccount FROM Account WHERE LastName = 'Smith'];
        System.debug('*** patient = ' + thePatient);

        Contact thePatientContact = [SELECT Id, LastName from Contact WHERE LastName = 'Jones'];
        System.debug('*** Contact = ' + thePatientContact);

        AccountContactRelation theAcr = [SELECT Id, Account.LastName, Contact.LastName from AccountContactRelation];
        System.debug('*** acr = ' + theAcr);

        patientModalController con = new patientModalController();
        con.patient = thePatient;

        List<Address_Data__c> theAddressList = con.getAddresses();
        Address_Data__c primaryBilling = con.getPrimaryBillingAddress();
        Address_Data__c primaryShipping = con.getPrimaryShippingAddress();

        System.assertEquals(0, theAddressList.size()); //No additional addresses
        System.assertEquals(null, primaryBilling.Street__c); // Primary Billing empty
        System.assertEquals(null, primaryShipping.Street__c); // Primary Shipping empty
        System.debug('theAddressList: ' + theAddressList);
        //Add address
        con.addAddressRow();
        Address_Data__c newAddress = new Address_Data__c(Account__c = thePatient.Id, Street__c = '123 Main St', City__c = 'Springfield', State_Province__c = 'KY', Zip_Postal_Code__c = '12345');
        INSERT newAddress;

//        Address_Patient_Junction__c apj = new Address_Patient_Junction__c(Address_Data__c = newAddress.Id, Patient__c = thePatient.Id);
//        INSERT apj;

        List<Address_Data__c> addylist = con.addresses;
        System.debug('addylist: ' + addylist);
        System.assertEquals(2, addylist.size()); //Address exists
        System.assertEquals('123 Main St', addylist[0].Street__c); //Address exists
    }

    @isTest
    static void testDoSave() {
        Account thePatient = [SELECT Id, LastName, IsPersonAccount, Primary_Contact__c FROM Account WHERE LastName = 'Smith'];
        System.debug('*** patient = ' + thePatient);

        AccountContactRelation theAcr = [SELECT Id, Account.LastName, Contact.LastName from AccountContactRelation];
        System.debug('*** acr = ' + theAcr);
        delete theAcr;
//
//        Contact thePatientContact = [SELECT Id, LastName, Primary_Contact__c from Contact WHERE LastName = 'Jones'];
//        System.debug('*** Contact = ' + thePatientContact);
//        delete thePatientContact;

        patientModalController con = new patientModalController();
        con.patient = thePatient;
        con.patient.Primary_Contact__c = false;
        con.addAddressRow();

        con.primaryContact = new Contact();
        con.primaryContact.LastName = 'Harkness';
        con.primaryContact.Primary_Contact__c = false;
        con.primaryContact.FirstName = 'Jack';
        con.doSave();

        System.debug(con.primaryContact);

        Contact c = [SELECT LastName FROM Contact WHERE LastName = 'Harkness'];

        System.assertEquals('Harkness', c.LastName);
    }

    @isTest
    static void testDoSave2() {
        Account thePatient = [SELECT Id, LastName, IsPersonAccount, Primary_Contact__c FROM Account WHERE LastName = 'Smith'];
        System.debug('*** patient = ' + thePatient);

        AccountContactRelation theAcr = [SELECT Id, Account.LastName, Contact.LastName from AccountContactRelation];
        System.debug('*** acr = ' + theAcr);
        delete theAcr;
//
//        Contact thePatientContact = [SELECT Id, LastName, Primary_Contact__c from Contact WHERE LastName = 'Jones'];
//        System.debug('*** Contact = ' + thePatientContact);
//        delete thePatientContact;

        patientModalController con = new patientModalController();
        con.patient = thePatient;
        con.patient.Primary_Contact__c = false;

        con.primaryContact = new Contact();
        con.primaryContact.LastName = 'Harkness';
        con.primaryContact.Primary_Contact__c = false;
        con.primaryContact.Responsible_Party__c = false;
        con.primaryContact.FirstName = 'Jack';

        con.responsibleParty = new Contact();
        con.responsibleParty.LastName = 'Lightning';
        con.responsibleParty.FirstName = 'Greased';
        con.doSave();

        System.debug(con.responsibleParty);

        Contact c = [SELECT LastName FROM Contact WHERE LastName = 'Lightning'];

        System.assertEquals('Lightning', c.LastName);
    }

}