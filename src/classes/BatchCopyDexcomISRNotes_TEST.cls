/**
 * Created by isaac on 5/9/18.
 */
@isTest
public class BatchCopyDexcomISRNotes_TEST {
    //public static Id OppNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Opp Note').getRecordTypeId();

    //@testSetup
    //static void setup(){
    //    List<Account> accounts = new List<Account>();
    //    List<Opportunity> opportunities = new List<Opportunity>();

    //    for (Integer i=0; i < 200 ; i++) {
    //        accounts.add(new Account(
    //                Name = 'Test Account ' + i
    //                , BillingStreet = i + ' Main St'
    //                , BillingCity = 'Portland'
    //                , BillingState = 'OR'
    //                , BillingPostalCode = '91493'
    //                , ShippingStreet = i + ' Main St'
    //                , ShippingCity = 'Portland'
    //                , ShippingState = 'OR'
    //                , ShippingPostalCode = '91493'
    //        ));
    //    }

    //    insert accounts;

    //    for (Integer i=0; i < 200 ; i++) {
    //        opportunities.add(new Opportunity(
    //                Name = 'Test Opportunity ' + i
    //                , AccountId = accounts[i].id
    //                , StageName = 'In Process'
    //                , CloseDate = Date.today()
    //                , Last_Note_Created_Date__c = Date.today().addDays(-1)
    //                , Patient_DOB__c = Date.today().addDays(-(i+7200))
    //                , Dexcom_Doctor__c = 'Dr. Strange'
    //                , Dexcom_Opp_Id__c = String.valueOf(i + 1)
    //                , Dexcom_Opportunity_Notes__c = 'Dexcom Opportunity Note'
    //                , Dexcom_Opportunity_Type__c = 'Physician Referral'
    //                , Dexcom_Patient_Address__c = '123 Main St,San Diego,CA,92123'
    //                , Dexcom_Patient_Email__c = 'opp' + i +'@fakemail.com'
    //                , Dexcom_Patient_Home_Phone__c = '5555555555'
    //                , Dexcom_Patient_Mobile_Phone__c = '5555554321'
    //                , Dexcom_Patient_Ship_To_Address__c = '345 Blenheim Rd,Bellevue,WA,81294'
    //                , Dexcom_Primary__c = 'Payor 1 - ID:[11111111]'
    //                , Dexcom_Stage__c = '2. Verification'
    //                , Dexcom_Status__c = '3.1 Pending Distributor Referral Confirmation'
    //                , Assigned_To__c = 'Miguel Guillen'
    //                , Doc_1_Status__c = 'AOB'
    //                , Doc_2_Status__c = 'CMN'
    //                , Doc_3_Status__c = 'Received'
    //                , Doc_4_Status__c = 'Requested'
    //                , Doc_5_Status__c = 'Sumitted'
    //                , Doc_6_Status__c = 'New'
    //                , Doc_1_Type__c = 'A'
    //                , Doc_2_Type__c = 'B'
    //                , Doc_3_Type__c = 'C'
    //                , Doc_4_Type__c = 'D'
    //                , Doc_5_Type__c = 'E'
    //                , Doc_6_Type__c = 'F'
    //                , Solara_User__c = 'Miguel Guillen'
    //                , Status__c = 'Test Order'
    //        ));
    //    }

    //    insert opportunities;
    //}

    //@isTest
    //static void testBatchCopyDexcomISRNotes() {
    //    List<Opportunity> opps = [Select Id, Name from Opportunity];
    //    System.assertEquals(200, opps.size());

    //    List<Task> oppNotesBefore = [SELECT Id, Subject, CreatedDate, Call_Outcome__c,
    //            Call_Disposition__c, Owner.Name, Description
    //            FROM Task WHERE RecordTypeId =: OppNoteRecordTypeId];

    //    System.assertEquals(0, oppNotesBefore.size());

    //    Test.startTest();
    //    BatchCopyDexcomISRNotes b = new BatchCopyDexcomISRNotes();
    //    Database.executeBatch(b);
    //    Test.stopTest();

    //    List<Task> oppNotes = [SELECT Id, Subject, CreatedDate, Call_Outcome__c,
    //            Call_Disposition__c, Owner.Name, Description
    //            FROM Task WHERE RecordTypeId =: OppNoteRecordTypeId];

    //    System.assertEquals(200, oppNotes.size());
    //    System.assert(oppNotes[0].Description.contains('Doc_3_Status__c: Received'));
    //}
}