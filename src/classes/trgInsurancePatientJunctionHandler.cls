/**
 * Created by krizia on 8/1/18.
 */

public class trgInsurancePatientJunctionHandler {
    private static List<Insurance_Patient_Junction__c> triggerNew;
    private static List<Insurance_Patient_Junction__c> triggerOld;
    private static Map<Id, Insurance_Patient_Junction__c> triggerNewMap;
    private static Map<Id, Insurance_Patient_Junction__c> triggerOldMap;
    private static Boolean hasProcessed = false;
    private static List<Insurance_Patient_Junction__c> updateIPJs;


    public trgInsurancePatientJunctionHandler() {

    }


    //#158045121 only one active IPJ per level (Primary/Secondary/Tertiary)
    public static void checkActiveStatus(List<Insurance_Patient_Junction__c> trigNew, Map<Id, Insurance_Patient_Junction__c> trigNewMap){
        System.debug('trgInsurancePatientJunctionHandler::: checkActiveStatus:: hasProcessed: ' + hasProcessed);

   //     if (hasProcessed == false) {
            triggerNewMap = trigNewMap;
            updateIPJs = new List<Insurance_Patient_Junction__c>();

            Set<Id> trigIds = new Set<Id>();
            for (Insurance_Patient_Junction__c ipj : trigNew) {
                trigIds.add(ipj.Id);
            }

            //Get the Patients in order to query for all of their IPJs for comparison
            Set<Id> thePatientIds = new Set<Id>();
            for (Insurance_Patient_Junction__c ipj : trigNew) {
                thePatientIds.add(ipj.Account__c);
            }

            //Get all of each Patient's IPJs to make sure they do not overlap in dates
            Map<Id, List<Insurance_Patient_Junction__c>> patientToIPJmap = new Map<Id, List<Insurance_Patient_Junction__c>>();
            List<Insurance_Patient_Junction__c> allRelatedIPJs = new List<Insurance_Patient_Junction__c>([SELECT Id, Account__c, Insurance__c, Start_Date__c, End_Date__c, Policy_Level__c FROM Insurance_Patient_Junction__c WHERE Account__c IN :thePatientIds ORDER BY Start_Date__c DESC]);
            System.debug('trgInsurancePatientJunctionHandler::: checkActiveStatus:: allRelatedIPJs: ');
            System.debug(allRelatedIPJs);
            for (Insurance_Patient_Junction__c ipj : allRelatedIPJs) {
                List<Insurance_Patient_Junction__c> theIPJs = new List<Insurance_Patient_Junction__c>();
                if (patientToIPJmap.containsKey(ipj.Account__c)) {
                    theIPJs = patientToIPJmap.get(ipj.Account__c);
                }
                theIPJs.add(ipj);
                patientToIPJmap.put(ipj.Account__c, theIPJs);
            }

            //Send to the next method in order to validate only one active Insurance per Level - one Patient at a time
            for (Id patient : patientToIPJmap.keySet()) {
                compareLevels(patientToIPJmap.get(patient));
            }
            hasProcessed = true;
            if (!updateIPJs.isEmpty()) UPDATE updateIPJs;
  //      }
    } //public static void checkActiveStatus(List<Insurance_Patient_Junction__c> trigNew)


    public static void compareLevels(List<Insurance_Patient_Junction__c> theIPJs){
        System.debug('trgInsurancePatientJunctionHandler::: compareLevels:: theIPJs');
        System.debug(theIPJs);

        //Split into levels for separate comparisons
        List<Insurance_Patient_Junction__c> primaries = new List<Insurance_Patient_Junction__c>();
        List<Insurance_Patient_Junction__c> secondaries = new List<Insurance_Patient_Junction__c>();
        List<Insurance_Patient_Junction__c> tertiaries = new List<Insurance_Patient_Junction__c>();

        for (Insurance_Patient_Junction__c ipj : theIPJs) {
            if (ipj.Policy_Level__c == 'Primary') primaries.add(ipj);
            else if (ipj.Policy_Level__c == 'Secondary') secondaries.add(ipj);
            else tertiaries.add(ipj);
        }

        //Now that they are in their levels, compare dates
        if (!primaries.isEmpty()) compareDates(primaries);
        if (!secondaries.isEmpty()) compareDates(secondaries);
        if (!tertiaries.isEmpty()) compareDates(tertiaries);
    } //public static void compareLevels(List<Insurance_Patient_Junction__c> theIPJs)


    public static void compareDates(List<Insurance_Patient_Junction__c> theIPJs) {
        System.debug('trgInsurancePatientJunctionHandler::: compareDates:: theIPJs:');
        System.debug(theIPJs);
        Date newStart;

        //Check for the overlapping/triggering IPJ from theIPJs and triggerNewMap
        for (Insurance_Patient_Junction__c ipj : theIPJs) {
            if (triggerNewMap.containsKey(ipj.Id)) {
                newStart = ipj.Start_Date__c;
            }
        }
        System.debug('trgInsurancePatientJunctionHandler::: compareDates:: newStart: ' + newStart);

        //when inserting a new IPJ, close previous one
        if (newStart != null) {
            for (Insurance_Patient_Junction__c ipj : theIPJs) {
                System.debug(ipj.Start_Date__c);
                System.debug(ipj.End_Date__c);
                if (!triggerNewMap.containsKey(ipj.Id) && (ipj.End_Date__c >= newStart || ipj.End_Date__c == null) && ipj.Start_Date__c < newStart) {
                    ipj.End_Date__c = newStart.addDays(-1);
                    System.debug(ipj);
                    updateIPJs.add(ipj);
                }
            }
        }
    } //public static void compareDates(List<Insurance_Patient_Junction__c> theIPJs)
}