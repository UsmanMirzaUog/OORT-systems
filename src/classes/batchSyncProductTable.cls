global class batchSyncProductTable implements Database.Batchable<productData>, Database.allowsCallouts {
	
	String query;
	String endpoint;
	
	global batchSyncProductTable(String url) {
		endpoint = url;
	}
	
	global List<productData> start(Database.BatchableContext BC) {
		
		Http h = new Http();

		// Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
		HttpRequest req = new HttpRequest();

		String username = BrightTree__c.getInstance('username') == null ? '' : BrightTree__c.getInstance('username').Value__c;
		String password = BrightTree__c.getInstance('password') == null ? '' : BrightTree__c.getInstance('password').Value__c;

		Blob headerValue = Blob.valueOf(username + ':' + password);
		String authorizationHeader = 'BASIC ' +
		EncodingUtil.base64Encode(headerValue);
		req.setHeader('Authorization', authorizationHeader);
		req.setHeader('cache-control', 'no-cache');
		req.setHeader('Authorization', authorizationHeader);

		req.setEndpoint(endpoint);
		req.setMethod('GET');

		// Send the request, and return a response
		HttpResponse res = h.send(req);

		system.debug (res.getBody());
		List<productData> productsData = (List<productData>)JSON.deserialize(res.getBody(), List<productData>.class);
		return productsData;
	}

   	global void execute(Database.BatchableContext BC, List<productData> scope) {
   		// take the list of productData and create Product2 objects and upsert them with ExternalId
   		List<Product2> products = new List<Product2>();

		Set<String> itemKeys = new Set<String>();
   		for (productData pd : scope) {
   			Product2 p = new Product2();
   			p.Name = pd.ItemName;
   			p.Item_Description__c = pd.ItemDescr;
   			p.Item_Group__c = pd.ItemGroup;
   			p.Item_ID__c = pd.ItemGroup;
   			p.Manufacturer__c = pd.ManufacturerName;
   			p.Procedure_Code__c = pd.ProcCode;
   			p.ILMS_ID__c = pd.ItemKey;
   			products.add(p);
			itemKeys.add(pd.ItemKey);
   		}
   		
		upsert products ILMS_ID__c;


		List<Pricebook2> stdPbs = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
		Id stdPbId;
		if (Test.isRunningTest()) stdPbId = Test.getStandardPricebookId();
		if (stdPbs.isEmpty() && stdPbId == null) return;

		Set<String> activePbes = new Set<String>();
		for (PricebookEntry pb : [SELECT Id, Product2.ILMS_ID__c FROM PricebookEntry WHERE IsActive = true AND Product2.ILMS_ID__c in :itemKeys]) activePbes.add(pb.Product2.ILMS_ID__c);

		List<PricebookEntry> entries = new List<PricebookEntry>();
		for (Product2 p : products) {
			if (activePbes.contains(p.ILMS_ID__c)) continue;
			entries.add(new PricebookEntry(
				Pricebook2Id = stdPbId == null ? stdPbs[0].Id : stdPbId,
				Product2Id = p.Id,
				UnitPrice = 1
			));
		}
		insert entries;
	}
	
	global void finish(Database.BatchableContext BC) {}

	global class productData {
		public String ItemDescr {get; set;}
        public String ItemGroup {get; set;}
        public String ItemID {get; set;}
        public String ItemKey {get; set;}
        public String ItemName {get; set;}
        public String ItemStatus {get; set;}
		public String ItemType {get; set;}
        public String KitItem {get; set;}
        public String Lotted {get; set;}
        public String ManufacturerID {get; set;}
        public String ManufacturerName {get; set;}
        public String NickName {get; set;}
		public String ProcCode {get; set;}
        public String RetailPurchAmount {get; set;}
        public String RetailRentalAmount {get; set;}
        public String SaleType {get; set;}
        public String SupercedeItemKey {get; set;}
        public String User1 {get; set;}
		public String User2 {get; set;}
        public String User3 {get; set;}
        public String User4 {get; set;}
        public String VendorItemID {get; set;}
        public String VendorItemName {get; set;}
        public String VendorName {get; set;}
        public String Weight {get; set;}
	}
    /*
    ItemDescr
	ItemGroup
	ItemID
	ItemKey
	ItemName
	ItemStatus
	ItemType
	KitItem
	Lotted
	ManufacturerID
	ManufacturerName
	NickName
	ProcCode
	RetailPurchAmount
	RetailRentalAmount
	SaleType
	SupercedeItemKey
	User1
	User2
	User3
	User4
	VendorItemID
	VendorItemName
	VendorName
	Weight
    */
}