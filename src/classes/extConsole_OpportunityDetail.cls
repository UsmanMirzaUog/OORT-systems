/**
 * Created by isaac on 8/30/17.
 */

public with sharing class extConsole_OpportunityDetail {
    public Boolean isSharedDexcom {get; set;}
    public Boolean isDexOpp { get; set; }
    public Boolean showPage {get; set;}
    public Opportunity myOpportunity {get; set;}
    public Opportunity myOpportunityDetails {get; set;}
    public List<OpportunityLineItem> opportunityProductList {get; set;}
    public List<OpportunityLineItem> openOpportunityList {get; set;}
    public List<OpportunityLineItem> salesHistoryList {get; set;}
    public List<Task> opportunityNotes {get; set;}
    public transient List<String> patientNotesSorted {get; set;}
    public transient Map<String, Task> patientNotesItems {get; set;}
    private List<Task> patientNotes {get; set;}
    public Id accountId {get; set;}
    public String toUnselect {get; set;}
    
    public static String salesorderid{get; set;}
    public string OppNotes{get; set;}
    public string OppNotes1{get; set;}
        
    public Decimal opportunityAmount {get; set;}
    public static Id PatientNoteRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Patient Note').getRecordTypeId();

    private opportunityLineItem[] forDeletion = new opportunityLineItem[]{};
    
    public class solaramedicalsuppliesWrp {
        public DateTime RequestedDate{get; set;}
        public string SalesOrderHubID{get; set;}
        public string SF_OppID{get; set;}
        public string Notes{get; set;}
        public string RequestedByUserName{get; set;}
    }
    
    public static List<solaramedicalsuppliesWrp> solaramedicalsupList{get; set;}

    public extConsole_OpportunityDetail(ApexPages.StandardController stdController){
        patientNotesSorted = new List<String>();
        patientNotesItems = new Map<String, Task>();
        showPage = true;

        solaramedicalsupList = new List<solaramedicalsuppliesWrp>();

        List<String> fields = new List<String> { 'AccountId' };
        if (!Test.isRunningTest()) {
            stdController.addFields(fields);
            myOpportunity = (Opportunity) stdController.getRecord();
            if (myOpportunity.AccountId == null) showPage = false;
        } else {
            myOpportunity = (Opportunity) stdController.getRecord();
        }

        System.debug('opp = ' + myOpportunity);

        if (showPage == true) {
            myOpportunityDetails = [SELECT Id, Name, AccountId, Account.Name, External_Id__c,Notes__c, OwnerId, Owner.Name, Account.PersonEmail, Account.PersonMobilePhone , Account.PersonHomePhone , Account.Preferred_Name__pc, Account.Preferred_Communication__pc,
                    Account.BillingStreet  , Account.BillingCity, Account.BillingState , Account.BillingPostalCode, Account.PersonBirthdate,
                    Account.ShippingStreet, Account.shippingCity, Account.ShippingState, Account.ShippingPostalCode, Account.FirstName, Account.LastName,
                    Account.Primary_Contact__c, Account.Responsible_Party__c, Account.Gender__pc, Account.Active__pc, Account.IsPersonAccount, Pricebook2Id,
                    CloseDate, Amount, Opportunity.StageName, Status__c, BrightTree_Order_Id__c, Urgent__c, Urgent_Reason__c, Estimated_Sensor_Cost__c, Estimated_Start_Up_Cost__c, Dexcom_Opp_Id__c
            FROM Opportunity WHERE Id = :myOpportunity.Id limit 1];
            accountId = myOpportunityDetails.AccountId;
    
                
            opportunityProductList = [SELECT Id, Name, Description, ListPrice, OpportunityId,
                    Product2Id, ProductCode, Quantity, UnitPrice, Subtotal, TotalPrice,
                    Rx_Status__c, DocX_Status__c, DocY_Status__c, Documentation_Status__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :myOpportunityDetails.Id];

            openOpportunityList = [SELECT Id, Name, Description, ListPrice, OpportunityId,
                    Product2Id, ProductCode, Quantity, UnitPrice, Subtotal, TotalPrice,
                    Rx_Status__c, DocX_Status__c, DocY_Status__c, Documentation_Status__c, Opportunity.Owner.Name
            FROM OpportunityLineItem
            WHERE Opportunity.AccountId = :AccountId
            AND Opportunity.StageName != 'Closed Won'
            AND OpportunityId != :myOpportunityDetails.Id];

            salesHistoryList = [SELECT Id, Name, Description, ListPrice, OpportunityId,
                    Product2Id, ProductCode, Quantity, UnitPrice, Subtotal, TotalPrice,
                    Rx_Status__c, DocX_Status__c, DocY_Status__c, Documentation_Status__c,
                    Opportunity.Owner.Name, Opportunity.CloseDate
            FROM OpportunityLineItem
            WHERE Opportunity.AccountId = :AccountId
            AND Opportunity.StageName = 'Closed Won'];

            opportunityNotes = [SELECT Id, Subject, CreatedDate, Call_Outcome__c,
                    Call_Disposition__c, Owner.Name, Description
            FROM Task
            WHERE WhatId =: myOpportunity.AccountId
            ORDER BY CreatedDate DESC];

            //patientNotes = [SELECT Id, Subject, CreatedDate, Call_Outcome__c, ActivityDate,
            //        Call_Disposition__c, Owner.Name, Description
            //FROM Task
            //WHERE Patient__c =: myOpportunityDetails.AccountId
            //AND (RecordTypeId = :PatientNoteRecordTypeId OR Copy_to_Patient_Notes__c = true)
            //ORDER BY CreatedDate DESC];

            //System.debug('****** pt notes: ' + patientNotes);

            //for(Task theTask : patientNotes) {
            //    patientNotesSorted.add(theTask.CreatedDate.format());
            //    patientNotesItems.put(theTask.CreatedDate.format(), theTask);
            //}

            //reverseOrderOfDatetimes(patientNotesSorted);
            //System.debug('***** ptnotes (sorted): ' + patientNotesSorted);

            updateOpportunityAmount();
            isSharedDexcom = checkDexcomShareStatus(myOpportunityDetails.Id);

            //#158712246 only display button if Dexcom opp
            if (myOpportunityDetails.Dexcom_Opp_Id__c != null) {
                isDexOpp = true;
            }
            else {
                isDexOpp = false;
            }
        }

    }

    public static Boolean checkDexcomShareStatus(Id oppId) {

        Boolean isItShared = false;
        List<PartnerNetworkRecordConnection> checkOpp = new List<PartnerNetworkRecordConnection>();
        checkOpp = [SELECT Id FROM PartnerNetworkRecordConnection WHERE LocalRecordId = :oppId];
        if (checkOpp.size() == 0) {
            isItShared = false;
        } else {
            isItShared = true;
        }

        return isItShared;
    }

    public void updateAvailableList() {

        // We dynamically build a query string and exclude items already in the shopping cart
        opportunityProductList = [SELECT Id, Name, Description, ListPrice, OpportunityId,
                Product2Id, ProductCode, Quantity, UnitPrice, Subtotal, TotalPrice,
                Rx_Status__c, DocX_Status__c, DocY_Status__c, Documentation_Status__c
        FROM OpportunityLineItem
        WHERE OpportunityId = :myOpportunity.Id];

    }

    public void saveOppLineItems() {
        update opportunityProductList;
    }

    public void updateOpportunityAmount() {
        this.opportunityAmount = 0.00;
        for(OpportunityLineItem theOpportunityProduct : opportunityProductList) {
            this.opportunityAmount += theOpportunityProduct.TotalPrice;
        }
    }

    public PageReference removeFromShoppingCart(){

        // This function runs when a user hits "remove" on an item in the "Selected Products" section
        Integer count = 0;

        for(opportunityLineItem d : opportunityProductList){
            if((String)d.Id==toUnselect){
                if(d.Id!=null)
                    forDeletion.add(d);

                opportunityProductList.remove(count);
                break;
            }
            count++;
        }

        try{
            delete forDeletion;
        } catch (Exception e) {
            System.debug('Exception deleting Product: ' + e);
        }
        forDeletion.clear();

        updateAvailableList();
        updateOpportunityAmount();

        return null;
    }
    
    public List<Datetime> reverseOrderOfDatetimes(List<Datetime> theDatetimes){
        List<Datetime> reOrderedDatetimes = new List<Datetime>();
        for(Integer i = theDatetimes.size() -1 ; i >= 0 ; i--) {
            reOrderedDatetimes.add(theDatetimes[i]);
        }
        return reOrderedDatetimes;
    }
    public List<String> reverseOrderOfDatetimes(List<String> theDatetimes){
        List<Datetime> theActualDateTimes = new List<Datetime>();
        List<String> theOrderedDateTimes = new List<String>();
        for(String theDateTime : theDatetimes) {
            Datetime dt = Datetime.parse(theDateTime);
            theActualDateTimes.add(dt);
        }
        theActualDateTimes.sort();
        theActualDateTimes = reverseOrderOfDatetimes(theActualDateTimes);
        for(Datetime theDT : theActualDateTimes) {
            String stringDT = theDT.format();
            theOrderedDateTimes.add(stringDT);
        }
        return theOrderedDateTimes;
    }

    public PageReference save() {
        update myOpportunity;
        
        PageReference myVFPage = new PageReference('/apex/Console_OpportunityDetail');
        myVFPage.setRedirect(true);
        myVFPage.getParameters().put('Id', myOpportunity.Id);
        return myVFPage;
    }
    
    
    public PageReference saveDocSetRequest(){
        //myOpportunity.Create_DocSet__c = false;
        //myOpportunity.API_Called__c = true;
        myOpportunity.Notes__c = OppNotes1;
        update myOpportunity;
        
        PageReference myVFPage = new PageReference('/apex/Console_OpportunityDetail');
        myVFPage.setRedirect(true);
        myVFPage.getParameters().put('Id', myOpportunity.Id);
        return myVFPage;
    }
    
    public PageReference createDocSetRequest(){
        //myOpportunity.Create_DocSet__c = true;
        //myOpportunity.API_Called__c = false;
        //myOpportunity.Notes__c = OppNotes;
        //update myOpportunity;  
        
        if(myOpportunityDetails.External_Id__c != null && myOpportunityDetails.External_Id__c != '')
        extConsole_OpportunityDetail.docSetCreateRequest(myOpportunity.Id, myOpportunityDetails.External_Id__c, OppNotes); 

        PageReference myVFPage = new PageReference('/apex/Console_OpportunityDetail');
        myVFPage.setRedirect(true);
        myVFPage.getParameters().put('Id', myOpportunity.Id);
        return myVFPage;
    }
    
         
    @future (callout=true)
    public static void docSetRequest(){
        
        //Construct HTTP request and response
        //Http request method,Endpoint and setBody
        HttpRequest req = new HttpRequest();
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', Label.Solar_Authorization);
        String endpoint = Label.Solar_GetDocSetRequest+extConsole_OpportunityDetail.salesorderid;
        req.setMethod('GET');
        req.setEndpoint(endpoint); 
        //SOQL to construct JSON string in set body
        //Http response method 
        Http http = new Http();
        HTTPResponse res;
        list<extConsole_OpportunityDetail.solaramedicalsuppliesWrp> responceSt = new list<extConsole_OpportunityDetail.solaramedicalsuppliesWrp>();
        if(!Test.isRunningTest()){
            res = http.send(req);
            string bodyContent = res.getBody();
           
            
            if(bodyContent != '"Record not found!"'){
            
             system.debug('Body JSOn+'+res.getBody());
            responceSt = (list<extConsole_OpportunityDetail.solaramedicalsuppliesWrp>)System.JSON.deserialize(bodyContent, list<extConsole_OpportunityDetail.solaramedicalsuppliesWrp>.class);
            }
        }
        list<extConsole_OpportunityDetail.solaramedicalsuppliesWrp> responceSt1 = new list<extConsole_OpportunityDetail.solaramedicalsuppliesWrp>();
        
        if(responceSt.size()>0)
        for(Integer i=responceSt.size()-1; i>=0;i--){
            responceSt1.add(responceSt.get(i));
        }
        
        extConsole_OpportunityDetail.solaramedicalsupList = responceSt1;
    }
    
    
    public class solaramedicalsupWrp {
        public string SalesOrderHubID{get; set;}
        public string SF_OppID{get; set;}
        public string Notes{get; set;}
        public string RequestedByUserName{get; set;}
    }
    
    @future (callout=true)
    public static void docSetCreateRequest(string oppId, string exhubId, string notes) {
        extConsole_OpportunityDetail.solaramedicalsupWrp  solarSupObj = new extConsole_OpportunityDetail.solaramedicalsupWrp();
        solarSupObj.SalesOrderHubID = exhubId;
        solarSupObj.SF_OppID = oppId;
        solarSupObj.Notes = notes;
        solarSupObj.RequestedByUserName = UserInfo.getName();
    
        //Construct HTTP request and response
        //Http request method,Endpoint and setBody
        HttpRequest req = new HttpRequest();
        req.setHeader('Content-Type','application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('Authorization', Label.Solar_Authorization);
        
        String endpoint = Label.Solar_CreateDocSetRequest;
        req.setMethod('POST');
        req.setEndpoint(endpoint); 
        //SOQL to construct JSON string in set body
        //string cc= '{ "SalesOrderHubID": "'+exhubId+'",  "SF_OppID": '+oppId+',  "Notes": "'+notes+'",  "RequestedByUserName": "'+UserInfo.getName()+'" }';
        String JsonString=JSON.serialize(solarSupObj);
        req.setBody(JsonString);
        //Http response method 
        Http http = new Http();
        if(!Test.isRunningTest())
        HTTPResponse res = http.send(req);
    }
    
}