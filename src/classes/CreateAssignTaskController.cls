/**
 * Created by danielpulache on 11/8/17.
 */

public with sharing class CreateAssignTaskController {
//    public static Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
    public static Id ADMTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    public static Id SalesTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Opp Note').getRecordTypeId();
    public Task theTask {get;set;}
    public static Id accountId { get; set; }
    public String theProvider { get; set; }
    public List<SelectOption> theProviders { get; set; }
    public Boolean providerDisabled { get; set; }
    public String patientId { get; set; }

    public CreateAssignTaskController() {
        theTask = new Task(ActivityDate = system.today(), RecordTypeId = ADMTaskRecordTypeId);
        providerDisabled = true;
        theProviders = new List<SelectOption>();
    }



    public void getProviders() {
        System.debug('CreateAssignTaskController::: getProviders:: patientId: ' + patientId);
        providerDisabled = false;
        System.debug('CreateAssignTaskController::: getProviders:: providerDisabled: ' + providerDisabled);
        theProviders = new List<SelectOption>();
   //     Id patientId = ApexPages.currentPage().getParameters().get('accId');
        List<SelectOption> options = new List<SelectOption>();
        List<Provider_Patient_Junction__c> providers = new List<Provider_Patient_Junction__c>();
        providers = [SELECT Id, Patient__c, Provider__c, Provider__r.Name FROM Provider_Patient_Junction__c WHERE Patient__c =: patientId];
        System.debug(providers);
        for (Provider_Patient_Junction__c ppj : providers) {
            options.add(new SelectOption(ppj.Provider__c, ppj.Provider__r.Name));
        }
        System.debug(options);

        System.debug(theProviders);
        theProviders.add(new SelectOption('', '-- None --'));
        theProviders.addAll(options);
        System.debug(theProviders);
    } //public void getProviders()




    public class Data {
        public List<SelectOption> TaskPriorityList;
        public List<SelectOption> TaskSubjectList;
        public List<SelectOption> TaskUrgentReasonList;
        public List<SelectOption> TaskDocTypeList;
        public List<SelectOption> TaskProviderList;
    }
    @RemoteAction
    public static Data retrieveTaskInfo() {
        Data theData = new Data();
        theData.TaskSubjectList = getTaskSubjectOptions();
        theData.TaskPriorityList = getTaskPriorityOptions();
        theData.TaskUrgentReasonList = getTaskUrgentReasonOptions();
        theData.TaskDocTypeList = getDocTypeOptions();
        return theData;
    }
    public static List<SelectOption> getTaskPriorityOptions() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult =
                Request__c.Priority__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }
        return options;
    }
    public static List<SelectOption> getTaskSubjectOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for(Schema.PicklistEntry ple : Task.Subject.getDescribe().getPickListValues()) {
            options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        return options;
    }
    public static List<SelectOption> getTaskUrgentReasonOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('–', ''));
        for(Schema.PicklistEntry ple : Task.Urgent_Reason__c.getDescribe().getPickListValues()) {
            options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        return options;
    }
    public static List<SelectOption> getDocTypeOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('–', ''));
        for(Schema.PicklistEntry ple : Task.Document_Type__c.getDescribe().getPickListValues()) {
            options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        return options;
    }



    @RemoteAction
    public static String createTask(String patientId, String providerId, String ownerId, String taskPriority, String taskSubject, String dueDate, Boolean isUrgent, String urgentReason, String docType, String noteBody, String taskType) {
        Task theTaskToInsert = new Task();

        if (taskType == 'Sales') { // Sales Opportunity Note Task
            // Opportunity Note (Sales Console) task
            theTaskToInsert.RecordTypeId = SalesTaskRecordTypeId;
            theTaskToInsert.OwnerId = ownerId == '' ? UserInfo.getUserId() : ownerId;
        } else if (taskType == 'ADM') { // ADM Task
            theTaskToInsert.RecordTypeId = ADMTaskRecordTypeId;
            theTaskToInsert.Document_Type__c = docType;

            // Not urgent tasks should show up in the regular task request queue so they need a Request
            if(isUrgent == false) {
                try {
                    // Look for an existing Request object for the Patient account
                    List<Request__c> existingRequestList = [SELECT Id FROM Request__c WHERE Patient__c = :patientId AND Completed__c = false LIMIT 1];

                    // No existing Request, create a new Request that looks up to Patient Account
                    if (existingRequestList.isEmpty()) {
                        Request__c newRequest = new Request__c(Patient__c = patientId, Priority__c = taskPriority);

                        INSERT newRequest;

                        theTaskToInsert.Request__c = newRequest.Id;
                    } else {
                        theTaskToInsert.Request__c = existingRequestList[0].Id;
                    }
                } catch (Exception e) {
                    System.debug('************ Exception: ' + e);
                    return e.getMessage();
                }
            }
        }

        theTaskToInsert.WhatId = patientId == '' ? null : patientId;
        theTaskToInsert.Patient__c = patientId == '' ? null : patientId;
        theTaskToInsert.Provider__c = providerId == '' ? null : providerId;
        theTaskToInsert.Priority = taskPriority;
        theTaskToInsert.Subject = taskSubject;
        theTaskToInsert.ActivityDate = Date.parse(dueDate);
        theTaskToInsert.isUrgent__c = isUrgent;
        theTaskToInsert.Urgent_Reason__c = urgentReason == '–' ? null : urgentReason;
        theTaskToInsert.Description = noteBody;
        theTaskToInsert.Status = 'Open';

        System.debug(theTaskToInsert);
        try {
            INSERT theTaskToInsert;
        } catch (Exception e) {
            System.debug('************ Exception: ' + e);
            return e.getMessage();
        }
        return 'Success';
    }
}