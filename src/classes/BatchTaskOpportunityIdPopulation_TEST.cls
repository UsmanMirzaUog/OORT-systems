/**
 * Created by krizia on 7/5/18.
 * BatchTaskOpportunityIdPopulation: 100%
 */

@isTest
public class BatchTaskOpportunityIdPopulation_TEST {


    @testSetup public static void SetUpData() {
        Opportunity o = new Opportunity(
                Name = 'My Opp',
                StageName = 'New Opportunity',
                CloseDate = System.today()
        );
        INSERT o;
    }

    @isTest public static void positiveTest(){
        Task t = new Task(
                WhatId = [SELECT Id FROM Opportunity LIMIT 1].Id,
                Subject = 'Opportunity as WhatId',
                Description = 'This will get updated.',
                Status = 'Open'
        );
        INSERT t;

        Test.startTest();
        BatchTaskOpportunityIdPopulation handler = new BatchTaskOpportunityIdPopulation('SELECT Id, WhatId, Patient__c, Opportunity__c FROM Task');
        Database.executeBatch(handler);
        Test.stopTest();

        Task t2 = [SELECT Id, Opportunity__c FROM Task LIMIT 1];
        Opportunity o = [SELECT Id FROM Opportunity LIMIT 1];
        System.assertEquals(o.Id, t2.Opportunity__c);
    }

    @isTest public static void negativeTest(){
        Task t = new Task(
                Subject = 'Account as WhatId',
                Description = 'This will not get updated.',
                Status = 'Open'
        );
        INSERT t;

        Test.startTest();
        BatchTaskOpportunityIdPopulation handler = new BatchTaskOpportunityIdPopulation('SELECT Id, WhatId, Patient__c, Opportunity__c FROM Task');
        Database.executeBatch(handler);
        Test.stopTest();

        Task t2 = [SELECT Id, Opportunity__c, WhatId FROM Task LIMIT 1];
        System.assertEquals(null, t2.WhatId);
        System.assertEquals(null, t2.Opportunity__c);
    }
}