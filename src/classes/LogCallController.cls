public with sharing class LogCallController {

    public Date followUpDate {get; set;}
    public Boolean isUrgent { get; set; }
    public String notes {get; set;}
    private final Opportunity mysObject;
    public Task theTask {get; set;}
    public List<RecordType> rTypes = new List<RecordType>();
    public Map<String, Id> rTypesMap = new Map<String, Id>();



    public LogCallController(ApexPages.StandardController stdController) {
        if(!Test.isRunningTest()) stdController.addFields(new String[] {'AccountId'});
        this.mysObject = (Opportunity)stdController.getRecord();


        List<Task> taskList = [Select ID From Task WHERE WhatId = :mysObject.Id LIMIT 1];
        System.debug('Did you get an ID? ' + taskList);
        populateRecordTypes();
        theTask = new Task();

        //#158608195/#158712250 add urgency to the Opp
        isUrgent = [SELECT Urgent__c FROM Opportunity WHERE Id =: mysObject.Id LIMIT 1].Urgent__c;
    }

    public List<SelectOption> getCallOutcomes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));

        Schema.DescribeFieldResult fieldResult =
                Task.Call_Outcome__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry f : ple)
        {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    public void populateRecordTypes() {
        rTypes = [SELECT Id, Name FROM RecordType where Sobjecttype='Task'];
        if (rTypes.size() > 0) {
            for(RecordType rt : rTypes) {
                rTypesMap.put(rt.Name, rt.Id);
            }
        }
        System.debug(rTypes);
        System.debug(rTypesMap);
    }


    public PageReference save()
    {
        System.debug('save() method trace');

        // validate that values are as they should be when logging a call
        
        if (followUpDate == null){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Follow Up Date cannot be blank'));
            return null;
        }
        if (followUpDate < System.today()){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Follow Up Date cannot be before ' + System.today().format()));
            return null;
        }
        if (mySobject.Call_Outcome__c == null || mySobject.Call_Outcome__c == '' || mySobject.Call_Disposition__c == null || mySobject.Call_Disposition__c == '') {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Please enter a valid Call Outcome & Call Disposition'));
            return null;
        }
        if (mysObject.Log_Type__c == null) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'You must specify a log type'));
            return null;
        }


        Id taskRecordType;


        if (rTypesMap.get(mySobject.Log_Type__c) != null) {
            taskRecordType = rTypesMap.get(mySobject.Log_Type__c);
        }
        System.debug('Log Type: ' + mysObject.Log_Type__c + 'taskRecordType: ' + taskRecordType);

        Task t = new Task();
        t.Subject = mySobject.Log_Type__c;
        t.Call_Outcome__c = mysObject.Call_Outcome__c;
        t.Call_Disposition__c = mysObject.Call_Disposition__c;
        t.Opportunity__c = mysObject.Id;
        t.WhatId = mysObject.AccountId;
        //t.Call_Category__c = mySobject.Category__c;
        t.Description = notes;
//        if(mySobject.Log_Type__c == 'Patient Note') {
//            Task t2 = new Task();
//            t2.Subject = 'Patient Note';
//            t2.Description = notes;
//            t2.whatId = mysObject.AccountId;
//            t2.Status = 'Completed';
//            insert t2;
//        }
//        t.whatId = mySobject.Id;
        t.Status = 'Completed'; //Is this supposed to be completed? I believe so since this is coming form the log call panel
        t.Follow_Up_Date__c = followUpDate;
        t.RecordTypeId = taskRecordType;
        t.Send_To_Manufacturer__c = mysObject.Send_To_Manufacturer__c;
        t.Manufacturer__c = mysObject.Manufacturer__c;
        t.Patient__c = mysObject.AccountId;
        t.Send_To_Hub__c = true;

        //#158608195/#158712250 add urgency to the Opp
        System.debug('LogCallController::: save:: isUrgent: ' + mysObject.Urgent__c);
        t.Urgent__c = mysObject.Urgent__c;
        UPDATE mysObject;

        System.debug('Task Info: ' + t);

        insert t;

        return null;
    }

    public PageReference foo(){
        return null;
    }

       

}