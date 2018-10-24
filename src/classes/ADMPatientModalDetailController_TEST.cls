/**
 * Created by krizia on 6/18/18.
 * ADMPatientModalDetailModalController: 95%
 */
@isTest
public class ADMPatientModalDetailController_TEST {


    @isTest static void full_Test() {
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

//        ADMPatientModalDetailModalController con = new ADMPatientModalDetailModalController();
        Account a2 = ADMPatientModalDetailModalController.getPatient(a.Id);
        System.assert(a2.Id == a.Id);
        List<ADMPatientModalDetailModalController.TaskWithTime> twt = ADMPatientModalDetailModalController.getNotesStream(a.Id);
        System.assert(twt.size() == 1);

        Insurance_Patient_Junction__c ipj = ADMPatientModalDetailModalController.getPrimaryInsurance(a.Id);
        Insurance_Patient_Junction__c ipj2 = ADMPatientModalDetailModalController.getSecondaryInsurance(a.Id);
        System.assert(ipj == null);
        System.assert(ipj2 == null);
    } //@isTest static void full_Test()



}