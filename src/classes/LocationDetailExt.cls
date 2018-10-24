/**
 * Created by danielpulache on 11/16/17.
 */

public with sharing class LocationDetailExt {
    public Location__c theLocation {get;set;}
    public Location__c theLocationDetails {get;set;}
    public Id patientId {get;set;}
    public Boolean copyToPatientNotes {get;set;}
    public Task theCallLog {get;set;}
    private static Id CallLogRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Log').getRecordTypeId();
    private static Id ADMRecordType = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
    public LocationDetailExt(ApexPages.StandardController controller) {
        theLocation = (Location__c) controller.getRecord();
        theLocationDetails =
            [SELECT Id, Name, Location_Name__c, Auto_Number__c, Priority__c, Address_Line_1__c, Address_Line_2__c, City__c,
                    State__c, Zip_Code__c, Outside_Sales_Rep__c, of_Medical_Group_Task_Set__c, Fax__c, Phone__c,
                    Provider_Rules_Score__c, Num_of_Patients__c, Last_Patient_Contact_Date__c
            FROM Location__c
            WHERE Id =: theLocation.Id];
        theLocationDetails.Address_Line_2__c = theLocationDetails.Address_Line_2__c == 'null' ? null : theLocationDetails.Address_Line_2__c; // Prevent the Address Details from displaying 'null' on the Location Detail page
        copyToPatientNotes = true;
        theCallLog = new Task();
    }
    public void saveTheRecord() {
        UPDATE theLocationDetails;
    }

    //#157318652 KHB notes templates populate the text body
    @RemoteAction
    public static String setTemplate(String disposition) {
        //Whenever the Call Disposition has a value, it should put a template into the text body for the note
        if (disposition != null && disposition != ''){
            System.debug('I am in!');
            System.debug(disposition);
            Notes_Template__c nt = new Notes_Template__c();
            try {
                nt = [SELECT Id, Call_Disposition__c, Template__c FROM Notes_Template__c WHERE Call_Disposition__c = :disposition LIMIT 1];

                //When one isn't found, don't do anything
                if (nt.Template__c != null && nt.Template__c != '') {
                    String description = nt.Template__c;
                    System.debug(description);
                    return (description);
                }
            }
            catch (Exception e) {
                System.debug('LocationDetailExt::: setTemplate:: did not find a Note Template for: ' + disposition);
                System.debug(e);
                return '';
            }
        }
        return '';
    } //public static String setTemplate



    /*
    *   Takes a location Id and returns call logs to display in the Call Log History table
    **/
    @RemoteAction
    public static List<CallLogItem> getCallLogItems(String locationId) {
        List<Task> theCallLogs = new List<Task>([SELECT Id, Subject, CreatedDate, CreatedBy.Name, Description,
                                                    Call_Disposition__c, Call_Outcome__c, Patient__c, Patient__r.Name
                                                FROM Task
                                                WHERE RecordTypeId =: CallLogRecordType
                                                AND WhatId =: locationId
                                                ORDER BY CreatedDate DESC]);
        List<CallLogItem> callLogItemList = new List<CallLogItem>();
        for(Task theTask : theCallLogs) {
            CallLogItem item  = new CallLogItem(theTask);
            callLogItemList.add(item);
        }
        
        return callLogItemList;
    }

    /*
    *   Takes a location Id and returns the Location Rules associated with that location
    **/
    @RemoteAction
    public static List<LocationRuleItem> getLocationRules(String locationId) {
        List<Location_Rule__c> theLocationRuleList = new List<Location_Rule__c>([SELECT Id, Name,
                Provider_Rule_Type__c,Value__c, Required__c
                        FROM Location_Rule__c
                        WHERE Location__c =: locationId
                        ORDER BY CreatedDate DESC]);
        List<LocationRuleItem> itemList = new List<LocationRuleItem>();
        for(Location_Rule__c theRule : theLocationRuleList){
            LocationRuleItem item = new LocationRuleItem(theRule);
            itemList.add(item);
        }

        return itemList;
    }

    /*
    *   Takes a location Id and returns a list of Tasks to display the Task table
    **/
    @RemoteAction
    public static List<TaskItem> getTasksItems(String locationId) { 
        List<Task> theADMTaskList = new List<Task>([SELECT Id, Subject, CreatedDate, ActivityDate, Last_Contact_Date__c, CreatedById, CreatedBy.Name,
                Description, Provider__c, Provider__r.Name, Patient__c, Patient__r.Name, Status, Num_of_QA_Cycles__c,
                Request__c, Request__r.Conduit__c, Request_Completed__c
            FROM Task
            WHERE RecordTypeId =: ADMRecordType
            AND Location__c =: locationId
            AND (Request__r.ADM_Request_Completed__c = true OR isUrgent__c = true)
            AND Status != 'Completed' AND Status != 'Closed'
            ORDER BY CreatedDate DESC]);
        List<TaskItem> taskItemList = new List<TaskItem>();
        for(Task theTask : theADMTaskList) {
            TaskItem item = new TaskItem(theTask);
            taskItemList.add(item);
        }
        System.debug('taskItemList: ' + taskItemList);
        return taskItemList;
    }

    /*
    *   Takes the task ID for a call log and Returns record details to display in the Call Log Detail Modal
    **/
    @RemoteAction
    public static Task getCallLogModalDetails(String callLogId) {
        Task callLogDetails = [SELECT Call_Outcome__c, Call_Disposition__c, Description,
                Patient__r.Name, Status, Subject, Owner.Name, Location__r.Location_Name__c, Provider__c,
                Send_to_Manufacturer__c, Manufacturer__c
                FROM Task WHERE Id = :callLogId LIMIT 1];
        if(NULL == callLogDetails) return null;

        return callLogDetails;
    }

    // Returns a set of select options that contain Patient Id and Patient Name. Populates Patient select drop down on
    // the Location Detail page
    public List<SelectOption> getPatientList() {
        List<Task> taskList = [SELECT Id, WhatId, RecordTypeId, Request__c, Patient__c, Patient__r.Name FROM Task WHERE Location__c =: theLocation.Id and RecordTypeId =: ADMRecordType ORDER BY Patient__r.Name ASC];
        Set<SelectOption> options = new Set<SelectOption>();

        options.add(new SelectOption('', '--None--'));

        for (Task task : taskList){
            options.add(new SelectOption(task.Patient__c, task.Patient__r.Name));
        }

        return new List<SelectOption>(options);
    }

    // Save the call log
    //
    @RemoteAction
    public static String logCall(Id patientId, Boolean copyToPatientNotes, String description, Id locationId, String callDisposition, String callOutcome, Boolean sendToManufacturer, String manufacturer){
        List<Task> tasksToInsert = new List<Task>();


        //Get the Opportunity Id to put it as the WhatId
        List<Task> taskList = [SELECT Id, WhatId, RecordTypeId, Request__c, Patient__c, Patient__r.Name
            FROM Task
            WHERE Location__c =: locationId AND RecordTypeId =: ADMRecordType AND WhatId != :patientId
            ORDER BY Patient__r.Name ASC];

        map<Id, Id> patientToOppMap = new map<Id, Id>();
        map<Id, Id> patientToReqMap = new map<Id, Id>();
        for(Task t : taskList) {
            patientToOppMap.put(t.Patient__c, t.WhatId);
            patientToReqMap.put(t.Patient__c, t.Request__c);
        }


        System.debug('***** logCall(): Pt = ' + patientId + ', Copy to pt notes = ' + copyToPatientNotes + ', Notes = ' + description + ', thelocationId = ' + locationId);
        // Create a location task
        Task locationTask = new Task(
                WhatId = patientToOppMap.get(patientId)
                , Request__c = patientToReqMap.get(patientId)
                , ActivityDate = System.today()
                , Location__c = locationId
                , Status = 'Complete'
                , Subject = 'ADM Follow-up Note'
                , RecordTypeId = CallLogRecordType
                , Patient__c = patientId
                , Copy_to_Patient_Notes__c = copyToPatientNotes
                , Description = description
                , Call_Disposition__c = callDisposition
                , Call_Outcome__c = callOutcome
                , Send_to_Manufacturer__c = sendToManufacturer
                , Manufacturer__c = manufacturer
                , Send_to_Hub__c = true
        );

        tasksToInsert.add(locationTask);

        try{
            System.debug('*** logCall(): tasksToInsert = ' + tasksToInsert);
            INSERT tasksToInsert;
        } catch (DmlException e) {
            System.debug('*** EXCEPTION: ' + e);
            for (Task t : tasksToInsert){
                return e.getMessage();
            }
        }

        return 'Success';
    }

    /*
    *
    * Wrapper Classes to be used to populate tables
    *
    * */
    public class TaskItem {
        public String Id {get;set;}
        public String Name {get;set;}
        public String ProviderId {get;set;}
        public String ProviderName {get;set;}
        public String PatientId {get;set;}
        public String PatientName {get;set;}
        public String Status {get;set;}
        public String NumOfQACycles {get;set;}
        public String CreatedDate {get;set;}
        public String NeededDate {get;set;}
        public String LastContactDate {get;set;}
        public String Comments {get;set;}
        public String ConduitId {get;set;}
        public TaskItem(Task theTask) {
            this.Id = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theTask.Id;
            this.Name = theTask.Subject;
            this.ProviderId = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theTask.Provider__c;
            this.ProviderName = theTask.Provider__r.Name;
            this.PatientId = theTask.Patient__c;
            this.PatientName = theTask.Patient__r.Name;
            this.Status = theTask.Status;
            this.NumOfQACycles = String.valueOf(theTask.Num_of_QA_Cycles__c);
            this.CreatedDate = theTask.CreatedDate.date().format();
            this.NeededDate = theTask.ActivityDate != null ? theTask.ActivityDate.format() : '-';
            this.LastContactDate = theTask.Last_Contact_Date__c == null ? null : theTask.Last_Contact_Date__c.format();
            this.Comments = theTask.Description;
            this.ConduitId = theTask.Request__r.Conduit__c;
        }
//        public TaskItem() {}
    }
    public class CallLogItem {
        public String Id {get;set;}
        public String Subject {get;set;}
        public String CreatedDate {get;set;}
        public String CreatedBy {get;set;}
        public String CreatedById {get;set;}
        public String Comments {get;set;}
        public String CallDisposition {get;set;}
        public String CallOutcome {get;set;}
        public String PatientName {get;set;}
        public String PatientId {get;set;}

        public CallLogItem(Task theTask) {
            this.Id = theTask.Id;
            this.Subject = theTask.Subject;
            this.CreatedDate = theTask.CreatedDate.date().format();
            this.CreatedById = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theTask.CreatedById;
            this.CreatedBy = theTask.CreatedBy.Name;
            this.Comments = theTask.Description;
            this.CallDisposition = theTask.Call_Disposition__c;
            this.CallOutcome = theTask.Call_Outcome__c;
            this.PatientName = theTask.Patient__r.Name;
            this.PatientId = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theTask.Patient__c;
        }
//        public CallLogItem() {}
    }
    public class LocationRuleItem {
        public String Id {get;set;}
        public String ProviderRuleType {get;set;}
        public String Values {get;set;}
        public Boolean Required {get;set;}
        public LocationRuleItem(Location_Rule__c theRule) {
            this.Id = URL.getSalesforceBaseUrl().toExternalForm() + '/' + theRule.Id;
            this.ProviderRuleType = theRule.Provider_Rule_Type__c;
            this.Values = theRule.Value__c;
            this.Required = theRule.Required__c;
        }
//        public LocationRuleItem() {}
    }
}