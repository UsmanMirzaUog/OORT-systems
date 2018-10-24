public class Utils {

/**
 getSelectStarQueryForSobjectTypes

 - This will iterate over an objects fields to create a dynamic SELECT * query
*/

public static String getSelectStarQueryForSobjectType(String objectType) {
        SObjectType theType = Schema.getGlobalDescribe().get(objectType);
        String theQuery = 'SELECT Id';
        for (String fieldName : getFieldsForObjectType(theType)) {
            theQuery += ','+fieldName;
        }
        theQuery += ' FROM ' + theType;
        return theQuery;
    }

/**
 getSelectStarQueryForSobjectType

 - This will iterate over an objects fields to create a dynamic list of an objects fields
*/

    public static Set<String> getFieldsForObjectType(Schema.SObjectType theType) {
        Set<String> theFields = new Set<String>();
        Map<String, Schema.SObjectField> mapFields = theType.getDescribe().fields.getMap();
        for(String fieldName : mapFields.keySet()) {
            if (fieldName != 'Id' && mapFields.get(fieldName).getDescribe().isAccessible()) {
                theFields.add(fieldName.toLowerCase());
            }
        }
        return theFields;
    }

    public static void logIntegrationIssue(String thejson, String body, String endpoint) {

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();

        String[] toAddresses = new String[] {};
        toAddresses.add('solara.salesforce@gmail.com');
        mail.setToAddresses(toAddresses);
        mail.sethtmlBody(body + '\n\n\n\n\n' + thejson);
        mail.setSubject('Unsuccessful call to the hub: ' + endpoint);
        mails.add(mail);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(
        mails);
    }
}