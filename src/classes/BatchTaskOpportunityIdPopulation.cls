/**
 * Created by krizia on 7/5/18.
 * Update existing Tasks that have a WhatId pointing to an Opportunity to have the Opportunity__c field populated
 */

global class BatchTaskOpportunityIdPopulation implements Database.Batchable<sObject> {


    String query;
    Set<Id> theTaskIds = new Set<Id>();

    global BatchTaskOpportunityIdPopulation(String theQuery) {
        query = theQuery;
        //query = 'SELECT Id, WhatId, Patient__c, Opportunity__c FROM Task';
    }

    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Task> scope) {
        for (Task t : scope) {
            //When the WhatId is an Opp, make it the Opportunity__c
            String theWhatId = String.valueOf(t.WhatId);
            if (theWhatId != '' && theWhatId != null) {
                System.debug('theWhatId: ' + theWhatId);
                if (theWhatId.startsWith('006')) {
                    System.debug('This is a Task with an Opportunity as the WhatId. ');
                    // get AccountId for Patient__c
                    Opportunity theOpp = [SELECT AccountId FROM Opportunity WHERE Id = :t.WhatId LIMIT 1];
                    t.Opportunity__c = t.WhatId; // 
                    t.Patient__c = theOpp.AccountId;
                    t.WhatId = theOpp.AccountId;
                }
            }
        }
        UPDATE scope;
    }

    global void finish(Database.BatchableContext BC) {

    }
}