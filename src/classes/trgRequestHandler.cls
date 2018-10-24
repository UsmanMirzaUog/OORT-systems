/**
 * Created by isaac on 4/22/18.
 */

public with sharing class trgRequestHandler {
    private List<Request__c> triggerNew;
    private List<Request__c> triggerOld;
    private Map<Id, Request__c> triggerNewMap;
    private Map<Id, Request__c> triggerOldMap;
    public static Boolean hasProcessed = false;

    public trgRequestHandler(List<Request__c> triggerNew, List<Request__c> triggerOld, Map<Id, Request__c> triggerNewMap, Map<Id, Request__c> triggerOldMap) {
        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerNewMap = triggerNewMap;
        this.triggerOldMap = triggerOldMap;
    }

    // Update tasks so that it will trigger an update of the Location's Num_of_Patients field
    public void updateTasks() {
        System.debug('trgRequestHandler::: updateTasks:: ' + triggerNew[0].Completed__c);
        if (triggerNew[0].Completed__c == true) {
            List<Task> tasksToUpdate = [SELECT Id, Request__r.Completed__c, Request_Completed__c, ActivityDate FROM Task WHERE Request__c IN :triggerNewMap.keySet() AND Request__r.Completed__c = true];

            System.debug('<<<< trgRequestHandler :: Just before update :: tasksToUpdate: ' + tasksToUpdate);
            if (tasksToUpdate.size() > 0) {
                for (Task t : tasksToUpdate) {
                    t.Request_Completed__c = t.Request__r.Completed__c;
                    t.Follow_Up_Date__c = Date.today().addDays(2);
                }
                System.debug('<<<< trgRequestHandler :: Just before update :: tasksToUpdate: ' + tasksToUpdate);
                update tasksToUpdate;
            }
        }
        hasProcessed = true;
    }
}