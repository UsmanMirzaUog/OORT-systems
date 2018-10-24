/**
 * Created by krizia on 8/10/18.
 */

public with sharing class DexcomFieldsModalController {

    public Account patient {get; set;}
    public Opportunity oppty {get; set;}

    public DexcomFieldsModalController(){
        System.debug('DexcomFieldsModalController::: ');
    }

    @RemoteAction
    public static Boolean saveOpp(Id oppId, Decimal estimatedSensorCost, Decimal estimatedStartUpCost){
        System.debug('DexcomFieldsModalController:: saveOpp:: estimatedSensorCost: ' + estimatedSensorCost);
        System.debug('DexcomFieldsModalController:: saveOpp:: estimatedStartUpCost: ' + estimatedStartUpCost);
        try {
            Opportunity o = new Opportunity();
            o = [SELECT Id, Name, Estimated_Sensor_Cost__c, Estimated_Start_Up_Cost__c FROM Opportunity WHERE Id =: oppId LIMIT 1];
            System.debug(o);
            o.Estimated_Sensor_Cost__c = estimatedSensorCost;
            o.Estimated_Start_Up_Cost__c = estimatedStartUpCost;
            UPDATE o;
            System.debug(o);

            return true;
        } catch (Exception e){
            System.debug(e);
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
            return false;
        }
    } //public static Boolean saveOpp(String estimatedSensorCost, String estimatedStartUpCost)

}