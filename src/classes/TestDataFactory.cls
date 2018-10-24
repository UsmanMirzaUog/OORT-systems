/**
 * Created by danielpulache on 10/30/17.
 */

global class TestDataFactory implements SandboxPostCopy {
    /*Static Variables*/
    public static List<Opportunity> opportunityList;
    public static Account patient;
    public static Provider__c provider;
    public static Address_Data__c address;
    public static Address_Data__c addressBilling;
    public static Address_Data__c addressShipping;
    public static List<Location__c> theLocationList;
    public static List<Request__c> requestListToInsert;

    /*Non Static Variables*/
    public Integer numberOfPatients {get;set;}
    public Integer numberOfProviders {get;set;}
    public Integer numberOfRequests {get;set;}
    public Integer numberOfPayors {get;set;}
    public List<Account> patientList {get;set;}
    public List<Opportunity> opportunityListNonStatic {get;set;}
    public List<Provider__c> providerList {get;set;}
    public List<Location__c> locationList {get;set;}
    public List<Request__c> requestList {get;set;}
    public List<Provider_Patient_Junction__c> patientProviderJunctionList {get;set;}
    public TestDataFactory() {
        numberOfPatients = 10;
        numberOfProviders = 10;
        numberOfPayors = 10;
        numberOfRequests = 3; //number of request determines the number of Locations
    }
    global void runApexClass(SandboxContext context) {
        createRealCustomSettings();
        createBiggerSampleSize();
    }
    public static void createAllCustomSettings() {
        createBrightTreeCustomSettings();
    }
    public static void createBrightTreeCustomSettings() {
        List<BrightTree__c> btList = new List<BrightTree__c>();
        btList.add(new BrightTree__c(Name = 'apiBaseUrl', Value__c = 'testString1'));
        btList.add(new BrightTree__c(Name = 'createPatientSalesOrder', Value__c = 'testString2'));
        btList.add(new BrightTree__c(Name = 'username', Value__c = 'testString3'));
        btList.add(new BrightTree__c(Name = 'password', Value__c = 'testString4'));
        btList.add(new BrightTree__c(Name = 'searchProviderByLastName', Value__c = 'teststring5'));
        btList.add(new BrightTree__c(Name = 'getStandardAddress', Value__c = 'teststring6'));
        btList.add(new BrightTree__c(Name = 'dexcomLeads', Value__c = 'teststring7'));
        btList.add(new BrightTree__c(Name = 'endpointGetPatient', Value__c = 'teststring8'));
        btList.add(new BrightTree__c(Name = 'createLead', Value__c = 'teststring9'));
        btList.add(new BrightTree__c(Name = 'leadService', Value__c = 'teststring10'));
        btList.add(new BrightTree__c(Name = 'updatePatientNote', Value__c = 'teststring11'));

        INSERT btList;
    }
    /*

        This method creates one patient with 3 opportunities

     */
    public static void create_Oppties_with_Patient() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        patient = new Account(FirstName = 'John', LastName = 'Smith', External_Id__c = '1234-5678', RecordTypeId = recordTypeId, BillingStreet = '123 Test Lane', BillingCity = 'San Diego', BillingState = 'CA', BillingPostalCode = '92111',
                ShippingStreet = '123 Test Lane', ShippingCity = 'San Diego', ShippingState = 'CA', ShippingPostalCode = '92111', Phone = '9876543210', Email__c = 'jsmith@testing.org', AccountNumber = '1000',
                Date_of_Birth__c = system.today().addYears(-35));
        INSERT patient;

        opportunityList = new List<Opportunity>();
        opportunityList.add(new Opportunity(Name = 'New Opportunity', CloseDate = Date.today().addDays(14), StageName = 'New', AccountId = patient.Id));
        opportunityList.add(new Opportunity(Name = 'Open Opportunity', CloseDate = Date.today().addDays(7), StageName = 'Open', AccountId = patient.Id));
        opportunityList.add(new Opportunity(Name = 'Closed Opportunity', CloseDate = Date.today(), StageName = 'Closed Won', AccountId = patient.Id));
        INSERT opportunityList;
        
     
        
    }
    /*

        After calling create_Oppties_with_Patient() call this method to create Payor, Provider, and Address with junction records related to Patient

     */
    public static void create_Address_Payor_Provider() {
        List<sObject> objectsToInsert = new List<sObject>();
        address = new Address_Data__c(Name = 'RevCult HQ', City__c = 'San Diego', State_Province__c = 'CA', Street__c = '123 Test Lane', Address_Line_2__c = 'Suite 205', Zip_Postal_Code__c = '92111', Primary__c = true, Account__c = patient.Id);
        addressBilling = new Address_Data__c(Name = 'Primary Billing Contact', City__c = 'San Diego', State_Province__c = 'CA', Street__c = '123 Test Lane', Address_Line_2__c = 'Suite 205', Zip_Postal_Code__c = '92111', Primary__c = true, Account__c = patient.Id);
        addressShipping = new Address_Data__c(Name = 'Primary Shipping Contact', City__c = 'San Diego', State_Province__c = 'CA', Street__c = '123 Test Lane', Address_Line_2__c = 'Suite 205', Zip_Postal_Code__c = '92111', Primary__c = true, Account__c = patient.Id);

        provider = new Provider__c(Name = 'Sheldon Cooper', Phone__c = '9254567896', Email__c = 'sheldon.cooper@revcult.com', Address__c = '789 SFDC Lane', Address2__c = 'Suite 100', City__c = 'San Francisco', State__c = 'CA', Zip__c = '94124');
        Insurance_Payor__c payor = new Insurance_Payor__c(Name = 'Blue Shield', Group_Name__c = 'The Bestest Group');
        objectsToInsert.add(address);
        objectsToInsert.add(provider);
        objectsToInsert.add(payor);
        INSERT objectsToInsert;

        objectsToInsert.clear();
//        objectsToInsert.add(new Address_Patient_Junction__c(Address_Data__c  = address.Id, Patient__c = patient.Id, Primary__c = true));
        objectsToInsert.add(new Provider_Patient_Junction__c(Provider__c = provider.Id, Patient__c = patient.Id, PCP__c = true));
        objectsToInsert.add(new Insurance_Patient_Junction__c(Insurance__c = payor.Id, Account__c = patient.Id));
        INSERT objectsToInsert;
    }
    /*

        After calling create_Oppties_with_Patient() call this method to create oppty line items

     */
    public static void create_OpptyLineItems() {
        Id pricebookId = Test.getStandardPricebookId();
        List<Product2> productList = new List<Product2>();
        productList.add(new Product2(Name = 'Product 1', ProductCode = '1', isActive = true));
        productList.add(new Product2(Name = 'Product 2', ProductCode = '2', isActive = true));
        productList.add(new Product2(Name = 'Product 3', ProductCode = '3', isActive = true));
        INSERT productList;

        List<PricebookEntry> pbEntry = new List<PricebookEntry>();
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(0).Id, UnitPrice = 100.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(1).Id, UnitPrice = 150.00, IsActive = true));
        pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(2).Id, UnitPrice = 250.00, IsActive = true));
        INSERT pbEntry;

        List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(0).Id, Quantity = 1, PricebookEntryId = pbEntry.get(0).Id, UnitPrice = pbEntry.get(0).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(0).Id, Quantity = 2, PricebookEntryId = pbEntry.get(1).Id, UnitPrice = pbEntry.get(1).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(1).Id, Quantity = 1, PricebookEntryId = pbEntry.get(1).Id, UnitPrice = pbEntry.get(1).UnitPrice));
        lineItemList.add(new OpportunityLineItem(OpportunityId = opportunityList.get(2).Id, Quantity = 1, PricebookEntryId = pbEntry.get(2).Id, UnitPrice = pbEntry.get(2).UnitPrice));
        INSERT lineItemList;
    }
    public static void create_Requests() {
        requestListToInsert = new List<Request__c>();
        Request__c r1 = new Request__c(Priority__c = '1 - New Customer', Opportunity__c = opportunityList[0].Id, Patient__c = patient.Id, Completed__c = true, Conduit__c = 'Test String 1', Name = 'Request 1');
        Request__c r2 = new Request__c(Priority__c = '2 - Billing', Opportunity__c = opportunityList[1].Id, Patient__c = patient.Id, Completed__c = false, Conduit__c = 'Test String 2', Name = 'Request 2');
        Request__c r3 = new Request__c(Priority__c = '3 - Reorder', Opportunity__c = opportunityList[2].Id, Patient__c = patient.Id, Completed__c = false, Conduit__c = 'Test String 3', Name =  'Request 3');
        requestListToInsert.add(r1);
        requestListToInsert.add(r2);
        requestListToInsert.add(r3);
        INSERT requestListToInsert;
    }
//    public static void create_LocationsWithTasks() {
    public static void create_Locations() {
        /*
        *   3 LOCATIONS
        * */
        theLocationList = new List<Location__c>();
        for (Integer i = 0; i < 2; i++) {
            Location__c theLocation = new Location__c(of_Medical_Group_Task_Set__c = 50 * i, Provider_Rules_Score__c = 'Strict', Priority__c = '1 - New Customer', Num_of_Patients__c = 5 * i,
                    Address_Line_1__c = String.valueOf(i) + ' Test Lane', Address_Line_2__c = 'Suite ' + String.valueOf(i) + '00', City__c = 'San Diego', State__c = 'CA', Zip_Code__c = '92111');
            theLocationList.add(theLocation);
        }
        Location__c theLocation = new Location__c(of_Medical_Group_Task_Set__c = 500, Provider_Rules_Score__c = 'Strict', Priority__c = '1 - New Customer', Num_of_Patients__c = 5,
                Address_Line_1__c = provider.Address__c, Address_Line_2__c = provider.Address2__c, City__c = provider.City__c, State__c = provider.State__c, Zip_Code__c = provider.Zip__c);
        theLocationList.add(theLocation);
        INSERT theLocationList;
    }
    /*

        Run create_Oppties_with_Patient(), create_Address_Payor_Provider(), create_Requests() first, in that order before calling this method


     */
//    public static void create_LocationTasks() {
    public static void create_LocationADMTasks() {
        List<Task> theTaskList = new List<Task>();
        /*
        *   ADM Tasks
        * */
        Task theTask = new Task();
        Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        for (Location__c theLocation : theLocationList) {
            for (Integer i = 0; i < 3; i++) {
                theTask = new Task(RecordTypeId = ADMRecordTypeId, Subject = 'Test ' + String.valueOf(i), Priority = 'Normal', Status = 'Not Started', ActivityDate = system.today().addDays(i),
                        Description = 'Description ' + String.valueOf(i), Provider__c = provider.Id, Patient__c = patient.Id, Num_of_QA_Cycles__c = i + 1, Request__c = requestListToInsert[i].Id);
                theTaskList.add(theTask);
            }
        }
        INSERT theTaskList;
    }
    public static void create_LocationCallLogActivities() {
        List<Task> theTaskList = new List<Task>();
        /*
        *   Call Logs Activities
        * */
        Id CallLogRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Log').getRecordTypeId();
        for(Location__c theLocation : theLocationList) {
            for(Integer i = 0 ; i < 3 ; i++) {
                Task theTask = new Task(RecordTypeId = CallLogRecordTypeId, WhatId = theLocation.Id, Subject = 'Test Subject' + String.valueOf(i), Priority = 'Normal', Status = 'Completed', Description = 'Test Description ' + String.valueOf(i),
                        Call_Disposition__c = 'Disposition ' + String.valueOf(i), Call_Outcome__c = 'Outcome ' + String.valueOf(i));
                theTaskList.add(theTask);
            }
        }
        INSERT theTaskList;
    }
    /*

        After calling create_LocationsWithTasks() call this method to create Location Rules

     */
    public static void create_LocationRules() {
        List<Location_Rule__c> theRuleList = new List<Location_Rule__c>();
        for(Location__c theLocation : theLocationList) {
            for(Integer i = 0 ; i < 3 ; i++) {
                Location_Rule__c theRule = new Location_Rule__c(Name = 'Name' + String.valueOf(i), Provider_Rule_Type__c = 'Rule Type ' + String.valueOf(i), Value__c = 'Value ' + String.valueOf(i), Required__c = true, Location__c = theLocationList[i].Id);
                theRuleList.add(theRule);
            }
        }
        INSERT theRuleList;
    }

    /*

        Run this method to create custom settings with real values

     */
    public void createRealCustomSettings() {
        delete [SELECT Id FROM BrightTree__c];
        List<BrightTree__c> btList = new List<BrightTree__c>();
        btList.add(new BrightTree__c(Name = 'apiBaseUrl', Value__c = 'http://13.64.71.110'));
        btList.add(new BrightTree__c(Name = 'createPatientSalesOrder', Value__c = '/api/Patient/updatePatientSalesOrderWithOptions'));
        btList.add(new BrightTree__c(Name = 'username', Value__c = 'SalesForceTest@mail.com'));
        btList.add(new BrightTree__c(Name = 'password', Value__c = 'abc123'));
        btList.add(new BrightTree__c(Name = 'searchProviderByLastName', Value__c = '/api/Patient/searchProviderByLastName'));
        btList.add(new BrightTree__c(Name = 'updatePatient', Value__c = '/api/Patient/updatePatient'));
        INSERT btList;
    }



    /*
    *
    *   Run this method to populate a bigger sample size in a sandbox environment
    *
    * */
    public void createBiggerSampleSize() {
        createPatients();
        createOpportunities();
        createProviders();
        createPayors();
        createRequests();
        createLocationRules();
    }
    public void createPatients() {
        Id recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Patients').getRecordTypeId();
        patientList = new List<Account>();
        for (Integer i = 1; i < numberOfPatients+1; i++) {
            patientList.add(new Account(FirstName = 'Patient', LastName = String.valueOf(i), RecordTypeId = recordTypeId));
        }
        INSERT patientList;
        List<Address_Data__c> addresses = new List<Address_Data__c>();
        for(Integer j = 0; j < patientList.size(); j++) {
            Integer i = j + 1;
            Account thePatient = patientList[j];
            addresses.add(new Address_Data__c(Name = 'Primary Address: ' + thePatient.FirstName + ' ' +thePatient.LastName, City__c = 'San Diego', State_Province__c = 'CA', Street__c = '12'+String.valueOf(i)+' Test Lane', Address_Line_2__c = 'Suite '+String.valueOf(i)+'05', Zip_Postal_Code__c = '92111', Primary__c = true, Account__c = thePatient.Id));
            addresses.add(new Address_Data__c(Name = 'Secondary Address: '+ thePatient.FirstName + ' ' +thePatient.LastName, City__c = 'San Diego', State_Province__c = 'CA', Street__c = '12'+String.valueOf(i)+' Exam Avenue', Address_Line_2__c = 'Suite '+String.valueOf(i)+'05', Zip_Postal_Code__c = '92111', Primary__c = false, Account__c = thePatient.Id));
        }
        INSERT addresses;
    }
    public void createOpportunities() {
        opportunityListNonStatic = new List<Opportunity>();
        for (Integer i = 1; i < numberOfPatients+1; i++) {
            Account thePatient = patientList[i-1];
            opportunityListNonStatic.add(new Opportunity(Name = 'New Opportunity: ' + thePatient.FirstName + ' ' +thePatient.LastName, CloseDate = Date.today().addDays(14), StageName = 'New', AccountId = thePatient.Id));
            opportunityListNonStatic.add(new Opportunity(Name = 'Open Opportunity: ' + thePatient.FirstName + ' ' +thePatient.LastName, CloseDate = Date.today().addDays(7), StageName = 'Open', AccountId = thePatient.Id));
            opportunityListNonStatic.add(new Opportunity(Name = 'Closed Opportunity: ' + thePatient.FirstName + ' ' +thePatient.LastName, CloseDate = Date.today(), StageName = 'Closed Won', AccountId = thePatient.Id));
        }
        INSERT opportunityListNonStatic;

        if(Test.isRunningTest()) {
            Id pricebookId = Test.getStandardPricebookId();
            List<Product2> productList = new List<Product2>();
            productList.add(new Product2(Name = 'Product 1', ProductCode = '1', isActive = true));
            productList.add(new Product2(Name = 'Product 2', ProductCode = '2', isActive = true));
            productList.add(new Product2(Name = 'Product 3', ProductCode = '3', isActive = true));
            INSERT productList;

            List<PricebookEntry> pbEntry = new List<PricebookEntry>();
            pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(0).Id, UnitPrice = 100.00, IsActive = true));
            pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(1).Id, UnitPrice = 150.00, IsActive = true));
            pbEntry.add(new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productList.get(2).Id, UnitPrice = 250.00, IsActive = true));
            INSERT pbEntry;

            List<OpportunityLineItem> lineItemList = new List<OpportunityLineItem>();
            for(Opportunity theOpp : opportunityListNonStatic) {
                lineItemList.add(new OpportunityLineItem(OpportunityId = theOpp.Id, Quantity = 1, PricebookEntryId = pbEntry.get(0).Id, TotalPrice = pbEntry.get(0).UnitPrice));
                lineItemList.add(new OpportunityLineItem(OpportunityId = theOpp.Id, Quantity = 1, PricebookEntryId = pbEntry.get(1).Id, TotalPrice = pbEntry.get(1).UnitPrice));
                lineItemList.add(new OpportunityLineItem(OpportunityId = theOpp.Id, Quantity = 1, PricebookEntryId = pbEntry.get(2).Id, TotalPrice = pbEntry.get(2).UnitPrice));
            }
            INSERT lineItemList;
        }
    }
    public void createProviders() {
        providerList = new List<Provider__c>();
        for (Integer i = 1; i < numberOfProviders+1; i++) {
            providerList.add(new Provider__c(Name = 'Provider '+String.valueOf(i), Phone__c = '925456789'+String.valueOf(i), Email__c = 'provider.'+String.valueOf(i)+'@revcult.com', Address__c = '78'+String.valueOf(i)+' SFDC Lane', Address2__c = 'Suite '+String.valueOf(i)+'00', City__c = 'San Francisco', State__c = 'CA', Zip__c = '94124'));
        }
        INSERT providerList;

        patientProviderJunctionList = new List<Provider_Patient_Junction__c>();
        for(Integer j = 0; j < patientList.size(); j++) {
            Account thePatient = patientList[j];
            Provider__c theProvider = providerList.size() - 1 > j ? providerList[j] : providerList[0];
            patientProviderJunctionList.add(new Provider_Patient_Junction__c(Provider__c = theProvider.Id, Patient__c = thePatient.Id, PCP__c = true));
        }
        INSERT patientProviderJunctionList;

    }
    public void createPayors() {
        List<Insurance_Payor__c> payorList = new List<Insurance_Payor__c>();
        for (Integer i = 1; i < numberOfPayors+1; i++) {
            payorList.add(new Insurance_Payor__c(Name = 'Payor ' +String.valueOf(i), Group_Name__c = 'Group '+String.valueOf(i)));
        }
        INSERT payorList;


        List<sObject> objectsToInsert = new List<sObject>();
        for(Integer j = 0; j < patientList.size(); j++) {
            Account thePatient = patientList[j];
            Insurance_Payor__c thePayor = payorList.size() - 1 > j ? payorList[j] : payorList[0];
            objectsToInsert.add(new Insurance_Patient_Junction__c(Insurance__c = thePayor.Id, Account__c = thePatient.Id));
        }
        INSERT objectsToInsert;
    }
    public void createRequests() {
        requestList = new List<Request__c>();
        for(Integer i = 1; i < numberOfRequests+1; i++) {
            Opportunity theOpp = opportunityListNonStatic.size() > i ? opportunityListNonStatic[i-1] : opportunityListNonStatic[0];
            Account thePatient = patientList.size() > i ? patientList[i-1] : patientList[0];
            requestList.add(new Request__c(Name = 'Request '+String.valueOf(i), Priority__c = '1 - New Customer', Opportunity__c = theOpp.Id, Patient__c = thePatient.Id, Completed__c = true, Conduit__c = 'Test String 1'));
        }
        INSERT requestList;
        Id ADMRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('ADM').getRecordTypeId();
        List<Task> theTaskList = new List<Task>();
        for(Integer i = 1; i < numberOfRequests+1; i++) {
            Request__c theRequest = requestList[i-1];
            Provider_Patient_Junction__c patientProviderJunction = patientProviderJunctionList.size() > i ? patientProviderJunctionList[i-1] : patientProviderJunctionList[0];
            theTaskList.add(new Task(RecordTypeId = ADMRecordTypeId, Subject = 'ADM Task 1', Priority = 'Normal', Status = 'Not Started', ActivityDate = system.today().addDays(i),
                    Description = 'Description 1', Provider__c = patientProviderJunction.Provider__c, Patient__c = patientProviderJunction.Patient__c, Num_of_QA_Cycles__c = 1, Request__c = theRequest.Id));

            theTaskList.add(new Task(RecordTypeId = ADMRecordTypeId, Subject = 'ADM Task 2', Priority = 'Normal', Status = 'Not Started', ActivityDate = system.today().addDays(i),
                    Description = 'Description 2', Provider__c = patientProviderJunction.Provider__c, Patient__c = patientProviderJunction.Patient__c, Num_of_QA_Cycles__c = 2, Request__c = theRequest.Id));

            theTaskList.add(new Task(RecordTypeId = ADMRecordTypeId, Subject = 'ADM Task 3', Priority = 'Normal', Status = 'Not Started', ActivityDate = system.today().addDays(i),
                    Description = 'Description 3', Provider__c = patientProviderJunction.Provider__c, Patient__c = patientProviderJunction.Patient__c, Num_of_QA_Cycles__c = 3, Request__c = theRequest.Id));
        }
        INSERT theTaskList; //inserting ADM tasks will create Locations
    }
    public static void createUrgentRequestItems() {
        User theOwner = [SELECT Id FROM User WHERE Name = 'Miguel Guillen' LIMIT 1];
        Account thePatient = [SELECT Id FROM Account LIMIT 1];
        Provider__c theProvider = [SELECT Id FROM Provider__c LIMIT 1];

        Task urgentRequest = new Task(
                isUrgent__c = true,
                OwnerId = theOwner.Id,
                WhatId = thePatient.Id,
                Subject = 'Call',
                Priority = '1 - New Customer',
                Status = 'Open',
                Provider__c = theProvider.Id,
                Urgent_Reason__c = 'Doctor Assistance'
        );
        INSERT urgentRequest;
    }
    public void createLocationRules() {
        locationList = [SELECT Id, Name FROM Location__c];
        List<Task> theTaskList = new List<Task>();
        List<Location_Rule__c> theLocationRuleList = new List<Location_Rule__c>();
        Id CallLogRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Call Log').getRecordTypeId();
        for(Location__c theLocation : locationList) {
            theTaskList.add(new Task(RecordTypeId = CallLogRecordTypeId, WhatId = theLocation.Id, Subject = 'Call Log 1', Priority = 'Normal', Status = 'Complete', Description = 'Test Description 1',
                    Call_Disposition__c = 'Disposition 1', Call_Outcome__c = 'Outcome 1'));
            theTaskList.add(new Task(RecordTypeId = CallLogRecordTypeId, WhatId = theLocation.Id, Subject = 'Call Log 2', Priority = 'Normal', Status = 'Complete', Description = 'Test Description 2',
                    Call_Disposition__c = 'Disposition 2', Call_Outcome__c = 'Outcome 2'));
            theTaskList.add(new Task(RecordTypeId = CallLogRecordTypeId, WhatId = theLocation.Id, Subject = 'Call Log 3', Priority = 'Normal', Status = 'Complete', Description = 'Test Description 3',
                    Call_Disposition__c = 'Disposition 3', Call_Outcome__c = 'Outcome 3'));
            for(Integer i = 1 ; i < 4 ; i++) {
                Location_Rule__c theRule = new Location_Rule__c(Name = 'Location Rule ' + String.valueOf(i), Provider_Rule_Type__c = 'Rule Type ' + String.valueOf(i), Value__c = 'Value ' + String.valueOf(i),
                        Required__c = true, Location__c = theLocation.Id);
                theLocationRuleList.add(theRule);
            }
        }
        INSERT theTaskList;
        INSERT theLocationRuleList;
    }
}