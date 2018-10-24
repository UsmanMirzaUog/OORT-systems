/**
 * Created by krizia on 8/10/18.
 * DexcomFieldsModalController: 84%
 */

@isTest
private class DexcomFieldsModalController_TEST {

    @isTest private static void testController(){
        DexcomFieldsModalController dfmc = new DexcomFieldsModalController();

        Opportunity o = new Opportunity(
                Name = 'Test Opp',
                CloseDate = System.today().addDays(12),
                StageName = 'New'
        );
        INSERT o;

        Boolean success = DexcomFieldsModalController.saveOpp([SELECT Id FROM Opportunity LIMIT 1].Id, 12.31, 1994);
        System.assertEquals(true, success);
        System.assertEquals(12.31, [SELECT Estimated_Sensor_Cost__c FROM Opportunity WHERE Id =: o.Id LIMIT 1].Estimated_Sensor_Cost__c);
        System.assertEquals(1994, [SELECT Estimated_Start_Up_Cost__c FROM Opportunity WHERE Id =: o.Id LIMIT 1].Estimated_Start_Up_Cost__c);


        Boolean failure = DexcomFieldsModalController.saveOpp( null, 12.31, 1994);
        System.assertEquals(false, failure);
    }


}