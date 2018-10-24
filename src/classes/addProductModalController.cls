global with sharing class addProductModalController { //KHB added with sharing

	public Account patient {get; set;}
	public Opportunity oppty {get; set;}


	public addProductModalController() {}

    @RemoteAction
    public static List<productWrapper> getProducts() {
        List<productWrapper> wrappers = new List<productWrapper>();
        for (Product2 prod : [SELECT Id, Name, Item_Group__c, Item_ID__c, Item_Name__c, Manufacturer__c, Procedure_Code__c from Product2]) {
            wrappers.add(new productWrapper(prod));
        }
        return wrappers;
    }

    @RemoteAction
    public static void doSave(Map<Id, productWrapper> products, Id oppId, Id pricebookId) {
        List<OpportunityLineItem> lineItems = new List<OpportunityLineItem>();

        Map<Id, Id> productToPricebook = new Map<Id, Id>();
        for (PriceBookEntry pb : [SELECT Id, Product2Id from PriceBookEntry WHERE Product2Id in :products.keySet() and Pricebook2Id = :pricebookId]) {
            productToPricebook.put(pb.Product2Id, pb.Id);
        }

        for (productWrapper p : products.values()) {
            if (productToPricebook.containsKey(p.id)) {
                lineItems.add(new OpportunityLineItem(
                    OpportunityId = oppId,
                    PriceBookEntryId = productToPricebook.get(p.id),
                    Quantity = 1,
                    TotalPrice = 1
                ));
            }
        }

        insert lineItems;
    }

    public class productWrapper {
        public Boolean isSelected {get; set;}
        public String itemName {get; set;}
        public String itemId {get; set;}
        public String itemGroup {get; set;}
        public String manufacturer {get; set;}
        public String procedureCode {get; set;}      
        public String id {get; set;}

        public productWrapper(Product2 p) {
            this.isSelected = false;
            this.itemName = p.Item_Name__c;
            this.itemGroup = p.Item_Group__c;
            this.itemId = p.Item_ID__c;
            this.manufacturer = p.Manufacturer__c;
            this.procedureCode = p.Procedure_Code__c;
            this.id = p.Id;
        }  
    }
}