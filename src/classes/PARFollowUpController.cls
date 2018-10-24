public with sharing class PARFollowUpController { //KHB added with sharing
  public Task theTask {get;set;}
    public PARFollowUpController() { }
    public static Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
    private static Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    private static Id PatientNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Patient Note').getRecordTypeId();
    private static Id PARNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PAR').getRecordTypeId();

    public static List<Location_Rule__c> theLocationRules { get; set; }
    public class QueueItems {
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
        public String payorName {get; set;}
        public String taskid { get; set; }
        public QueueItems(Request__c theRequest, String reqOwnerName, Account thePatient, Provider__c theProvider, Opportunity theOpportunity, String insuranceName, String taskId) {
            this.providerId =  theProvider == null ? '' :theProvider.Id;
            this.patientId = thePatient.Id;
            this.patientName = thePatient.FirstName + ' ' + thePatient.LastName;
            this.providerName = theProvider == null ? 'Needs PCP' :'Dr. ' +theProvider.Name;
            this.priority = theRequest.Priority__c;
            this.completed = false;
            this.daysInQueue = String.valueOf(theRequest.Days_in_Queue__c);
            this.referralSource = theOpportunity == null ? '-' :theOpportunity.LeadSource;
            this.orderOwnerName =  theOpportunity == null ? '-' : theOpportunity.Owner.Name;
            this.conduitId = theRequest.Conduit__c;
            this.requestId = theRequest.Id;
            this.assignedTo = reqOwnerName;
            //if (rules > 0) this.hasLocationRules = true;
            this.hasLocationRules = false;
           //this.locationId = location;
            this.payorName = insuranceName;
            this.taskid = taskId;

        }
    }


    @RemoteAction
    public static List<QueueItems> getWorkQueueItems(String priority) {
        system.debug ('i hate my life');
        Set<Id> patientIdSet = new Set<Id>();
        Set<Id> opportunityIdSet = new Set<Id>();
        Set<Id> requestIdSet = new Set<Id>();

        Map<Id, Request__c> requestMap;

        // get a task list
        requestMap = new Map<Id, Request__c> ([SELECT Id, Name, ADM_Rep__r.Name, ADM_Completed__c, PAR_Completed__c, Completed__c, Conduit__c, Days_in_Queue__c, Opportunity__c, Patient__c, Priority__c FROM Request__c WHERE PAR_Request_Completed__c = true AND ADM_Completed__c = true AND Completed__c = false]);

        system.debug (requestMap);

        for(Request__c theRequest : requestMap.values()) {
            patientIdSet.add(theRequest.Patient__c);
            opportunityIdSet.add(theRequest.Opportunity__c);
            requestIdSet.add(theRequest.Id);
        }


        List<Task> parFollowUpTasks = [SELECT Id, WhatId, Request__c, Location__c, Insurance_Payor__r.Name FROM TASK WHERE Request__c IN: requestIdSet AND RecordTypeId = :PARNoteRecordTypeId AND Status = 'Open'];
  
        system.debug (parFollowUpTasks);

        Map<Id, Account> patientMap = new Map<Id, Account>([SELECT Id, FirstName, LastName FROM Account WHERE RecordTypeId =: personAccountRecordTypeId AND Id IN : patientIdSet]);
        Map<Id, Provider__c> providerMap = new Map<Id, Provider__c>([SELECT Id, Name, (SELECT Patient__c FROM Provider_Patient_Junction__r) FROM Provider__c WHERE Id IN (SELECT Provider__c FROM Provider_Patient_Junction__c WHERE PCP__c = true AND Patient__c IN : patientIdSet)]);
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, Name, Owner.Name, LeadSource FROM Opportunity WHERE Id IN : opportunityIdSet]);
        Map<Id, Provider__c> patientToPCPMap = new Map<Id, Provider__c>();
        for(Provider__c theProvider : providerMap.values()) {
            Id theCurrentPatientId = theProvider.Provider_Patient_Junction__r[0].Patient__c;
            patientToPCPMap.put(theCurrentPatientId,theProvider);
        }


        //#158017071 KHB Locations count and Location Id
        //List<Task> theTasks = new List<Task>();
        //theTasks = [SELECT Id, WhatId, Request__c, Location__c FROM Task WHERE Request__c IN: requestIdSet];
        //System.debug(theTasks);
        //Map<Id, Id> requestToLocation = new Map<Id, Id>();
        //Set<Id> locationIdSet = new Set<Id>();
        //for (Task t : theTasks) {
        //    if (!requestToLocation.containsKey(t.WhatId)) {
        //        requestToLocation.put(t.Request__c, t.Location__c);
        //        locationIdSet.add(t.Location__c);
        //    }
        //}

        // create PAR to Request object map since our followup screen only shows tasks

        Map<Id, Request__c> parTaskToRequestMap = new Map<Id, Request__c>();

        for(Task t : parFollowUpTasks) {
            if (!parTaskToRequestMap.containsKey(t.Id)) {
                parTaskToRequestMap.put(t.Id, requestMap.get(t.Request__c));
            }
        }

        //Build up a map corresponding to Locations in order to figure out if there are any rules
        //List<Location_Rule__c> lrList = new List<Location_Rule__c>();
        //lrList = [SELECT Id, Location__c FROM Location_Rule__c WHERE Location__c IN: locationIdSet];
        //Map<Id, Integer> locationsCount = new Map<Id, Integer>();
        //for (Location_Rule__c lr : lrList){
        //    if (!locationsCount.containsKey(lr.Location__c)) {
        //        locationsCount.put(lr.Location__c, 1);
        //    }
        //    else {
        //        locationsCount.put(lr.Location__c, locationsCount.get(lr.Location__c) + 1);
        //    }
        //}
        //System.debug(requestToLocation);
        //System.debug(locationIdSet);
        //System.debug(locationsCount);


        //Build the work queue
        List<QueueItems> workQueueItems = new List<QueueItems>();

        if(parFollowUpTasks.size() > 0) {
            system.debug(JSON.serialize(parTaskToRequestMap));
            for(Task t : parFollowUpTasks) {
                system.debug(t.Id);
                Request__c myRequest = parTaskToRequestMap.get(t.Id);
                system.debug('myRequest: '+myRequest);
                system.debug('myRequest.Patient__c: '+myRequest.Patient__c);
                system.debug('myRequest.Opportunity__c: '+myRequest.Opportunity__c);
                system.debug('patientMap.get: '+patientMap.get(myRequest.Patient__c));
                system.debug('patientToPCPMap.get: '+patientToPCPMap.get(myRequest.Patient__c));
                system.debug('opportunityMap.get: '+opportunityMap.get(myRequest.Opportunity__c));
                workQueueItems.add(new QueueItems(
                    myRequest, 
                    myRequest.ADM_Rep__r.Name, 
                    patientMap.get(myRequest.Patient__c), 
                    patientToPCPMap.get(myRequest.Patient__c), 
                    opportunityMap.get(myRequest.Opportunity__c),
                    t.Insurance_Payor__r.Name,
                    String.valueOf(t.Id)
                ));
            }
        } else {
            system.debug('pete');
        }


        //for(Request__c theRequest : requestList) {
        //    workQueueItems.add(new QueueItems(theRequest, theRequest.ADM_Rep__r.Name, patientMap.get(theRequest.Patient__c), patientToPCPMap.get(theRequest.Patient__c), opportunityMap.get(theRequest.Opportunity__c), requestToLocation.get(theRequest.Id), locationsCount.get(requestToLocation.get(theRequest.Id))));
        //}

        return workQueueItems;
    }

  
    @RemoteAction
    public static void updateRequestOwner(String requestId) {
        Request__c theRequestToUpdate = [SELECT Id, Name, Completed__c FROM Request__c WHERE Id =: requestId AND PAR_Completed__c = true];
        theRequestToUpdate.ADM_Rep__c = UserInfo.getUserId();
        update theRequestToUpdate;
    }

//    @RemoteAction
//    public static void updateRequest(String requestId, Boolean isComplete) {
//        Request__c theRequestToUpdate = [SELECT Id, Name, ADM_Rep__c, Completed__c, PAR_Completed__c, Patient__c FROM Request__c WHERE Id =: requestId];
//        theRequestToUpdate.PAR_Completed__c = isComplete;
//        theRequestToUpdate.Completed__c = isComplete;
//
//
//        update theRequestToUpdate;
//        System.debug(theRequestToUpdate);
//    }

    @RemoteAction
    public static void updateTask(String taskId, Boolean isComplete) {
        System.debug('updateTask taskId: ' + taskId);
        Task theTaskToUpdate = [SELECT Id, Status, Request__c FROM Task WHERE Id =: taskId AND RecordTypeId =: PARNoteRecordTypeId LIMIT 1];
        System.debug(theTaskToUpdate);
        Request__c r = [SELECT Id, PAR_Completed__c, Completed__c, PAR_Follow_Up_Complete__c, Entire_Request_Complete__c FROM Request__c WHERE Id =: theTaskToUpdate.Request__c LIMIT 1];
        System.debug(r);
        if (isComplete) {
            System.debug('PARFollowUpController::: updateTask:: isComplete IF: ' + isComplete);
            theTaskToUpdate.Status = 'Completed';
            r.PAR_Completed__c = true;
            r.Completed__c = true;
            r.PAR_Follow_Up_Complete__c = System.now();
            r.Entire_Request_Complete__c = System.now();
        } else {
            System.debug('PARFollowUpController::: updateTask:: isComplete ELSE: ' + isComplete);
            theTaskToUpdate.Status = 'Not Started';
            r.PAR_Completed__c = false;
            r.Completed__c = false;
        }
        System.debug(r);
        System.debug(theTaskToUpdate);
        UPDATE r;
        UPDATE theTaskToUpdate;
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
                    Subject = 'Patient Note',
                    Description = noteBody,
                    WhatId = [SELECT Opportunity__c FROM Request__c WHERE Id =: requestId LIMIT 1].Opportunity__c,
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



//    //#158017071 KHB Location Rules modal
//    @RemoteAction
//    public static List<Location_Rule__c> getLocationRules(Id theLocationId) {
//        System.debug('PARFollowUpController::: getLocationRules:: theLocationId: ' + theLocationId);
//        theLocationRules = [SELECT Id, Value__c, Provider_Rule_Type__c, Required__c
//                FROM Location_Rule__c
//                WHERE Location__c =: theLocationId];
//
//        System.debug('PARFollowUpController::: getLocationRules:: theLocationRules: ' + theLocationRules);
//        return theLocationRules;
//    }

}