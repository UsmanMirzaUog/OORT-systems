/**
 * Created by isaac on 5/9/18.
 */

global class BatchCopyDexcomISRNotes implements Database.Batchable<SObject> {
    String query;
    private static Id OppRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Opp Note').getRecordTypeId();

    global BatchCopyDexcomISRNotes() {
        query = 'SELECT Id, Name, External_Id__c, CloseDate, Last_Note_Created_Date__c, Patient_DOB__c, ' +
                'Dexcom_Doctor__c, Dexcom_Opp_Id__c, Dexcom_Opportunity_Notes__c, Dexcom_Opportunity_Type__c, ' +
                'Dexcom_Patient_Address__c, Dexcom_Patient_Address_Formula__c, Dexcom_Patient_Email__c, ' +
                'Dexcom_Patient_Home_Phone__c, Dexcom_Patient_Home_Phone_Formula__c, Dexcom_Patient_Mobile_Phone__c, ' +
                'Dexcom_Patient_Ship_To_Address__c, Dexcom_Primary__c, Dexcom_Stage__c, Dexcom_Status__c, ' +
                'Assigned_To__c, Doc_1_Status__c, Doc_2_Status__c, Doc_3_Status__c, Doc_4_Status__c, Doc_5_Status__c, ' +
                'Doc_6_Status__c, Doc_1_Type__c, Doc_2_Type__c, Doc_3_Type__c, Doc_4_Type__c, Doc_5_Type__c, ' +
                'Doc_6_Type__c, Solara_User__c, StageName, Status__c ' +
                'FROM Opportunity ' +
                'WHERE Dexcom_Opp_Id__c != null ' +
                'AND External_Id__c = null';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> batch) {
        List<Task> DexcomNotes = new List<Task>();

        //for each opp
        for (Opportunity o : batch) {
            //Create the JSON string of all the fields
            String ISRNote = JSON.serialize(o);
            ISRNote = ISRNote.replaceAll(',', '\n');
            ISRNote = ISRNote.replaceAll('":"', ': ');
            ISRNote = ISRNote.replaceAll('"', '');
            ISRNote = ISRNote.substringBetween('}', '}');

            //create an opp note task with Description or Note field (Long Text) that holds JSON string
            Task oppNote = new Task(
                    RecordTypeId = OppRecordType
                    , Description = ISRNote
                    , WhatId = o.id
                    , Status = 'Completed'
                    , Subject = 'Opportunity Note'
            );

            //Add it to the list
            DexcomNotes.add(oppNote);
        }

        //Insert the list
        if (DexcomNotes.size() > 0) {
            insert DexcomNotes;
        }
    }

    global void finish(Database.BatchableContext BC) {

    }
}