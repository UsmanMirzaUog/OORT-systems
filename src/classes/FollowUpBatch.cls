public class FollowUpBatch implements Database.batchable<SObject>,Database.AllowsCallouts {
   
    
   public Database.QueryLocator start(Database.BatchableContext BC){
      Date followUpDate = system.Today().addDays(Integer.valueOf(Label.FollowUp_Email));
      string recordType = 'Vendor';
      string soql = 'SELECT Id, Name, Email, Follow_Up_30_Day__c, Dinner_Meeting_90_Day__c,OwnerId, Owner.Email, Owner.Name FROM Contact where (Follow_Up_30_Day__c =:followUpDate OR Dinner_Meeting_90_Day__c =:followUpDate) AND RecordType.Name =: recordType';
      
      return Database.getQueryLocator( soql );
   }
   
   
   public void execute(Database.BatchableContext BC, List<sObject> contlist){
        List<Contact> contDtls = (List<Contact>)contlist;
               
        EmailTemplate et30 = [Select Id,Name from EmailTemplate where Name = '30 Days Follow Up Email'];
        EmailTemplate et90 = [Select Id,Name from EmailTemplate where Name = '90 Days Dinner Invite'];
        Date followUpDate = system.Today().addDays(Integer.valueOf(Label.FollowUp_Email));

        list<Messaging.SingleEmailMessage> mailList = new list<Messaging.SingleEmailMessage>();
        for(Contact cont : contDtls){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.toAddresses = new String[] { cont.Owner.Email };
            mail.setSenderDisplayName(cont.Owner.Name);
            mail.setTargetObjectId(cont.OwnerId);
            mail.setWhatId(cont.Id);
            mail.setSaveAsActivity(false);
            
            if(cont.Follow_Up_30_Day__c == followUpDate)
            mail.setTemplateId(et30.Id); 

            if(cont.Dinner_Meeting_90_Day__c == followUpDate)
            mail.setTemplateId(et90.Id); 
            
            
            mailList.add(mail);
        }
        system.debug('mailList++'+mailList);
        
        if(mailList.size() > 0){
             //Sent email
             Messaging.sendEmail(mailList);
             system.debug('Email is sent Successfully.');
        }
        
   }

    public void finish(Database.BatchableContext BC){

    }
       
}