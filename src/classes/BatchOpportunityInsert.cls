/**
 * Created by krizia on 8/10/18.
 */

global class BatchOpportunityInsert implements Database.Batchable<sObject>, Database.allowsCallouts {


    String query;
    Integer batchsize = 1;
    Set<Id> oppIds = new Set<Id>();


    global BatchOpportunityInsert() {}


    global BatchOpportunityInsert(Set<Id> recordIds) {

        oppIds = recordIds;

        query = 'SELECT Id, Opportunity_Notes__c, Close_Reason__c, Doc_1_Status__c, Doc_2_Status__c, Doc_3_Status__c, Doc_4_Status__c, Doc_5_Status__c, Doc_6_Status__c, Estimated_Sensor_Cost__c, Estimated_Start_Up_Cost__c, Next_Follow_Up_Date__c, Last_Note_Created_Date__c, Name, Opportunity_Owner_Name__c, Dexcom_Opportunity_Type__c, Patient_DOB__c, Dexcom_Primary__c, Dexcom_Secondary__c, Dexcom_Patient_Home_Phone__c, Dexcom_Doctor__c, Doc_1_Type__c, Doc_2_Type__c, Doc_3_Type__c, Doc_4_Type__c, Doc_5_Type__c, Doc_6_Type__c, StageName, Status__c, Dexcom_Opp_Id__c, Dexcom_Patient_Mobile_Phone__c, Dexcom_Patient_Ship_To_Address__c, Dexcom_Patient_Email__c, Dexcom_Gender__c, Dexcom_Account_Number__c FROM Opportunity WHERE Id IN :oppIds';

    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Opportunity> scope) {
        System.debug('Opportunity list size: ' + scope.size());


        for (Opportunity o : scope){
            if (o.Dexcom_Opp_Id__c != null && o.Dexcom_Opp_Id__c != '') {
                trgOpportunityHandler.dexcomLeadWrapper dexWrap = new trgOpportunityHandler.dexcomLeadWrapper(o);
                String theJson = JSON.serialize(dexWrap, true);
                system.debug(theJson);
                callHub('dexcomLeads','POST',theJson);
            }
        }
    }

    public void callHub(String serviceCustomSettingName, String verbMethod, String theJson){
        Map<String, String> optionsMap = SolaraHubIntegration.createOptionsMap(serviceCustomSettingName, verbMethod);

        HttpRequest req = SolaraHubIntegration.createHttpRequest(optionsMap, thejson);
        HttpResponse res = SolaraHubIntegration.sendHttpRequest(req);

        if (res != null && res.getStatusCode() != 200  && (!Test.isRunningTest())) {
            Utils.logIntegrationIssue(thejson, 'Status: ' + res.getStatusCode() + ': ' + res.getStatus() + '<br><br>' + res.getBody(), serviceCustomSettingName);
        }
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('BatchOpportunityInsert::: finish:: ');
    }


}