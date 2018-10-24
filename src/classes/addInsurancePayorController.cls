public with sharing class addInsurancePayorController {

    public Account patient {get; set;}
	public Opportunity oppty {get; set;}
//    public Date startDate { get; set; }
//    public Date endDate { get; set; }

    public class Data {
        public List<IPayor> payors;
        public List<PolicyLevel> policyLevels;
    }

    public class IPayor {
        public String name;
        public String id;
        public String groupName;
        public String displayId;

        public IPayor(Insurance_Payor__c p) {
            this.name = p.Name;
            this.id = p.Id;
            this.groupName = p.Group_Name__c;
        }
    }

    public class PolicyLevel {
        public String label;
        public String value;

        public PolicyLevel(Schema.PicklistEntry p) {
            this.label = p.getLabel();
            this.value = p.getValue();
        }
    }

    @RemoteAction
    public static Data getData() {
        Data d = new Data();
        d.payors = getPayors();
        d.policyLevels = getPolicyLevels();
        return d;
    }

    @RemoteAction
    public static Boolean savePayor(Id payorId, String payorType, Id patientId, String startDate, String endDate) {
        System.debug('addInsurancePayorController::: savePayor:: entering method: payorId-' + payorId + ' -- payorType-' + payorType + ' -- patientId-' + patientId + ' -- startDate-' + startDate + ' -- endDate-' + endDate);

        //Throw an error if someone tries to add historical data
        Boolean showError = false;
        List<Insurance_Patient_Junction__c> ipjList = new List<Insurance_Patient_Junction__c>([SELECT Id, Start_Date__c, Policy_Level__c FROM Insurance_Patient_Junction__c WHERE Account__c =: patientId AND Policy_Level__c =: payorType]);
        System.debug(ipjList);
        if (startDate != null && startDate != '') {
            for (Insurance_Patient_Junction__c ipj : ipjList) {
                if ((ipj.Start_Date__c.addDays(1)) > Date.valueOf(startDate)) {
                    showError = true;
                }
            }
        }

        //ApexPage messages are not actually showing up, but returning false is all we need.
        if (startDate == null || startDate == '') {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Please include a Start Date for this policy.'));
            System.debug('addInsurancePayorController::: savePayor:: start date missing');
            return false;
        }
        else if (showError == true) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, 'Please do not add an old Policy.'));
            System.debug('addInsurancePayorController::: savePayor:: old policy');
            return false;
        }
        else {
            System.debug('addInsurancePayorController::: savePayor:: startDate: ' + startDate);
            Insurance_Patient_Junction__c ipj = new Insurance_Patient_Junction__c(
                    Account__c = patientId,
                    Insurance__c = payorId,
                    Policy_Level__c = payorType,
                    Start_Date__c = Date.valueOf(startDate)
            );
            INSERT ipj;
            System.debug('addInsurancePayorController::: savePayor:: successful IPJ insert');
            if (endDate != null && endDate != '' && endDate != ' ') {
                System.debug('addInsurancePayorController::: savePayor:: endDate: ' + endDate);
                ipj.End_Date__c = Date.valueOf(endDate);
                System.debug('addInsurancePayorController::: savePayor:: ipj.End_Date__c: ' + ipj.End_Date__c);
                UPDATE ipj;
                System.debug('addInsurancePayorController::: savePayor:: successful IPJ update');
            }
            return true;
        }
    }

    private static List<IPayor> getPayors() {
        List<IPayor> payors = new List<IPayor>();
        for (Insurance_Payor__c payor : [SELECT Id, Name, Group_Name__c FROM Insurance_Payor__C]) {
            payors.add(new IPayor(payor));
        }
        return payors;
    }

    private static List<PolicyLevel> getPolicyLevels() {
        List<PolicyLevel> policyLevels = new List<PolicyLevel>();
        for (Schema.PicklistEntry val : Insurance_Patient_Junction__c.Policy_Level__c.getDescribe().getPicklistValues()) {
            policyLevels.add(new PolicyLevel(val));
        }
        return policyLevels;
    }

}