/**
 * Created by isaac on 4/25/18.
 */

public with sharing class ADMPatientModalDetailModalController {
    public static String accountId { get; set; }
//    public static Boolean notesRender { get; set; }
//    public String patientId { get; set; }
    public static Id theAccountId { get; set; }
    public static List<Task> theTasks { get; set; }
    public static List<TaskWithTime> thePatientTaskList { get; set; }

    public ADMPatientModalDetailModalController(){
      //  notesRender = false;
    } // Constructor


    @RemoteAction
    public static Account getPatient(String patientId) {
        List<Account> accounts = [SELECT Id, Name, FirstName, MiddleName, LastName, Suffix, Date_of_Birth__c, PersonBirthdate,
                PersonHomePhone, PersonMobilePhone, PersonEmail,
                BillingStreet, BillingCity, BillingState, BillingPostalCode,
                ShippingStreet, ShippingCity, ShippingState, ShippingPostalCode
        // Also get Primary Insurance, Secondary insurance
        from Account WHERE Id = :patientId LIMIT 1];
        if(accounts.size() < 1) return null;

   //     notesRender = true;
        accountId = accounts[0].Id;
        System.debug(accounts[0]);
        return accounts[0];
    }

    @RemoteAction
    public static Insurance_Patient_Junction__c getPrimaryInsurance(String patientId) {
        List<Insurance_Patient_Junction__c> primaryPolicyList = new List<Insurance_Patient_Junction__c>();
        primaryPolicyList = [SELECT Insurance__r.Name, Policy_Level__c
        FROM Insurance_Patient_Junction__c
        WHERE Account__c = :patientId AND Policy_Level__c = 'Primary'
        LIMIT 1];

        if (!primaryPolicyList.isEmpty()) return primaryPolicyList[0];

        return null;
    }

    @RemoteAction
    public static Insurance_Patient_Junction__c getSecondaryInsurance(String patientId) {
        List<Insurance_Patient_Junction__c> secondaryPolicyList;
        secondaryPolicyList = [SELECT Insurance__r.Name, Policy_Level__c
        FROM Insurance_Patient_Junction__c
        WHERE Account__c = :patientId AND Policy_Level__c = 'Secondary'
        LIMIT 1];

        if(!secondaryPolicyList.isEmpty()) return secondaryPolicyList[0];

        return null;
    }





    @RemoteAction
    public static List<TaskWithTime> getNotesStream(String accId){ //String patientId
        //Get the records for display
        Id accountId = (Id)accId;
        System.debug(accountId);
        theTasks = new List<Task>();
        theTasks = [SELECT Id, Subject, Description, CreatedBy.Name, CreatedDate, WhatId, RecordType.Name
            FROM Task
            WHERE WhatId =: accountId OR Patient__c =: accountId
            ORDER BY CreatedDate DESC];

        thePatientTaskList = new List<TaskWithTime>();
        for (Task t : theTasks) {
            thePatientTaskList.add(new TaskWithTime(t));
        }
        System.debug(thePatientTaskList);
        return(thePatientTaskList);
    } //public static List<TaskWithTime> getNotesStream(Id accId)



    public class TaskWithTime{
        public Task theT { get; set; }
        public String CreatedDateString { get; set; }
        public String subject { get; set; }
        public String description { get; set; }
        public String type { get; set; }
        public Id taskId { get; set; }

        public TaskWithTime(Task t) {
            this.theT = t;
            this.subject = t.Subject;
            this.description = t.Description;
            this.type = t.RecordType.Name;
            this.taskId = t.Id;
            this.CreatedDateString = String.valueOf(t.CreatedDate.format('MM/dd/yyyy HH:mm a'));
        } //public TaskWithTime(Task t)

    }//public class TaskWithTime

}