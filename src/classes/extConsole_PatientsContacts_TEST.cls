/**
 * Created by danielpulache on 10/24/17.
 */
@isTest
public class extConsole_PatientsContacts_TEST {
    private static extConsole_TopPanel_PatientsContacts ext;
    @testSetup static void setUpTestData() {
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
        opportunityList.add(new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New', AccountId = patient.Id));
        opportunityList.add(new Opportunity(Name = 'Open Opportunity', CloseDate = Date.today().addDays(7), StageName = 'Open', AccountId = patient.Id));
        opportunityList.add(new Opportunity(Name = 'Closed Opportunity', CloseDate = Date.today(), StageName = 'Closed Won', AccountId = patient.Id));

        INSERT opportunityList;
    }
    @isTest static void instantiateController() {
        Opportunity theOpp = [SELECT Id,AccountId FROM Opportunity WHERE StageName = 'Closed Won'];
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new extConsole_TopPanel_PatientsContacts(sc);
    }
    @isTest static void doSave() {
        Opportunity theOpp = [SELECT Id,AccountId FROM Opportunity WHERE StageName = 'Closed Won'];
        ApexPages.StandardController sc = new ApexPages.StandardController(theOpp);
        ext = new extConsole_TopPanel_PatientsContacts(sc);
        ext.save();
    }
}