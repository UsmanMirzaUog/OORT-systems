public class trgTaskHandler { //KHB removed with sharing
    private Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    private Id CallLogRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Log').getRecordTypeId();
    private Id OppNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Opp Note').getRecordTypeId();
    public static Boolean hasProcessed = false;
    public static Set<Id> alreadyProcessed = new Set<Id>();

    private List<Task> triggerNew;
    private List<Task> triggerOld;
    private Map<Id, Task> triggerNewMap;
    private Map<Id, Task> triggerOldMap;
    public trgTaskHandler(List<Task> triggerNew, List<Task> triggerOld, Map<Id, Task> triggerNewMap, Map<Id, Task> triggerOldMap) {
        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerNewMap = triggerNewMap;
        this.triggerOldMap = triggerOldMap;
    }

    //#157295832: KHB update Opportunity Note on Opportunity from Tasks
    public void updateDexcomFields() {
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> theOpps = new List<Opportunity>();
        Map<Id, Opportunity> theOppsMap = new Map<Id, Opportunity>();
        for (Task t : triggerNew) {
            if (t.Subject != 'Dexcom Notes' && t.Subject != 'Dexcom Notes (Update)') oppIds.add(t.Opportunity__c);
        }
        theOpps = [SELECT Id, AccountId, Dexcom_Opp_Id__c, Status__c, Dexcom_Opportunity_Notes__c, Opportunity_Notes__c, Dexcom_Doctor__c, Dexcom_Primary__c, Dexcom_Secondary__c
                FROM Opportunity
                WHERE Id IN :oppIds];
        theOppsMap = new Map<Id, Opportunity>(theOpps);



        trgOpportunityHandler handler = new trgOpportunityHandler(theOpps, theOpps, theOppsMap, theOppsMap);
        handler.assignDexcomFields(theOpps);
        System.debug(theOpps);
    } //public void updateDexcomFields()



    public void updateTrackerIDOnOpp(List<Task> triggerNew) {
    // this method will look for a tracker ID to update the hub and put it on the opp
    // (These come over with a BI note in the original opportunity insertion process from ILMS)

        List<Opportunity> updateOpps = new List<Opportunity>();
        for (Task t : triggerNew) {
            if (t.Tracker_External_Id__c != '' && t.Tracker_External_Id__c != null) {
                Opportunity updateOpp = new Opportunity();
                if (!Test.isRunningTest()) {
                    updateOpp.Id = t.WhatId; 
                } else {
                    updateOpp.Id = t.Opportunity__c;
                }

                updateOpp.Tracker_External_Id__c = t.Tracker_External_Id__c;
                updateOpps.add(updateOpp);
            }
        }

        if (updateOpps.size() > 0) update updateOpps;

    }

   public void sendNoteToSolaraHub(List<Task> triggerNew){
    // this method should be called when an opp note or call log
    // is saved and the "Send to Hub" option is checked

        Set<Id> whatIdSet = new Set<Id>(); // set of whatIds (to get Opportunities)
        
        // this step should find any records in the trigger that should be sent
        //#157294726 KHB also send any tasks that are of type ADM
        Set<Id> ADMrequestIds = new Set<Id>();
        Set<Id> ADMoppIds = new Set<Id>();
        for (Task t : triggerNew) {
            if (t.Send_To_Hub__c == true || t.RecordTypeId == ADMRecordTypeId) {
                whatIdSet.add(t.Opportunity__c);
                ADMrequestIds.add(t.Request__c);
                //patientWhatIds.add(t.What.Id);
            }        
        }

        // get tracker external ids
        System.debug(whatIdSet);
        Map<Id, Opportunity> oppIdTrackerMap = new Map<Id, Opportunity>([SELECT Id, Tracker_External_Id__c, Account.External_Id__c FROM Opportunity WHERE Id IN :whatIdSet]);

        for (Opportunity o : oppIdTrackerMap.values()) {
            oppIdTrackerMap.put(o.Id, o);
        }

        //TODO: Support ADM Create & Assign Task page
        List<Request__c> requests = new List<Request__c>();
        requests = [SELECT Id, Opportunity__c FROM Request__c WHERE Id IN :ADMrequestIds];
        System.debug(requests);
        for (Request__c r : requests) {
            ADMoppIds.add(r.Opportunity__c);
        }
        System.debug(ADMoppIds);
        Map<Id, Opportunity> ADMoppMap = new Map<Id, Opportunity>([SELECT Id, Tracker_External_Id__c, Account.External_Id__c FROM Opportunity WHERE Id IN :ADMoppIds]);
        for (Request__c r : requests){
            ADMoppMap.put(r.Id, ADMoppMap.get(r.Opportunity__c));
            System.debug(ADMoppMap.get(r.Opportunity__c));
        }


        // loop over tasks in the trigger and send the ones to the hub that belong in the hub
        // (That would be any user entered note Call Log | Opp Note | Patient Note from Console)
       //#157294726 KHB also send any tasks that are of type ADM

        for (Task t : triggerNew) {
            if (t.Send_To_Hub__c == true || t.RecordTypeId == ADMRecordTypeId) {
                String trackerId = oppIdTrackerMap.get(t.Opportunity__c) != null ? oppIdTrackerMap.get(t.Opportunity__c).Tracker_External_Id__c : '';
                String patientHubId = oppIdTrackerMap.get(t.Opportunity__c) != null ? oppIdTrackerMap.get(t.Opportunity__c).Account.External_Id__c : '';
                String noteText = t.Description != null ? t.Description : '';
                Date needDate = t.Follow_Up_Date__c;
                if (trackerId == null) trackerId = '';
                if (patientHubId == null) patientHubId = '';
                JSONGenerator jsonGen = JSON.createGenerator(true);
                jsonGen.writeStartObject();
                jsonGen.writeStringField('NoteHubID', trackerId);
                jsonGen.writeStringField('PatientHubID', patientHubId);
                jsonGen.writeStringField('NoteText', noteText);
                if (t.Follow_Up_Date__c != null) jsonGen.writeDateField('NeedDate', t.Follow_Up_Date__c);
                jsonGen.writeEndObject();

                String theJson = jsonGen.getAsString();

                if (trackerId != '' && trackerId != null && patientHubId != '' && patientHubId != null && noteText != null && noteText != '') {
                    system.debug('attempting a bt send:::');
                    SolaraHubIntegration.callHubService('updatePatientNote', 'POST', theJson, t.Id, true);
                }
            }
        }

    }

    public void setFollowUpDateOnOpp(){
        // this method should take the follow up date that is entered in call logs
        // and set it as the opportunity level follow up date

        List<Opportunity> updateOpps = new List<Opportunity>();

        for (Task t : triggerNew) {
            if (t.Follow_Up_Date__c != null && t.Opportunity__c != null) {
                Opportunity o = new Opportunity();
            //    o.Id = t.WhatId;
                o.Id = t.Opportunity__c;
                o.Next_Follow_Up_Date__c = t.Follow_Up_Date__c;
                updateOpps.add(o);
            }
        }

        if (updateOpps.size() > 0 ) update updateOpps;

    }

    //on after task insert
    public void trackPatientLastContactDate() {
        System.debug('<<<<< trgTaskHandler::trackPatientLastContactDate START');
//        System.debug('<<<<< trgTaskHandler::trackPatientLastContactDate triggerNew' + triggerNew);
        Map<Id, Task> patientIdToTaskMap = new Map<Id,Task>();
        //Whenever a call is log against a patient
        for(Task theNewTask : triggerNew) {
            if(theNewTask.RecordTypeId == CallLogRecordTypeId && theNewTask.Patient__c != null) {
                patientIdToTaskMap.put(theNewTask.Patient__c, theNewTask);
            }
        }

        //Query the Patients who got recently contacted
        Map<Id, Account> mapIdTopatient = new Map<Id, Account>([SELECT Id, Last_Contact_Date__c FROM Account WHERE Id IN : patientIdToTaskMap.keySet()]);

        //Patient's Last Contact Date comes from Task Note's ActivityDate
        for(Account thePatient : mapIdTopatient.values()) {
            Task theCallLogTask = patientIdToTaskMap.get(thePatient.Id);
            if(thePatient.Last_Contact_Date__c == null || thePatient.Last_Contact_Date__c < theCallLogTask.ActivityDate) {
                thePatient.Last_Contact_Date__c = theCallLogTask.ActivityDate;
            }
        }

//        System.debug('***** trgTaskHandler::trackPatientLastContactDate::Patients that need Last Contact Date updated = ' + mapIdTopatient);
        if(!mapIdTopatient.isEmpty()) {
            UPDATE mapIdTopatient.values();

            // Now update all of the patient's ADM Tasks
            // Get a list of tasks that belong to the patients above
            List<Task> ADMTaskToUpdateList = new List<Task>([SELECT Id, Last_Contact_Date__c, Patient__c FROM Task WHERE RecordTypeId = :ADMRecordTypeId AND Patient__c IN :patientIdToTaskMap.keySet()]);

            // For each task change the last contact date to the last contact date of the Patient
            for (Task theADMTask : ADMTaskToUpdateList) {
                theADMTask.Last_Contact_Date__c = mapIdTopatient.get(theADMTask.Patient__c).Last_Contact_Date__c;
            }

            if (ADMTaskToUpdateList.size() > 0) {
                UPDATE ADMTaskToUpdateList;
            }
        }
    }
    //on after task update
    public void groupTasksUnderLocationBasedOnAddress() {
        List<Location__c> locationsToInsert = new List<Location__c>();
        Map<String, Location__c> mapLocationKeyToLocation = new Map<String, Location__c>();

        Map<String, Id> mapLocationKeyToProviderId = new Map<String, Id>();
        Map<Id, List<Task>> mapProviderIdToTaskList = new Map<Id, List<Task>>();
        for(Task theNewTask : triggerNew) {
            if(trigger.isInsert && theNewTask.Provider__c != null && theNewTask.RecordTypeId == ADMRecordTypeId) {
                if(!mapProviderIdToTaskList.containsKey(theNewTask.Provider__c)) {
                    mapProviderIdToTaskList.put(theNewTask.Provider__c, new List<Task>{theNewTask});
                } else {
                    mapProviderIdToTaskList.get(theNewTask.Provider__c).add(theNewTask);
                }
            }
            else if(trigger.isUpdate && theNewTask.Provider__c != null && theNewTask.Provider__c != triggerOldMap.get(theNewTask.Id).Provider__c && theNewTask.RecordTypeId == ADMRecordTypeId) {
                if(!mapProviderIdToTaskList.containsKey(theNewTask.Provider__c)) {
                    mapProviderIdToTaskList.put(theNewTask.Provider__c, new List<Task>{theNewTask});
                } else {
                    mapProviderIdToTaskList.get(theNewTask.Provider__c).add(theNewTask);
                }
            }
        }

        Map<Id, Provider__c> mapIdToProvider = new Map<Id, Provider__c>([SELECT Id, Address__c,Address2__c, City__c, State__c, Zip__c FROM Provider__c WHERE Id IN : mapProviderIdToTaskList.keySet()]);
        for(Provider__c theProvider : mapIdToProvider.values()) {
            /*
            *
            * Key depends on workflow rule on the Location Object. Make sure the format matches the format in the worklfow rule
            *
            * */
            String key = theProvider.Address__c +'!'+ theProvider.Address2__c +'!'+ theProvider.City__c +'!'+ theProvider.State__c +'!'+ theProvider.Zip__c;
            mapLocationKeyToProviderId.put(key, theProvider.Id);
        }

        Map<Id, Location__c> mapIdToLocation = new Map<Id, Location__c>([SELECT Id, Address_Line_1__c, Address_Line_2__c, City__c, State__c, Zip_Code__c, Location_Key__c FROM Location__c WHERE Location_Key__c IN : mapLocationKeyToProviderId.keySet()]);
        for(Location__c theLocation : mapIdToLocation.values()) {
            mapLocationKeyToLocation.put(theLocation.Location_Key__c, theLocation);
        }

        for(String locationKey : mapLocationKeyToProviderId.keySet()) {
            Id providerId = mapLocationKeyToProviderId.get(locationKey);
            List<Task> tasksToGroup = mapProviderIdToTaskList.get(providerId);
            if(tasksToGroup != null && !tasksToGroup.isEmpty()) {
                for(Task theTask : tasksToGroup) {
                    if(!mapLocationKeyToLocation.containsKey(locationKey)) {
                        //Create New Location if the Provider didn't already have a Location
                        Location__c temporaryLocation = createLocationFromLocationKey(locationKey);
                        mapLocationKeyToLocation.put(locationKey, temporaryLocation);
                        locationsToInsert.add(temporaryLocation);
                    }
                }
            }
        }

        if(!locationsToInsert.isEmpty()) INSERT locationsToInsert;

        for(String locationKey : mapLocationKeyToProviderId.keySet()) {
            Id providerId = mapLocationKeyToProviderId.get(locationKey);
            List<Task> tasksToGroup = mapProviderIdToTaskList.get(providerId);
            if(tasksToGroup != null && !tasksToGroup.isEmpty()) {
                for(Task theTask : tasksToGroup) {
                    theTask.Location__c = mapLocationKeyToLocation.get(locationKey).Id;
                }
            }
        }
    }

    private Location__c createLocationFromLocationKey(String locationKey) {
        List<String> addressData = locationKey.split('!');
        Location__c theLocationToRetun = new Location__c();
        theLocationToRetun.Address_Line_1__c = addressData[0];
        theLocationToRetun.Address_Line_2__c = addressData[1];
        theLocationToRetun.City__c = addressData[2];
        System.debug(addressData[3]);
        if (addressData[3] != null && addressData[3] != 'null') {
            theLocationToRetun.State__c = addressData[3];
        }
        theLocationToRetun.Zip_Code__c = addressData[4];
        return theLocationToRetun;
    }

    public void updateNumberOfPatients() {
        System.debug('>>> trgTaskHandler::updateNumberOfPatients::Start');
        List<Location__c> locationsToUpdateList = new List<Location__c>();
        List<Id> locationIdsToUpdateList = new List<Id>(); //List of Locations to update number of Patients
        System.debug('>>> trgTaskHandler::updateNumberOfPatients::triggerNew' + triggerNew);

        // Get list of Location Ids contained in the trigger
        for (Task t : triggerNew) {
            if (t.RecordTypeId == ADMRecordTypeId && t.Location__c != null){ //Only update ADM tasks with a Location Id
                locationIdsToUpdateList.add(t.Location__c);
            }
        }   

        System.debug('>>> trgTaskHandler::updateNumberOfPatients::location ids to update list: ' + locationIdsToUpdateList);


        // Get all open tasks for Locations in the trigger
        Map<Id, Set<Id>> locationIdToPatientIdSetMap = new Map<Id, Set<Id>>();
        //My original query
//        List<Task> tasksForAllLocations = [SELECT Location__c, Patient__c, Request__r.Completed__c FROM Task WHERE Location__c IN :locationIdsToUpdateList AND Status = 'Open' AND Request__r.Completed__c = true];
        //Same query as LocationDetail getTaskItems()
        List<Task> tasksForAllLocations = [SELECT Location__c, Patient__c, Request_Completed__c, isUrgent__c
                FROM Task
                WHERE RecordTypeId =: ADMRecordTypeId
                    AND Location__c IN :locationIdsToUpdateList
                    AND (Request_Completed__c = true OR isUrgent__c = true)
                    AND Status != 'Completed'
                ORDER BY CreatedDate DESC];
        Id previousLocationId = null;

        System.debug('>>> trgTaskHandler:: tasksforAllLocations: ' + tasksForAllLocations);
        if (tasksForAllLocations.size() > 0) {
            // Build map of Location Ids to Set of Patients at that location that have tasks
            for (Task t : tasksForAllLocations) {
                if (t.Location__c == previousLocationId) { // Add Patient to set if the location is the same
                    if (t.Request_Completed__c == true || t.isUrgent__c == true) {
                        locationIdToPatientIdSetMap.get(t.Location__c).add(t.Patient__c);
                    }
                } else { // If this is a new location, put the Location Id and a new set of Patient Ids, and add the current patient to the set
                    locationIdToPatientIdSetMap.put(t.Location__c, new Set<Id>());
                    if (t.Request_Completed__c == true || t.isUrgent__c == true) {
                        locationIdToPatientIdSetMap.get(t.Location__c).add(t.Patient__c);
                    }
                    previousLocationId = t.Location__c;
                }
            }
        } else {
            if (locationIdsToUpdateList.size() > 0) {
                locationIdToPatientIdSetMap.put(locationIdsToUpdateList[0], new Set<Id>()); // Location has 0 tasks, therefore 0 pts
            }
        }
        System.debug('>>> trgTaskHandler::updateNumberOfPatients::Map of Location Ids to Set of Patient Ids: ' + locationIdToPatientIdSetMap);

        // Iterate through the Location Ids and update the location with the number of patients in the set
        for (Id locationId : locationIdToPatientIdSetMap.keySet()) {
            Location__c theLocation = new Location__c(
                    Id = locationId
                    , Num_of_Patients__c = locationIdToPatientIdSetMap.get(locationId).size() == 0 ? null : locationIdToPatientIdSetMap.get(locationId).size() // Num of pts = Size of the Set of ptId for that location
            );
            locationsToUpdateList.add(theLocation);
        }

        System.debug('*** trgTaskHandler::updateNumberOfPatients::locationsToUpdateList: ' + locationsToUpdateList);

        // Update the locations with their new Num_of_Patients count
        if(locationsToUpdateList.size() > 0) update locationsToUpdateList;
    }

    public void updateRelatedRequests() {
        System.debug('>>> trgTaskHandler::updateRelatedRequests::Start');
        List<Id> requestIdList = new List<Id>();
        for (Task t : triggerNew) {
            if (t.Request__c != null) {
                requestIdList.add(t.Request__c);
            }
        }

        List<Request__c> requestsToUpdate = [SELECT Id, Completed__c FROM Request__c WHERE Id IN :requestIdList];
        if (requestsToUpdate.size() > 0) {
            for (Request__c theRequest : requestsToUpdate) {
                theRequest.Completed__c = false;
            }

            update requestsToUpdate;
        }
    }

    public void updateFollowUpDate() {
        System.debug('*********** updateFollowUpDate');
        Set<Id> locationIdSet = new Set<Id>();
        if (triggerNew[0].RecordTypeId == ADMRecordTypeId) {
            if ((trigger.isInsert && triggerNew[0].Location__c != null) || (trigger.isUpdate && (triggerNew[0].Follow_Up_Date__c != triggerOldMap.get(triggerNew[0].Id).Follow_Up_Date__c || triggerNew[0].Request_Completed__c != triggerOldMap.get(triggerNew[0].Id).Request_Completed__c || triggerNew[0].Status == 'Completed'))) {
                Location__c theLocation = new Location__c();
                //KHB addition because not all have an attached Location
                if (triggerNew[0].Location__c != null) {
                    theLocation = [SELECT Follow_Up_Date__c FROM Location__c WHERE Id = :triggerNew[0].Location__c LIMIT 1];
                    List<Task> taskList = new List<Task>();
                    taskList = [
                            SELECT Location__c, Follow_Up_Date__c, Status
                            FROM Task
                            WHERE RecordTypeId = :ADMRecordTypeId
                            AND Follow_Up_Date__c != null
                            AND Location__c = :theLocation.Id
                            AND Status != 'Completed'
                            AND (Request_Completed__c = true OR isUrgent__c = true)
                            ORDER BY Follow_Up_Date__c ASC
                    ];
                    System.debug('********** taskList: ' + taskList);
                    if (taskList.size() > 0) {
                        theLocation.Follow_Up_Date__c = taskList[0].Follow_Up_Date__c;
                    } else {
                        theLocation.Follow_Up_Date__c = null;
                    }
                    update theLocation;
                }
            }
        }
    }



    public void updateADMCompletedRequest() {
        System.debug('trgTaskHandler::: updateADMCompletedRequest::');
        Set<Id> requestIds = new Set<Id>();
        List<Request__c> requests = new List<Request__c>();
        for (Task t : triggerNew) {
            System.debug('trgTaskHandler::: updateADMCompletedRequest:: t: ' + t);
            if (t.RecordTypeId == ADMRecordTypeId && t.Status == 'Completed' && t.Request__c != null) {
                requestIds.add(t.Request__c);
            }
        }


        //When an ADM Task is marked as Completed, be sure to mark the Request as completed as well
        requests = [SELECT Id, ADM_Request_Completed__c, ADM_Completed__c, Completed__c, Patient__c, ADM_Follow_Up_Complete__c, Entire_Request_Complete__c FROM Request__c WHERE Id IN :requestIds];
        System.debug(requests);
        Set<Id> patients = new Set<Id>();
        for (Request__c r : requests) {
            patients.add(r.Patient__c);
        }

        if (!requests.isEmpty()) {
            System.debug('trgTaskHandler::: updateADMCompletedRequest:: getting ipjList');
            List<Insurance_Patient_Junction__c> ipjList = new List<Insurance_Patient_Junction__c>();
            ipjList = [
                    SELECT Id, Account__c, Insurance__c, Name, Insured_Name__c, Requires_PAR__c
                    FROM Insurance_Patient_Junction__c
                    WHERE Account__c IN :patients // AND Requires_PAR__c = true
            ];
            System.debug(ipjList);
            Map<Id, Boolean> patientToIPJ = new Map<Id, Boolean>();
            for (Insurance_Patient_Junction__c ipj : ipjList) {
                if (patientToIPJ.containsKey(ipj.Account__c) && ipj.Requires_PAR__c == true) {
                    patientToIPJ.put(ipj.Account__c, ipj.Requires_PAR__c);
                } else if (!patientToIPJ.containsKey(ipj.Account__c)) {
                    patientToIPJ.put(ipj.Account__c, ipj.Requires_PAR__c);
                }
            }
            System.debug(patientToIPJ);

            System.debug('trgTaskHandler::: updateADMCompletedRequest:: go through the requests and update them');
            for (Request__c r : requests) {
                System.debug(r);
                r.ADM_Completed__c = true;
                r.ADM_Follow_Up_Complete__c = System.now();
                if (patientToIPJ.get(r.Patient__c) == false && r.Completed__c == false) {
                    r.Completed__c = true;
                    r.Entire_Request_Complete__c = System.now();
                }
            }
            System.debug('trgTaskHandler::: updateADMCompletedRequest:: requests: ' + requests);
            UPDATE requests;
        }
    } //public void updateADMCompletedRequest()
}