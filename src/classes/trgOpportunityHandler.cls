public class trgOpportunityHandler { //KHB removed with sharing
    private List<Opportunity> triggerNew;
    private List<Opportunity> triggerOld;
    private Map<Id, Opportunity> triggerNewMap;
    private Map<Id, Opportunity> triggerOldMap;
    public static Id personAccountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
    private final static String NewStageName = 'New Opportunity';
    public static Id ADMTaskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();


    public trgOpportunityHandler(List<Opportunity> triggerNew,
            List<Opportunity> triggerOld,
            Map<Id, Opportunity> triggerNewMap,
            Map<Id, Opportunity> triggerOldMap) {
        this.triggerNew = triggerNew;
        this.triggerOld = triggerOld;
        this.triggerNewMap = triggerNewMap;
        this.triggerOldMap = triggerOldMap;
    }


    //#157528613 Create Dexcom note on Opportunity as Task
    public void createDexcomNoteTask(){
        List<Task> newTasks = new List<Task>();
        Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Opp_Note' LIMIT 1].Id;

        for (Opportunity o : triggerNew) {
            if (o.Dexcom_Opp_Id__c != null && o.Dexcom_Opportunity_Notes__c != null) {
                if (o.Dexcom_Opportunity_Notes__c != ''){
                    Task t = new Task(
                    //        WhatId = o.Id,
                            WhatId = o.AccountId,
                            Opportunity__c = o.Id,
                            Patient__c = o.AccountId,
                            Subject = 'Dexcom Notes',
                            Description = o.Dexcom_Opportunity_Notes__c,
                         //   RecordTypeId = oppRecordTypeId,
                            Status = 'Completed'
                    );
                    newTasks.add(t);
                }
            }
        }

        if (newTasks.size() > 0) {
            INSERT newTasks;
        }
    } //public void createDexcomNoteTask()


    //#157528620 Updated Dexcom note on Opportunity as new Task without previously recorded Body
    public void updateDexcomNoteTask(List<Opportunity> triggerNew1, Map<Id, Opportunity> triggerOldMap1){
        List<Task> newTasks = new List<Task>();
        Id oppRecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Opp_Note' LIMIT 1].Id;


        System.debug(triggerNew1);
        //Create new Tasks without the information from old ones
        for (Opportunity o : triggerNew1) {
            System.debug(o);
            if (o.Dexcom_Opp_Id__c != null && o.Dexcom_Opportunity_Notes__c != null) {
                System.debug('1');
                System.debug(o.Dexcom_Opportunity_Notes__c);
                System.debug(triggerOldMap1.get(o.Id).Dexcom_Opportunity_Notes__c);
                if (o.Dexcom_Opportunity_Notes__c != triggerOldMap1.get(o.Id).Dexcom_Opportunity_Notes__c){
                    System.debug('2');
                    //Create new Tasks for those that did not already have a Dexcom Task
                    if (triggerOldMap1.get(o.Id).Dexcom_Opportunity_Notes__c != null){
                        System.debug('3');
                        String newDescription = o.Dexcom_Opportunity_Notes__c.remove(triggerOldMap1.get(o.Id).Dexcom_Opportunity_Notes__c);
                        System.debug(newDescription);
                        Task t2 = new Task(
                         //       WhatId = o.Id,
                                WhatId = o.AccountId,
                                Opportunity__c = o.Id,
                                Subject = 'Dexcom Notes (Update)',
                                Description = newDescription,
                                Patient__c = o.AccountId,
                           //     RecordTypeId = oppRecordTypeId,
                                Status = 'Completed'
                        );
                        System.debug(t2);
                        newTasks.add(t2);
                    } else {
                        System.debug('4');
                        Task t = new Task(
                         //       WhatId = o.Id,
                                WhatId = o.AccountId,
                                Opportunity__c = o.Id,
                                Subject = 'Dexcom Notes',
                                Description = o.Dexcom_Opportunity_Notes__c,
                           //     RecordTypeId = oppRecordTypeId,
                                Status = 'Completed',
                                Patient__c = o.AccountId
                        );
                        System.debug(t);
                        newTasks.add(t);
                    }
                } else if (triggerOldMap1.get(o.Id).Dexcom_Opportunity_Notes__c == null || triggerOldMap1.get(o.Id).Dexcom_Opportunity_Notes__c == '') {
                    System.debug('5');
                    Task t = new Task(
                    //        WhatId = o.Id,
                            WhatId = o.AccountId,
                            Opportunity__c = o.Id,
                            Subject = 'Dexcom Notes',
                            Description = o.Dexcom_Opportunity_Notes__c,
                            //     RecordTypeId = oppRecordTypeId,
                            Status = 'Completed',
                            Patient__c = o.AccountId
                    );
                    System.debug(t);
                    newTasks.add(t);
                }
            }
        }

        if (newTasks.size() > 0) {
            System.debug(newTasks);
            INSERT newTasks;
        }
    } //public void updateDexcomNoteTask()
    
    public void assignStandardPriceBook(List<Opportunity> triggerNew){

        Id pbookId;


        List<Pricebook2> pbList = [SELECT Id FROM PriceBook2 WHERE IsStandard = true LIMIT 1];
        
        if (pbList.size() > 0) pbookId = pbList[0].Id;

        if (Test.isRunningTest() == true) {
            pbookId = Test.getStandardPricebookId();
        }

        for(Opportunity newOppty : triggerNew){
     
            if(pbookId != null){
                newOppty.PriceBook2Id = pbookId;
                system.debug (newOppty);
                
            }
        }
           
    }

    public void sendDexcomLeadToHub(List<Opportunity> triggerNew) {
    /*#159667190 call out from batch class to prevent future call errors
        for (Opportunity o : triggerNew) {
            if (o.Dexcom_Opp_Id__c != null && o.Dexcom_Opp_Id__c != '') {
                dexcomLeadWrapper dexWrap = new dexcomLeadWrapper(o);
                String theJson = JSON.serialize(dexWrap, true);
                system.debug(theJson);
                SolaraHubIntegration.callHubService('dexcomLeads','POST',theJson);
            }
        }
    */

        Set<Id> oppIds = new Set<Id>();
        for (Opportunity o : triggerNew) {
            if (o.Dexcom_Opp_Id__c != null && o.Dexcom_Opp_Id__c != '') {
                oppIds.add(o.Id);
            }
        }

        System.debug('trgOpportunityHandler::: sendDexcomLeadToHub:: call BatchOpportunityInsert');
        BatchOpportunityInsert boi = new BatchOpportunityInsert(oppIds);
        Database.executeBatch(boi, 1);
    }

    public void getOppOwnerId(List<Opportunity> triggerNew, Map<Id, Opportunity> triggerOldMap, Boolean isUpdate, Boolean isInsert) {


        Set<String> lastNameSet = new Set<String>();
        Set<String> firstNameSet = new Set<String>();
        Set<String> fullNameSet = new Set<String>();
        List<Opportunity>  oppsToAssign = new List<Opportunity>();
        Map<String, Opportunity> nameOppMap = new Map<String, Opportunity>();
        Map<String, String> oppIdToFullName = new Map<String, String>();
        Boolean processAssignment = true;

        for (Opportunity o : triggerNew) {


        // the scenarios we want to handle
        // assignment on insert
        // assignment on update when the OwnerId field changed
        // assignment on update when 

        // non assignment on update when the OwnerId field didn't change

        system.debug ('isUpdate ::: ' + isUpdate);
        system.debug ('isInsert ::: ' + isInsert);
        system.debug ('triggerOldMap' + triggerOldMap);
        //system.debug ('triggerOldMap OwnerId' + triggerOldMap.get(o.Id).OwnerId);
        system.debug ('o dot ownerId' + o.OwnerId);

            if(isInsert == true) {
                processAssignment = true;
            } else if (o.Dont_Process_Assignment__c  == true) {
                processAssignment = false;
            } else if (isUpdate && triggerOldMap != null && triggerOldMap.get(o.Id).OwnerId != o.OwnerId) {
                processAssignment = false;
            } else if (isUpdate && triggerOldMap != null && triggerOldMap.get(o.Id).Order_Owner__c != o.Order_Owner__c) {
                processAssignment = true;
            } else if (isUpdate && triggerOldMap != null && triggerOldMap.get(o.Id).OwnerId == o.OwnerId) {
                processAssignment = false;
            }

            if(processAssignment == true) {
                oppsToassign.add(o);
            }

        }

        system.debug (oppsToAssign);

        for (Opportunity o : oppsToAssign) {

            String ordOwner = o.Order_Owner__c;
            String firstName = ordOwner != null ? ordOwner.substringAfter(',') : '';
            String lastName = ordOwner != null ? ordOwner.substringBefore(',') : '';
            firstname = firstName != null ? firstName.trim() : '';
            lastName = lastName != null ? lastName.trim() : '';
            String fullName = firstName + ' ' + lastName;
            fullNameSet.add(fullName);

            oppIdToFullName.put(o.Order_Owner__c, fullName);
            nameOppMap.put(fullName, o);                                
            
        }

        List<User> matchingOwners = [SELECT Name, Id FROM User WHERE Name IN :fullNameSet AND isActive = true];

        for(Opportunity o : nameOppMap.values()) {
            system.debug('innameoppmap');
            String curFullName = oppIdToFullName.get(o.Order_Owner__c);

            for(User u : matchingOwners) {
                if(u.Name == curFullName) {
                    o.OwnerId = u.Id;
                }     
            } 
        }
        
    }

    public static String createDexcomLeadJSON(Opportunity oppty) {


            dexcomLeadWrapper dexWrap = new dexcomLeadWrapper(oppty);
            String theJson = JSON.serialize(dexWrap, true);
            system.debug(theJson);
            return theJson;

        }


    public void createADMDocs(List<Opportunity> newTrigger, Map<Id, Opportunity> oldTriggerMap) {
        System.debug('****** createADMDocs start...');
        System.debug('****** newTrigger...' + newTrigger);
        System.debug('****** oldTriggerMap...' + oldTriggerMap);
        List<Request__c> requestList = new List<Request__c>();
        List<Task> docTask = new List<Task>();

        Set<Id> patientIdSet = new Set<Id>();
        for (Opportunity o : newTrigger) {
            if(o.AccountId != null) patientIdSet.add(o.AccountId); // Get set of Patient Account Ids
        }

        // Map of Providers
        List<Provider_Patient_Junction__c> providerPatientList = New List<Provider_Patient_Junction__c>([SELECT Patient__c, Provider__c FROM Provider_Patient_Junction__c WHERE Patient__c IN : patientIdSet]);
        Map<Id, List<Id>> patientIdToProviderIdListMap = new Map<Id, List<Id>>();

        Id oldPatientId = null;
        for (Provider_Patient_Junction__c ppj : providerPatientList) {
            if (ppj.Patient__c == oldPatientId) {
                patientIdToProviderIdListMap.get(ppj.Patient__c).add(ppj.Provider__c);
            } else {
                patientIdToProviderIdListMap.put(ppj.Patient__c, new List<Id>());
                patientIdToProviderIdListMap.get(ppj.Patient__c).add(ppj.Provider__c);
                oldPatientId = ppj.Patient__c;
            }
        }



        //#158949214 Find Primary Insurance payor bucket
        List<Insurance_Patient_Junction__c> insurancePatientJunctionList = new List<Insurance_Patient_Junction__c>([SELECT Id, Account__c, Insurance__c, Insurance__r.Payor_Bucket__c, Payor_Bucket__c FROM Insurance_Patient_Junction__c WHERE Account__c IN :patientIdSet AND Policy_Level__c = 'Primary']);
        Map<Id, String> patientIdToPayorBucket = new Map<Id, String>();
        for (Insurance_Patient_Junction__c ipj : insurancePatientJunctionList){
            patientIdToPayorBucket.put(ipj.Account__c, ipj.Insurance__r.Payor_Bucket__c);
        }
        List<Group> publicGroups = new List<Group>([SELECT Id, Name FROM Group]);
        Map<String, Group> publicGroupsMap = new Map<String, Group>();
        for (Group g : publicGroups){
            publicGroupsMap.put(g.Name, g);
        }


        for(Opportunity o : newTrigger) {
            System.debug('****** pt = ' + o.Name + ', Old = ' + oldTriggerMap.get(o.id).Status__c + ', New = ' + o.Status__c);
            if((oldTriggerMap.get(o.id).Status__c != 'Documentation Needed') && (o.Status__c == 'Documentation Needed')) {
                System.debug('****** createADMDocs - Documentation Needed ******');
                System.debug('****** Opportunity for patient: ' + o.Account.Name);

                // Get the Provider Address for the Location key


                // Create a request and tasks
                if (o.AccountId != null) {
                    // TODO add logic to catch only ILMS opps if necessary

                    // Create Request
                    Request__c r = new Request__c();
                    r.OwnerId = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1].Id;
                    r.Patient__c = o.AccountId;
                    r.Opportunity__c = o.Id;
                    r.Priority__c = '1 - Customer';
                    //#158949214 associate with Primary Insurance
                    if (publicGroupsMap.containsKey(patientIdToPayorBucket.get(o.AccountId))) {
                        r.Payor_Bucket__c = patientIdToPayorBucket.get(o.AccountId);
                    }
                    requestList.add(r);
                    insert requestList;

                    //Create Task
                    Task t = new Task();
                    //t.WhatId = o.Id;
                    t.WhatId = o.AccountId;
                    t.Opportunity__c = o.Id;
                    t.Subject = 'ADM Documents Created';
                    t.RecordTypeId = ADMTaskRecordTypeId;
                    t.Patient__c = o.AccountId;
                    t.Description = '[' + String.valueOf(System.now()) + '] - Document Request Task Created - System';
                    System.debug(t.Description);
                    if (patientIdToProviderIdListMap.containsKey(o.AccountId)) {
                        t.Provider__c = patientIdToProviderIdListMap.get(o.AccountId)[0];
                    }
                    t.Status = 'Open';
                    t.Request__c = r.Id;
                    //#158949214 associate with Primary Insurance
                    if (r.Payor_Bucket__c != null) t.Payor_Bucket__c = r.Payor_Bucket__c;
                    docTask.add(t);
                    insert docTask;
                }
            }
        }
//        if (requestList.size() > 0) insert requestList;
//        if (docTask.size() > 0) insert docTask;
        System.debug(requestList);
        System.debug(docTask);

        // TODO what tasks to create for follow up queue?
    }
    
    public void assignDexcomFields(List<Opportunity> triggerNew) {

        Set<Id> patientIdSet = new Set<Id>();
        Set<Id> oppIdSet = new Set<Id>();
        Set<String> statusSet = new Set<String>();

        for (Opportunity o : triggerNew) {
            if (o.Dexcom_Opp_Id__c != '' && o.Dexcom_Opp_Id__c != null) {
                system.debug('dexcom opp id not null in for loop!');
                if(o.AccountId != null) patientIdSet.add(o.AccountId);
                oppIdSet.add(o.Id);   
                statusSet.add(o.Status__c);               
            }
        }

        system.debug('patientIdset ::: ' + patientIdSet);
        system.debug('oppIdSet ::: ' + oppIdSet);
        system.debug('statusSet ::: ' + statusSet);

        if(patientIdSet.size() != 0) {
            system.debug ('patient ID set larger than 0');

            Map<String, String> statusToCloseReasonMap = new Map<String, String>();
            Map<Id, Account> patientMap = new Map<Id, Account>([SELECT Id, FirstName, LastName FROM Account WHERE RecordTypeId = :personAccountRecordTypeId AND Id IN :patientIdSet]);
            Map<Id, Provider__c> providerMap = new Map<Id, Provider__c>([SELECT Id, Name, Address__c, Address2__c, NPI__c, Phone__c, Fax__c, State__c, ZIP__c, City__c, (SELECT Patient__c FROM Provider_Patient_Junction__r) FROM Provider__c WHERE Id IN (SELECT Provider__c FROM Provider_Patient_Junction__c WHERE PCP__c = true AND Patient__c IN : patientIdSet)]);
            //Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>([SELECT Id, Name, Owner.Name, LeadSource FROM Opportunity WHERE Id IN : opportunityIdSet]);
            Map<Id, Provider__c> patientToPCPMap = new Map<Id, Provider__c>();
            Map<Id, Task> patientTaskMap = new Map<Id, Task>([SELECT Id, Opportunity__c, WhatId, Send_To_Manufacturer__c, Subject, Patient__c, Description, RecordType.Name, CreatedDate FROM Task WHERE (Opportunity__c IN :oppIdSet OR WhatId IN :oppIdSet) AND Subject != 'Dexcom Notes' AND Subject != 'Dexcom Notes (Update)' AND Subject != 'Opportunity Note' ORDER BY CreatedDate DESC]);
            Map<Id, List<Task>> patientToTaskMap = new  Map<Id, List<Task>>();
            List<Insurance_Patient_Junction__c> patientInsuranceList = [SELECT Id, Name, Policy_Level__c, Insurance__r.Name, Policy_Id__c, Account__c FROM Insurance_Patient_Junction__c WHERE Account__c IN :patientIdSet];
            Map<Id, List<Insurance_Patient_Junction__c>> patientToInsuranceMap = new  Map<Id, List<Insurance_Patient_Junction__c>>();

            List<Close_Reason__c> closeReasons = [SELECT Stage__c, Status__c, Close_Reason__c FROM Close_Reason__c WHERE Status__c IN :statusSet];

            system.debug ('close reasons ::: ' + closeReasons);

            for (Close_Reason__c cr : closeReasons) {
                statusToCloseReasonMap.put(cr.Status__c, cr.Close_Reason__c);
            }

            system.debug ('close reason :: statusToCloseReasonMap ::: ' + statusToCloseReasonMap);


            
            system.debug(patientTaskMap);
            
            for(Task t : patientTaskMap.values()) {
                system.debug ('current task:::: ' + t);
                if (patientToTaskMap.containsKey(t.Patient__c) && t.Patient__c != null) {
                    system.debug ('contained key for what ID, adding to list');
                    patientToTaskMap.get(t.Patient__c).add(t);

                } else if (!patientToTaskMap.containsKey(t.Patient__c) && t.Patient__c != null) {
                    system.debug ('didnt find key, adding it to map::');
                    List<Task> taskList = new List<Task>();
                    taskList.add(t);
                    system.debug ('added task to task list::: '+ taskList);
                    patientToTaskMap.put(t.Patient__c, taskList);
                }    
            }

            system.debug ('patient TO task map:::' + patientToTaskMap);


            for(Insurance_Patient_Junction__c ipj : patientInsuranceList) {
                if(patientToInsuranceMap.containsKey(ipj.Account__c)) {
                    patientToInsuranceMap.get(ipj.Account__c).add(ipj);
                } else {
                    List<Insurance_Patient_Junction__c> insuranceList = new List<Insurance_Patient_Junction__c>();
                    insuranceList.add(ipj);
                    patientToInsuranceMap.put(ipj.Account__c, insuranceList);
                }
            }

            system.debug (patientToInsuranceMap);
     
            for(Provider__c theProvider : providerMap.values()) {
                Id theCurrentPatientId = theProvider.Provider_Patient_Junction__r[0].Patient__c;
                patientToPCPMap.put(theCurrentPatientId,theProvider);
            }

            List<Opportunity> oppUpdateList = new List<Opportunity>();

            for (Opportunity o : triggerNew) {

                Opportunity opp = new Opportunity();
                opp.Id = o.Id;
                String docString = '';

                if (patientToPCPMap.get(o.AccountId) != null) {
                    if (patientToPCPMap.get(o.AccountId).Name != null) {
                        docString = patientToPCPMap.get(o.AccountId).Name;
                    }
                    if (patientToPCPMap.get(o.AccountId).Address__c != null) {
                        docString = docString + ' - ' + patientToPCPMap.get(o.AccountId).Address__c;
                    }
                    if (patientToPCPMap.get(o.AccountId).Address2__c != null) {
                        docString = docString + ' ' +  patientToPCPMap.get(o.AccountId).Address2__c;
                    }
                    if (patientToPCPMap.get(o.AccountId).City__c != null) {
                        docString = docString + ' ' + patientToPCPMap.get(o.AccountId).City__c;
                    }
                    if (patientToPCPMap.get(o.AccountId).State__c != null) {
                        docString = docString + ' ' +  patientToPCPMap.get(o.AccountId).State__c;
                    }
                    if (patientToPCPMap.get(o.AccountId).Zip__c != null) {
                        docString = docString + ' ' +  patientToPCPMap.get(o.AccountId).Zip__c;
                    }
                    if (patientToPCPMap.get(o.AccountId).NPI__c != null) {
                        docString = docString + ' - NPI:' +  patientToPCPMap.get(o.AccountId).NPI__c;
                    }
                    if (patientToPCPMap.get(o.AccountId).Phone__c != null) {
                        docString = docString + ' - Ph:[' +  patientToPCPMap.get(o.AccountId).Phone__c + ']';
                    }
                    if (patientToPCPMap.get(o.AccountId).Fax__C != null) {
                        docString = docString + ' - FX:[' +  patientToPCPMap.get(o.AccountId).Fax__c + ']';
                    }


                    system.debug (docString);

                    opp.Dexcom_Doctor__c = docString;

      
                }   

                String oppNotesCombined = '';
                String taskSubject = '';
                String taskDescription = '';
                String taskDate = '';

                system.debug ('patient task map' + patientToTaskMap);

                if(patientToTaskMap.get(o.AccountId) != null) {   
                    List<Task> patientTasks = patientToTaskMap.get(o.AccountId);
                    System.debug(patientTasks);

                    Integer theCount = 0;
                    for(Task t : patientTasks) {
                        System.debug(t);
                        taskSubject = t.Subject == null ? '' : t.Subject;
                        taskDescription = t.Description == null ? '' : t.Description;
                        taskDate = t.CreatedDate.format();
                        if (theCount == 0) {

                            oppNotesCombined = 'Date: ' + taskDate + '\n' + 'Subject: ' + taskSubject + '\n' + 'Description: ' + taskDescription + '\n' + 'Record Type: ' + t.RecordType.Name;
                            theCount = theCount + 1;
                        } else if (theCount > 0) {
                            oppNotesCombined = oppNotesCombined + '\n\n' + 'Date: ' + taskDate + '\n' + 'Subject: ' + taskSubject + '\n' + 'Description: ' + taskDescription+ '\n' + 'Record Type: ' + t.RecordType.Name;
                        }
                    }
                }

                opp.Opportunity_Notes__c = oppNotesCombined;
                System.debug(opp.Opportunity_Notes__c);
                oppNotesCombined = '';

                String dexPrimary = '';
                String dexSecondary = '';
                if(patientToInsuranceMap.get(o.AccountId) != null) {
                    system.debug ('insurance map not null');
                    List<Insurance_Patient_Junction__c> patientInsurance = patientToInsuranceMap.get(o.AccountId);

                    Integer theCount = 0;
                    for(Insurance_Patient_Junction__c pi : patientInsurance) {
                        if(pi.Policy_Level__c == 'Primary') {
                            dexPrimary = pi.Insurance__r.Name + ' - ID:[' + pi.Policy_Id__c + ']';
                        } else if(pi.Policy_Level__c == 'Secondary') {
                            dexSecondary = pi.Insurance__r.Name + ' - ID:[' + pi.Policy_Id__c + ']';
                        }
                    }                      
                }

                opp.Dexcom_Primary__c = dexPrimary;
                opp.Dexcom_Secondary__c = dexSecondary;

                system.debug ('close reason opp status ::: '  + o.Status__c);

                if (statusToCloseReasonMap.containsKey(o.Status__c) == true) {
                    system.debug('should have wrote a close reason');
                    opp.Close_Reason__c = statusToCloseReasonMap.get(o.Status__c);
                }                


                dexPrimary = '';
                dexSecondary = '';

                oppUpdateList.add(opp);
                system.debug ('just added::: ' + opp);

            }

            if (oppUpdateList.size() > 0) update oppUpdateList;
            system.debug ('should have just updated opps with size of list ' + oppUpdateList.size());
        }
    }



    //#158712198 Opp closing
    public void closeLosingOpp(List<Opportunity> newOpps, Map<Id, Opportunity> triggerOldMap) {
        //Identify the Opportunities that are now Close Losing
        Set<Id> closedOppIds = new Set<Id>();
        for (Opportunity o : newOpps) {
            System.debug('o.StageName: ' + o.StageName);
            System.debug('triggerOldMap.get(o.Id).StageName: ' + triggerOldMap.get(o.Id).StageName);
            if (o.StageName == 'Closed Lost' && triggerOldMap.get(o.Id).StageName != o.StageName){
                closedOppIds.add(o.Id);
            }
        }

        //Change Tracker Note status from Open to Closed [BT or SF?]


        //VOID the SO [BT via the Hub?]


        //Close out related Requests
        List<Request__c> theRequests = new List<Request__c>([SELECT Id, Completed__c, Opportunity__c FROM Request__c WHERE Opportunity__c IN: closedOppIds]);
        System.debug(theRequests);
        for (Request__c r : theRequests) {
            r.Completed__c = true;
        }
        if (!theRequests.isEmpty()) { UPDATE theRequests; }

        //Close Out any related Tasks [Status from Open to Closed]
        List<Task> theTasks = new List<Task>([SELECT Id, WhatId, Status, Opportunity__c, Follow_Up_Date__c FROM Task WHERE Opportunity__c IN: closedOppIds OR WhatId IN: closedOppIds]);
        System.debug(theTasks);
        for (Task t : theTasks) {
            t.Status = 'Closed';
            t.Follow_Up_Date__c = null;
        }
        if (!theTasks.isEmpty()) { UPDATE theTasks; }
    } //public void closeLosingOpp(List<Opportunity> triggerNew)


    public class dexcomLeadWrapper {

        public String DistributorActivityNotes {get; set;}
        public String CloseReason {get; set;}
        public String Document1 {get; set;}
        public String Document2 {get; set;}
        public String Document3 {get; set;}
        public String Document4 {get; set;}
        public String Document5 {get; set;}
        public String Document6 {get; set;}
        public Integer EstimatedSensorCost {get; set;}
        public Integer EstimatedStartUpCost {get; set;}
        public Date FollowUpDate {get; set;}
        public Date LastActivityDate {get; set;}
        public String Name {get; set;}
        public String OpportunityOwnerC {get; set;}
        public String OpportunityType {get; set;}
        public Date PatientDOB {get; set;}
        public String Payer1C {get; set;}
        public String Payer2C {get; set;}
        public String Payer3C {get; set;}
        public String HomePhone {get; set;}
        public String PhysicianC {get; set;}
        public String ReqDoc1 {get; set;}
        public String ReqDoc2 {get; set;}
        public String ReqDoc3 {get; set;}
        public String ReqDoc4 {get; set;}
        public String ReqDoc5 {get; set;}
        public String ReqDoc6 {get; set;}
        public String Stage {get; set;}
        public String Status {get; set;}
        public String DistCreatedDate {get; set;}
        public String DistOppID {get; set;}
        public String MobilePhone {get; set;}
        public String DistOppShipToAddress {get; set;}
        public String Email {get; set;}
        public String Gender {get; set;}
        public String DistOppBillToAddress {get; set;}
        public String SFOppID {get; set;}
        public String DistAccountNumber {get; set;}

        public dexcomLeadWrapper(Opportunity o) {
            this.DistributorActivityNotes = o.Opportunity_Notes__c;
            this.CloseReason = o.Close_Reason__c;
            this.Document1 = o.Doc_1_Status__c;
            this.Document2 = o.Doc_2_Status__c;
            this.Document3 = o.Doc_3_Status__c;
            this.Document4 = o.Doc_4_Status__c;
            this.Document5 = o.Doc_5_Status__c;
            this.Document6 = o.Doc_6_Status__c;
            this.EstimatedSensorCost = o.Estimated_Sensor_Cost__c == null ? 0 : Integer.valueOf(o.Estimated_Sensor_Cost__c);
            this.EstimatedStartUpCost = o.Estimated_Start_Up_Cost__c == null ? 0 : Integer.valueOf(o.Estimated_Start_Up_Cost__c);
            this.FollowUpDate = o.Next_Follow_Up_Date__c;
            this.LastActivityDate = o.Last_Note_Created_Date__c;
            this.Name = o.Name;
            this.OpportunityOwnerC = o.Opportunity_Owner_Name__c;
            this.OpportunityType = o.Dexcom_Opportunity_Type__c;
            this.PatientDOB = o.Patient_DOB__c == null ? Date.newInstance(1800, 01, 01) : o.Patient_DOB__c;
            this.Payer1C = o.Dexcom_Primary__c;
            this.Payer2C = o.Dexcom_Secondary__c;
            this.Payer3C = o.Dexcom_Secondary__c;
            this.HomePhone = o.Dexcom_Patient_Home_Phone__c;
            this.PhysicianC = o.Dexcom_Doctor__c;
            this.ReqDoc1 = o.Doc_1_Type__c;
            this.ReqDoc2 = o.Doc_2_Type__c;
            this.ReqDoc3 = o.Doc_3_Type__c;
            this.ReqDoc4 = o.Doc_4_Type__c;
            this.ReqDoc5 = o.Doc_5_Type__c;
            this.ReqDoc6 = o.Doc_6_Type__c;
            this.Stage = o.StageName;
            this.Status = o.Status__c;
            //this.DistCreatedDate = o.Dexcom_Dis
            this.DistOppID = o.Dexcom_Opp_Id__c;
            this.MobilePhone = o.Dexcom_Patient_Mobile_Phone__c;
            this.DistOppShipToAddress = o.Dexcom_Patient_Ship_To_Address__c;
            this.Email = o.Dexcom_Patient_Email__c;
            this.Gender = o.Dexcom_Gender__c;
            this.DistOppBillToAddress = o.Dexcom_Patient_Ship_To_Address__c;
            this.SFOppID = o.Id;
            this.DistAccountNumber = o.Dexcom_Account_Number__c;
        }
    }
}