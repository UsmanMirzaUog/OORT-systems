/**
 * Created by krizia on 6/18/18.
 */

public with sharing class NotesStreamController { //KHB added with sharing


    public String patientId { get; set; }
    public Id theAccountId { get; set; }
    public List<Task> theTasks { get; set; }
    public List<TaskWithTime> theTaskList { get; set; }

    public NotesStreamController(){ //String patientId
        //Get the records for display
        Id theId;
        if (patientId == null || patientId == '') { //Opportunity right panel
            theId = System.currentPageReference().getParameters().get('Id');
            System.debug(theId);
            if (theId.getSobjectType() == Opportunity.getSObjectType()) theAccountId = [SELECT AccountId FROM Opportunity WHERE Id =: theId LIMIT 1].AccountId;
            else return;
        }
        else if (patientId != null && patientId != ''){ //Patient modal
            theAccountId = (Id)patientId;
        }
        else {
            return;
        }



        System.debug(theAccountId);
        theTaskList = new List<TaskWithTime>();

        //#158711900 BI notes first
        Set<Id> BIids = new Set<Id>();
        List<Task> BInotes = new List<Task>();
        if (patientId == null || patientId == '') { //Opportunity right panel
            BInotes = [SELECT Id, Subject, Description, CreatedBy.Name, CreatedDate, WhatId, RecordType.Name, Opportunity__c
            FROM Task
            WHERE (CreatedBy.Name = 'Integration Account' AND (WhatId =: theAccountId OR Patient__c =: theAccountId))
            AND (Subject = 'Patient Note' OR Opportunity__c =: theId OR WhatId =: theId)
            ORDER BY CreatedDate DESC];
        }
        else { //ADM patient modal
            BInotes = [
                    SELECT Id, Subject, Description, CreatedBy.Name, CreatedDate, WhatId, RecordType.Name, Opportunity__c
                    FROM Task
                    WHERE CreatedBy.Name = 'Integration Account'
                    AND (WhatId = :theAccountId OR Patient__c = :theAccountId)
                    ORDER BY CreatedDate DESC
            ];
        }
        System.debug(BInotes);
        for (Task bi : BInotes){
            theTaskList.add(new TaskWithTime(bi));
            BIids.add(bi.Id);
        }


        theTasks = new List<Task>();
        if (patientId == null || patientId == '') { //Opportunity right panel
            theTasks = [
                    SELECT Id, Subject, Description, CreatedBy.Name, CreatedDate, WhatId, RecordType.Name, Opportunity__c
                    FROM Task
                    WHERE (WhatId =: theAccountId OR Patient__c =: theAccountId)
                    AND (Subject = 'Patient Note' OR Opportunity__c =: theId OR WhatId =: theId)
                    AND Id NOT IN :BIids
                    ORDER BY CreatedDate DESC
            ];
        }
        else { //ADM patient modal
            theTasks = [
                    SELECT Id, Subject, Description, CreatedBy.Name, CreatedDate, WhatId, RecordType.Name, Opportunity__c
                    FROM Task
                    WHERE (WhatId = :theAccountId OR Patient__c = :theAccountId) AND Id NOT IN :BIids
                    ORDER BY CreatedDate DESC
            ];
        }

        for (Task t : theTasks) {
            theTaskList.add(new TaskWithTime(t));
        }
        System.debug(theTaskList);
    } //public NotesStreamController()



    public class TaskWithTime{
        public Task theT { get; set; }
        public String CreatedDateString { get; set; }

        public TaskWithTime(Task t) {
            theT = t;
            CreatedDateString = String.valueOf(t.CreatedDate.format('MM/dd/yyyy HH:mm a'));
        } //public TaskWithTime(Task t)

    }//public class TaskWithTime



}