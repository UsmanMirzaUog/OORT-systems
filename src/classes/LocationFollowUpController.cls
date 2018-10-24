/**
 * Created by danielpulache on 11/7/17.
 */

public with sharing class LocationFollowUpController {
    public static Map<Id, List<Task>> mapLocationIdToTaskList;
    public static Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    public class FollowUpItem {
        public String locationTaskSetIdURL {get;set;}
        public String locationTaskSetName {get;set;}
        public String priority {get;set;}
        public String numberOfPatients {get;set;}
        public String numberOfTasks {get;set;}
        public String dollarValue {get;set;}
        public String providerRulesScore {get;set;}
        public String lastContact {get;set;}
        public String followUpDate {get;set;}
        public FollowUpItem(Location__c theLocation) {
            this.locationTaskSetIdURL = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theLocation.Id;
            this.locationTaskSetName = theLocation.Name == 'System Created Location' ? 'MGTS-'+theLocation.Auto_Number__c : theLocation.Name;
            this.priority = theLocation.Priority__c;
            this.numberOfPatients = String.valueOf(theLocation.Num_of_Patients__c);
            this.numberOfTasks = String.valueOf(mapLocationIdToTaskList.get(theLocation.Id).size());
            this.dollarValue = String.valueOf(theLocation.of_Medical_Group_Task_Set__c);
            this.providerRulesScore = theLocation.Provider_Rules_Score__c;
            this.lastContact = theLocation.Last_Patient_Contact_Date__c == null ? null : theLocation.Last_Patient_Contact_Date__c.format();
            this.followUpDate = theLocation.Follow_Up_Date__c == null ? null : theLocation.Follow_Up_Date__c.format();
        }
    }
    @RemoteAction
    public static List<FollowUpItem> getFollowUpItems() {
        List<FollowUpItem> followUpItems = new List<FollowUpItem>();
        Map<Id, Task> theTaskMap = new Map<Id, Task>([SELECT Id, WhatId, Location__c FROM Task WHERE Location__c != null AND RecordTypeId =: ADMRecordTypeId AND Location__r.Num_of_Patients__c != 0 AND Location__r.Num_of_Patients__c != null AND Status != 'Closed']);
        System.debug(theTaskMap);
        mapLocationIdToTaskList = new Map<Id, List<Task>>();
        for(Task theTask : theTaskMap.values()) {
            if(!mapLocationIdToTaskList.containsKey(theTask.Location__c)) {
                mapLocationIdToTaskList.put(theTask.Location__c, new List<Task>{theTask});
            } else {
                mapLocationIdToTaskList.get(theTask.Location__c).add(theTask);
            }
        }
        Map<Id, Location__c> theLocationMap = new Map<Id, Location__c>([SELECT Id, Name, of_Medical_Group_Task_Set__c, Priority__c, Num_of_Patients__c, Provider_Rules_Score__c, Auto_Number__c, Last_Patient_Contact_Date__c, Follow_Up_Date__c FROM Location__c WHERE Id IN : mapLocationIdToTaskList.keySet() AND Num_of_Patients__c > 0 AND Num_of_Patients__c != null LIMIT 500]);
        if (theLocationMap.size() > 0) {
            for (Location__c theLocation : theLocationMap.values()) {
                System.debug(theLocation);
                FollowUpItem item = new FollowUpItem(theLocation);
                followUpItems.add(item);
            }
            return followUpItems;
        }

        return null;
    }
}