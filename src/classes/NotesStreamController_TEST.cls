/**
 * Created by krizia on 6/18/18.
 * NotesStreamController: 94%
 */

@isTest
public class NotesStreamController_TEST {

    @isTest static void constructor_Test() {
        Account a = new Account(
                Name = 'Drover Buck'
        );
        INSERT a;
        Opportunity o = new Opportunity(
                AccountId = a.Id,
                Name = 'Max Attack',
                StageName = 'New Opportunity',
                CloseDate = System.today().addDays(20)
        );
        INSERT o;
        Task t = new Task(
                WhatId = o.Id,
                Patient__c = a.Id,
                Subject = 'Treat',
                Description = 'Throw me a bone.',
                Status = 'Completed'
        );
        INSERT t;

        PageReference ref = Page.Console_RightPanel;
        ref.getParameters().put('id', o.id);
        Test.setCurrentPage(ref);
        NotesStreamController con = new NotesStreamController();

        System.assert(a.Id == con.theAccountId);
        System.assert(1 == con.theTaskList.size());
    } //@isTest static void constructor_Test()


}