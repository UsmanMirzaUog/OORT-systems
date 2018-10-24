/**
 * Created by krizia on 6/6/18.
 */

public with sharing class PARQueueController { //KHB added with sharing


    public PARQueueController() {}
    public static Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
    private static Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    private static Id PatientNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Patient Note').getRecordTypeId();
    private static Id PARNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PAR').getRecordTypeId();
    public static List<Location_Rule__c> theLocationRules { get; set; }

    public class PARQueueItems {
        public String priority {get;set;}
        public String patientId {get;set;}
        public String patientName {get;set;}
        public String providerId {get;set;}
        public String providerName {get;set;}
        public Boolean completed {get;set;}
        public String daysInQueue {get;set;}
        public String referralSource {get;set;}
        public String orderOwnerName {get;set;}
        public String conduitId {get;set;}
        public String requestId {get;set;}
        public String assignedTo {get; set;}
        public Boolean hasLocationRules { get; set; }
        public String locationId { get; set; }
        public Id PARtaskId { get; set; }
        public PARQueueItems(Request__c theRequest, String reqOwnerName, Account thePatient, Provider__c theProvider, Opportunity theOpportunity, Id location, Integer rules, Task parTask) {
            this.providerId =  theProvider == null ? '' :theProvider.Id;
            this.patientId = thePatient.Id;
            this.patientName = thePatient.FirstName + ' ' + thePatient.LastName;
            this.providerName = theProvider == null ? 'Needs PCP' :'Dr. ' +theProvider.Name;
            this.priority = theRequest.Priority__c;
            this.completed = theRequest.PAR_Request_Completed__c;
            this.daysInQueue = String.valueOf(parTask.CreatedDate.Date().daysBetween(System.today()));
            this.referralSource = theOpportunity == null ? '-' :theOpportunity.LeadSource;
            this.orderOwnerName =  theOpportunity == null ? '-' : theOpportunity.Owner.Name;
            this.conduitId = theRequest.Conduit__c;
            this.requestId = theRequest.Id;
            this.assignedTo = reqOwnerName;
            if (rules > 0) this.hasLocationRules = true;
            else this.hasLocationRules = false;
            this.locationId = location;
            this.PARtaskId = parTask.Id;
            System.debug('PARQueueController::: PARQueueItems:: this.hasLocationRules: ' + String.valueOf(this.hasLocationRules));
            System.debug('PARQueueController::: PARQueueItems:: this.PARtaskId: ' + String.valueOf(this.PARtaskId));
        }
    }

//    public class UrgentPARQueueItems {
//        public String priority {get;set;}
//        public String patientId {get;set;}
//        public String patientName {get;set;}
//        public String providerId {get;set;}
//        public String providerName {get;set;}
//        public Boolean completed {get;set;}
//        public String daysInQueue {get;set;}
//        public String referralSource {get;set;}
//        public String orderOwnerName {get;set;}
//        public String conduitId {get;set;}
//        public String taskId {get;set;}
//        public String hoursopen {get;set;}
//        public Boolean taskstatus {get; set;}
//        public String tasktype {get; set;}
//        public String taskstatustext {get; set;}
//        public String assignedTo {get; set;}
//        public String urgentReason{get;set;}
//        public Boolean hasLocationRules { get; set; }
//        public Id locationId { get; set; }
//        public UrgentPARQueueItems() {
//        }
//    }

    @RemoteAction
    public static List<SelectOption> getWIPStateOptions() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('All', 'All'));
        Schema.DescribeFieldResult fieldResult =
                Request__c.Priority__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getValue(), f.getLabel()));
        }
        return options;
    }

    @RemoteAction
    public static List<PARQueueItems> getPARQueueItems(String priority) {
        Set<Id> patientIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> requestIdSet = new Set<Id>();

        List<Request__c> requestList;

        if(priority == 'all') {
            requestList = new List<Request__c>([SELECT Id, Name, ADM_Rep__r.Name, PAR_Request_Completed__c, PAR_Completed__c, Completed__c, Conduit__c, Days_in_Queue__c, Opportunity__c, Patient__c, Priority__c FROM Request__c WHERE PAR_Request_Completed__c = false AND Completed__c = false]);
        } else {
            requestList = new List<Request__c>([SELECT Id, Name, ADM_Rep__r.Name, PAR_Request_Completed__c, PAR_Completed__c, Completed__c, Conduit__c, Days_in_Queue__c, Opportunity__c, Patient__c, Priority__c FROM Request__c WHERE Priority__c =: priority AND PAR_Request_Completed__c = false AND Completed__c = false]);
        }
        for(Request__c theRequest : requestList) {
            patientIdSet.add(theRequest.Patient__c);
            opportunityIdSet.add(theRequest.Opportunity__c);
            requestIdSet.add(theRequest.Id);
        }

        Map<Id, Account> patientMap = new Map<Id, Account>([SELECT Id, FirstName, LastName FROM Account WHERE RecordTypeId =: personAccountRecordTypeId AND Id IN : patientIdSet]);
        Map<Id, Provider__c> providerMap = new Map<Id, Provider__c>([SELECT Id, Name, (SELECT Patient__c FROM Provider_Patient_Junction__r) FROM Provider__c WHERE Id IN (SELECT Provider__c FROM Provider_Patient_Junction__c WHERE PCP__c = true AND Patient__c IN : patientIdSet)]);
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, Name, Owner.Name, LeadSource FROM Opportunity WHERE Id IN : opportunityIdSet]);
        Map<Id, Provider__c> patientToPCPMap = new Map<Id, Provider__c>();
        for(Provider__c theProvider : providerMap.values()) {
            Id theCurrentPatientId = theProvider.Provider_Patient_Junction__r[0].Patient__c;
            patientToPCPMap.put(theCurrentPatientId,theProvider);
        }


        //#158017071 KHB Locations count and Location Id
        List<Task> theTasks = new List<Task>();
        theTasks = [SELECT Id, WhatId, CreatedDate, Request__c, Location__c FROM Task WHERE Request__c IN: requestIdSet AND RecordTypeId =: PARNoteRecordTypeId AND Status != 'Closed' ORDER BY CreatedDate DESC];
        System.debug(theTasks);
        Map<Id, Id> requestToLocation = new Map<Id, Id>();
        Set<Id> locationIdSet = new Set<Id>();
        Map<Id, Task> requestToPARTask = new Map<Id, Task>();
        for (Task t : theTasks) {
            if (!requestToLocation.containsKey(t.WhatId)) {
                requestToLocation.put(t.Request__c, t.Location__c);
                locationIdSet.add(t.Location__c);
            }
            //Capture the latest PAR task as the one that needs to be worked on
            if (!requestToPARTask.containsKey(t.Request__c)) {
                requestToPARTask.put(t.Request__c, t);
            }
        }

        //Build up a map corresponding to Locations in order to figure out if there are any rules
        List<Location_Rule__c> lrList = new List<Location_Rule__c>();
        lrList = [SELECT Id, Location__c FROM Location_Rule__c WHERE Location__c IN: locationIdSet];
        Map<Id, Integer> locationsCount = new Map<Id, Integer>();
        for (Location_Rule__c lr : lrList){
            if (!locationsCount.containsKey(lr.Location__c)) {
                locationsCount.put(lr.Location__c, 1);
            }
            else {
                locationsCount.put(lr.Location__c, locationsCount.get(lr.Location__c) + 1);
            }
        }
        System.debug(requestToLocation);
        System.debug(locationIdSet);
        System.debug(locationsCount);
        System.debug(requestToPARTask);


        //Build the work queue
        List<PARQueueItems> workPARQueueItems = new List<PARQueueItems>();

        for(Request__c theRequest : requestList) {
            //If there isn't a PAR task, on the Request, then it shouldn't show up in the queue
            if (requestToPARTask.containsKey(theRequest.Id)) {
                workPARQueueItems.add(new PARQueueItems(theRequest, theRequest.ADM_Rep__r.Name, patientMap.get(theRequest.Patient__c), patientToPCPMap.get(theRequest.Patient__c), opportunityMap.get(theRequest.Opportunity__c), requestToLocation.get(theRequest.Id), locationsCount.get(requestToLocation.get(theRequest.Id)), requestToPARTask.get(theRequest.Id)));
            }
        }

        return workPARQueueItems;
    }


    @RemoteAction
    public static void updateRequestOwner(String requestId) {
        Request__c theRequestToUpdate = [SELECT Id, Name, Completed__c FROM Request__c WHERE Id =: requestId];
        theRequestToUpdate.ADM_Rep__c = UserInfo.getUserId();
        update theRequestToUpdate;
    }

    @RemoteAction
    public static void updateRequest(String requestId, Boolean isComplete) {
        Request__c theRequestToUpdate = [SELECT Id, Name, PAR_Request_Completed__c, PAR_Request_Complete__c FROM Request__c WHERE Id =: requestId];
        theRequestToUpdate.PAR_Request_Completed__c = isComplete;

        //#158565538 Request/Task aging
        if (isComplete) theRequestToUpdate.PAR_Request_Complete__c = System.now();
        update theRequestToUpdate;
    }

    @RemoteAction
    public static void updateTask(String taskId, Boolean isComplete) {
        Task theTaskToUpdate = [SELECT Id, Status, Request__c, WhatId FROM Task WHERE Id =: taskId];
        if (isComplete) {
            theTaskToUpdate.Status = 'Completed';
            Request__c r = [SELECT Id, PAR_Request_Complete__c FROM Request__c WHERE Id =: theTaskToUpdate.Request__c LIMIT 1];
            r.PAR_Request_Complete__c = System.now();
            UPDATE r;
        } else {
            theTaskToUpdate.Status = 'Not Started';
        }

        update theTaskToUpdate;
    }

    @RemoteAction
    public static Account getPatientNameForADMNoteModal(String ptId) {
        List<Account> ptDetailList = new List<Account>();
        ptDetailList = [SELECT Name from Account WHERE Id = :ptId LIMIT 1];

        if(!ptDetailList.isEmpty()) return ptDetailList[0];

        return null;
    }

    @RemoteAction
    public static String saveADMNote(String patientId, String requestId, String noteBody, Boolean sendToManufacturer, String manufacturer) {
        try {
            Task ADMNote = new Task(
                    RecordTypeId = PatientNoteRecordTypeId,
                    Subject = 'PAR Note',
                    Description = noteBody,
                    WhatId = [SELECT Opportunity__r.AccountId FROM Request__c WHERE Id =: requestId LIMIT 1].Opportunity__r.AccountId,
                    Request__c = requestId,
                    Send_to_Manufacturer__c = sendToManufacturer,
                    Manufacturer__c = manufacturer,
                    Copy_to_Patient_Notes__c = true,
                    Send_To_Hub__c = true,
                    Patient__c = patientId,
                    Status = 'Completed');
            INSERT ADMNote;
        } catch(Exception e) {
            System.debug('************ Exception: ' + e);
            return e.getMessage();
        }
        return 'Success';
    }

    @RemoteAction
    public static List<SelectOption> getManufacturerList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('–', ''));
        for(Schema.PicklistEntry ple : Task.Manufacturer__c.getDescribe().getPickListValues()) {
            options.add(new SelectOption(ple.getValue(), ple.getLabel()));
        }
        return options;
    }



    //#158017071 KHB Location Rules modal
    @RemoteAction
    public static List<Location_Rule__c> getLocationRules(Id theLocationId) {
        System.debug('PARQueueController::: getLocationRules:: theLocationId: ' + theLocationId);
        theLocationRules = [SELECT Id, Value__c, Provider_Rule_Type__c, Required__c
        FROM Location_Rule__c
        WHERE Location__c =: theLocationId];

        System.debug('PARQueueController::: getLocationRules:: theLocationRules: ' + theLocationRules);
        return theLocationRules;
    }
}