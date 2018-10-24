/**
 * Created by danielpulache on 10/31/17.
 */

public with sharing class TaskWorkQueueController {
    public Task theTask {get;set;}
    public TaskWorkQueueController() { }
    public static Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
    private static Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    private static Id PatientNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Patient Note').getRecordTypeId();
    public static List<Location_Rule__c> theLocationRules { get; set; }

    private static Id PARNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PAR').getRecordTypeId();
    public with sharing class QueueItems { //KHB added with sharing
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
        public QueueItems(Request__c theRequest, String reqOwnerName, Account thePatient, Provider__c theProvider, Opportunity theOpportunity, Id location, Integer rules) {
            this.providerId =  theProvider == null ? '' :theProvider.Id;
            this.patientId = thePatient.Id;
            this.patientName = thePatient.FirstName + ' ' + thePatient.LastName;
            this.providerName = theProvider == null ? 'Needs PCP' :'Dr. ' +theProvider.Name;
            this.priority = theRequest.Priority__c;
            this.completed = theRequest.ADM_Request_Completed__c;
            this.daysInQueue = String.valueOf(theRequest.Days_in_Queue__c);
            this.referralSource = theOpportunity == null ? '-' :theOpportunity.LeadSource;
            this.orderOwnerName =  theOpportunity == null ? '-' : theOpportunity.Owner.Name;
            this.conduitId = theRequest.Conduit__c;
            this.requestId = theRequest.Id;
            this.assignedTo = reqOwnerName;
            if (rules > 0) this.hasLocationRules = true;
            else this.hasLocationRules = false;
            this.locationId = location;
            System.debug('TaskWorkQueueController::: QueueItems:: this.hasLocationRules: ' + String.valueOf(this.hasLocationRules));
        }
    }

    public with sharing class UrgentQueueItems {//KHB added with sharing
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
        public String taskId {get;set;}
        public String hoursopen {get;set;}
        public Boolean taskstatus {get; set;}
        public String tasktype {get; set;}
        public String taskstatustext {get; set;}
        public String assignedTo {get; set;}
        public String urgentReason{get;set;}
        public Boolean hasLocationRules { get; set; }
        public Id locationId { get; set; }
        public UrgentQueueItems() {

        }
    }

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
    public static List<QueueItems> getWorkQueueItems(String priority) {
        Set<Id> patientIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> requestIdSet = new Set<Id>();

        List<Request__c> requestList;
        if(priority == 'all') {
            requestList = new List<Request__c>([SELECT Id, Name, ADM_Rep__r.Name, ADM_Request_Completed__c, ADM_Completed__c, Completed__c, Conduit__c, Days_in_Queue__c, Opportunity__c, Patient__c, Priority__c FROM Request__c WHERE ADM_Request_Completed__c = false AND Completed__c = false]);
        } else {
            requestList = new List<Request__c>([SELECT Id, Name, ADM_Rep__r.Name, ADM_Request_Completed__c, ADM_Completed__c, Completed__c, Conduit__c, Days_in_Queue__c, Opportunity__c, Patient__c, Priority__c FROM Request__c WHERE Priority__c =: priority AND ADM_Request_Completed__c = false AND Completed__c = false]);
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
        theTasks = [SELECT Id, WhatId, Request__c, Location__c FROM Task WHERE Request__c IN: requestIdSet];
        System.debug(theTasks);
        Map<Id, Id> requestToLocation = new Map<Id, Id>();
        Set<Id> locationIdSet = new Set<Id>();
        for (Task t : theTasks) {
            if (!requestToLocation.containsKey(t.WhatId)) {
                requestToLocation.put(t.Request__c, t.Location__c);
                locationIdSet.add(t.Location__c);
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


        //Build the work queue
        List<QueueItems> workQueueItems = new List<QueueItems>();

        for(Request__c theRequest : requestList) {
            workQueueItems.add(new QueueItems(theRequest, theRequest.ADM_Rep__r.Name, patientMap.get(theRequest.Patient__c), patientToPCPMap.get(theRequest.Patient__c), opportunityMap.get(theRequest.Opportunity__c), requestToLocation.get(theRequest.Id), locationsCount.get(requestToLocation.get(theRequest.Id))));
        }

        return workQueueItems;
    }

    @RemoteAction
    public static List<UrgentQueueItems> getUrgentQueueItems(String theStr) {
        Set<Id> patientIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();


    
        List<UrgentQueueItems> urgentWorkQueueItems = new List<UrgentQueueItems>();

        List<Task> urgentTasks = [Select Id, WhoId, Owner.Name, What.Name, WhatId, Hours_Open__c, Subject, Priority, Status, Provider__r.Name, Urgent_Reason__c, Location__c FROM Task WHERE isUrgent__c = true AND Status != 'Completed'];


        //#158017071 Get Locations
        Set<Id> locations = new Set<Id>();
        Map<Id, Id> taskToLocationMap = new Map<Id, Id>();
        Map<Id, Integer> locationToRuleCountMap = new Map<Id, Integer>();
        for (Task t : urgentTasks) {
            locations.add(t.Location__c);
            taskToLocationMap.put(t.Id, t.Location__c);
        }
        //Get the Location Rules count of each Location
        if (locations.size() > 0) {
            List<Location_Rule__c> locationRules = new List<Location_Rule__c>();
            locationRules = [SELECT Id, Location__c, Value__c FROM Location_Rule__c WHERE Location__c IN: locations];

            //Go through the Location Rules and count up how many there are for each Location so we can either display the
            //Location Rules buttons or not
            for (Location_Rule__c lr : locationRules){
                //when the Location is already in the map, just add one to it, otherwise start counting at 1
                if (locationToRuleCountMap.containsKey(lr.Location__c)) {
                    locationToRuleCountMap.put(lr.Location__c, 1 + locationToRuleCountMap.get(lr.Location__c));
                }
                else {
                    locationToRuleCountMap.put(lr.Location__c, 1);
                }
            }
            System.debug(locationToRuleCountMap);
        }


        for(Task t : urgentTasks) {
            UrgentQueueItems uqi = new UrgentQueueItems();
            uqi.priority = t.Priority;
            uqi.patientName = t.What.Name;
            uqi.patientId = t.WhatId;
            uqi.hoursopen = String.valueOf(t.Hours_Open__c);
            uqi.taskId = t.Id;
            uqi.tasktype = t.Subject;
            uqi.taskstatustext = t.Status;
            uqi.urgentReason = t.Urgent_Reason__c;
            uqi.assignedTo = t.Owner.Name;
            uqi.providerName = t.Provider__r.Name;
            if (t.Status != 'Completed') {
                uqi.taskstatus = false;
            } else {
                uqi.taskstatus = true;  
            }
            uqi.locationId = t.Location__c;
            if (locationToRuleCountMap.containsKey(taskToLocationMap.get(t.Id))) {
                Integer rules = locationToRuleCountMap.get(taskToLocationMap.get(t.Id));
                if (rules > 0) uqi.hasLocationRules = true;
                else uqi.hasLocationRules = false;
            }
            else uqi.hasLocationRules = false;
            System.debug('TaskWorkQueueController::: getUrgentQueueItems:: uqi.hasLocationRules: ' + String.valueOf(uqi.hasLocationRules) + ' -- locaitonId: ' + uqi.locationId);
            urgentWorkQueueItems.add(uqi);
        }

        return urgentWorkQueueItems;
    }

    @RemoteAction
    public static void updateRequestOwner(String requestId) {
        Request__c theRequestToUpdate = [SELECT Id, Name, Completed__c FROM Request__c WHERE Id =: requestId];
        theRequestToUpdate.ADM_Rep__c = UserInfo.getUserId();
        update theRequestToUpdate;
    }

    @RemoteAction
    public static void updateRequest(String requestId, Boolean isComplete) {
        Request__c theRequestToUpdate = [SELECT Id, Name, ADM_Rep__c, Completed__c, ADM_Request_Completed__c, Patient__c, Payor_Bucket__c FROM Request__c WHERE Id =: requestId];
        theRequestToUpdate.ADM_Request_Completed__c = isComplete;
        //#158565538 Request/Task aging
        if (isComplete) theRequestToUpdate.ADM_Request_Complete__c = System.now();

        //#158193629 create PAR tasks if need be based on the Patient/Payor junction
        List<Insurance_Patient_Junction__c> ipjList = new List<Insurance_Patient_Junction__c>();
        ipjList = [SELECT Id, Account__c, Insurance__c, Name, Insured_Name__c, Requires_PAR__c
                FROM Insurance_Patient_Junction__c
                WHERE Account__c =: theRequestToUpdate.Patient__c AND Requires_PAR__c = true];
        System.debug(ipjList);

        List<Task> reqTasks = [SELECT Id, Request_Completed__c, Request__c FROM Task WHERE Request__c = :theRequestToUpdate.Id];

        // todo add Opportunity query to only mark opp related tasks complete? will bomb on multi order patients

        List<Task> tasksToUpdate = new List<Task>();

        for(Task t : reqTasks) {
            Task tsk = new Task();
            tsk.Id = t.Id;
            tsk.Request_Completed__c = true;
            tasksToUpdate.add(tsk);
        }

        update tasksToUpdate;



        if (!ipjList.isEmpty()){
            theRequestToUpdate.ADM_Rep__c = null;
            List<Task> PARTasks = new List<Task>();
            for (Insurance_Patient_Junction__c ipj : ipjList){
                Task t = new Task(
                        RecordTypeId = PARNoteRecordTypeId,
                        WhatId = theRequestToUpdate.Patient__c,
                        Request__c = theRequestToUpdate.Id,
                        Insurance_Payor__c = ipj.Insurance__c,
                        Patient__c = ipj.Account__c,
                        Subject = 'PAR Task Created',
                        Description = 'PAR Task Created',
                        Status = 'Open',
                        Payor_Bucket__c = theRequestToUpdate.Payor_Bucket__c
                );
                PARTasks.add(t);
            }
            System.debug(PARTasks);
            INSERT PARTasks;
        }
        else {
        //    theRequestToUpdate.Completed__c = isComplete;
        }

        update theRequestToUpdate;
        System.debug(theRequestToUpdate);
    }

    @RemoteAction
    public static void updateTask(String taskId, Boolean isComplete) {
        Task theTaskToUpdate = [SELECT Id, Status, Request__c, WhatId FROM Task WHERE Id =: taskId];
        if (isComplete) {
            theTaskToUpdate.Status = 'Completed';
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
                    Subject = 'ADM Note',
                    Description = noteBody,
            //        WhatId = [SELECT Opportunity__c FROM Request__c WHERE Id =: requestId LIMIT 1].Opportunity__c,
                    WhatId = patientId,
                    Opportunity__c = [SELECT Opportunity__c FROM Request__c WHERE Id =: requestId LIMIT 1].Opportunity__c,
                    Request__c = requestId,
                    Send_to_Manufacturer__c = sendToManufacturer,
                    Manufacturer__c = manufacturer,
                    Copy_to_Patient_Notes__c = true,
                    Send_to_Hub__c = true,
                    Patient__c = patientId,
                    Status = 'Completed');
            System.debug(ADMNote);
            INSERT ADMNote;
        } catch(Exception e) {
            System.debug('************ Exception: ' + e);
            System.debug(e.getMessage());
            System.debug(e.getStackTraceString());
            System.debug(e.getCause());
            System.debug(e.getTypeName());
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
        System.debug('TaskWorkQueueController::: getLocationRules:: theLocationId: ' + theLocationId);
        theLocationRules = [SELECT Id, Value__c, Provider_Rule_Type__c, Required__c
                FROM Location_Rule__c
                WHERE Location__c =: theLocationId];

        System.debug('TaskWorkQueueController::: getLocationRules:: theLocationRules: ' + theLocationRules);
        return theLocationRules;
    }
}