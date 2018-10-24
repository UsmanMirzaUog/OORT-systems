public with sharing class addProviderModalController {
	public Provider__c theProvider;
	public List<Provider__c> providerSearchResults = new List<Provider__c>();
	public String searchString {get; set;}
	public static String providerSearchString {get; set;}
	public Account patient {get; set;} //The patient record that will come from the component attribute

	public addProviderModalController() {

	}

	public class Provider {
		public String DocKey;
		public String LastName;
		public String MiddleName;
		public String FirstName;
		public String NPINumber;
		public String Address1;
		public String Address2;
		public String City;
		public String State;
		public String PostalCode;
		public String PhoneNumber1;
		public String FaxNumber;
		public String Email;
		public String Suffix;
		public String MedicalID;
		public Boolean selectedProvider;

		public Provider(){
			selectedProvider = FALSE;
		}
	}

	public static HttpRequest buildWebServiceRequest(String url){
		// Instantiate a new HTTP request, specify the method (GET) as well as the endpoint
		HttpRequest req = new HttpRequest();

		String username = BrightTree__c.getInstance('username') == null ? '' : BrightTree__c.getInstance('username').Value__c;
		String password = BrightTree__c.getInstance('password') == null ? '' : BrightTree__c.getInstance('password').Value__c;

		Blob headerValue = Blob.valueOf(username + ':' + password);
		String authorizationHeader = 'BASIC ' + EncodingUtil.base64Encode(headerValue);
		req.setHeader('Authorization', authorizationHeader);
		req.setHeader('cache-control', 'no-cache');
		req.setHeader('Authorization', authorizationHeader);
		req.setEndpoint(url);
		req.setMethod('GET');

		return req;
	}

	public static HttpResponse invokeWebService(Http h, HttpRequest req){
		HttpResponse res = h.send(req);

		return res;
	}

	public static List<Provider> handleWebServiceResponse(HttpResponse res){
		system.debug('BODY = ' + res.getBody());
		return (List<Provider>)JSON.deserialize(res.getBody(), List<Provider>.class);
	}

	@RemoteAction
	public static List<Provider> getProvidersByLastName(String url){

		System.debug('*** SEARCH for ' + url + ' ***');

		//Build request
		HttpRequest req = buildWebServiceRequest(url);

		//Instantiate a new http object
		Http h = new Http();

		//Send the request, and return a response
		HttpResponse res = invokeWebService(h, req);

		//Return the list of Provider search results
		return handleWebServiceResponse(res);
	}

	@RemoteAction
	public static void addProvider(Provider theProvider, String patientId){
		//TODO: check if NPI exists, if not create new Provider, else create provider patient junction record
		System.debug('Add Provider');
		System.debug(theProvider);

		//Check for Provider with existing NPI
		String providerName = theProvider.FirstName + ' ' + theProvider.LastName;
		List<Provider__c> existingProviderList = [
				SELECT Id, Name, Address__c, Address2__c, City__c, State__c, Zip__c, Email__c, Fax__c, Phone__c, NPI__c
				FROM Provider__c
				WHERE ((Name =: providerName)
					AND (City__c =: theProvider.City)
					AND (State__c =: theProvider.State)
					AND (Phone__c =: theProvider.PhoneNumber1))
					OR (NPI__c != NULL AND NPI__c = :theProvider.NPINumber)
				LIMIT 1
		];

		System.debug('Provider from query: ' + existingProviderList);
		Provider__c providerToAdd = new Provider__c();

		//If no matching NPI, create a new Provider__c
		if(existingProviderList.size() < 1){
			providerToAdd.NPI__c = theProvider.NPINumber;
			providerToAdd.Name = theProvider.FirstName + ' ' + theProvider.LastName;
			providerToAdd.Address__c = theProvider.Address1;
			providerToAdd.Address2__c = theProvider.Address2;
			providerToAdd.City__c = theProvider.City;
			providerToAdd.State__c = theProvider.State;
			providerToAdd.Zip__c = theProvider.PostalCode;
			providerToAdd.Phone__c = theProvider.PhoneNumber1;
			providerToAdd.Fax__c = theProvider.FaxNumber;
			providerToAdd.Medical_Id__c = theProvider.MedicalID;
			providerToAdd.Email__c = theProvider.Email;

			try {
				INSERT providerToAdd;
			} catch (Exception e) {
				System.debug('********* EXCEPTION: ' + e);
				//TODO: Pass back error to modal page and display message
			}
		} else {
			providerToAdd = existingProviderList[0]; //Otherwise the provider gets the existing Provider info
		}

		//Create provider patient junction record
		Integer existingPpjs = [SELECT Count() FROM Provider_Patient_Junction__c WHERE Provider__c =: providerToAdd.Id AND Patient__c =: patientId];

		System.debug('existingPPJs: ' + existingPpjs);
		if (existingPpjs == 0) {
			System.debug('Adding new PPJ');
			Provider_Patient_Junction__c ppj = new Provider_Patient_Junction__c(Provider__c = providerToAdd.Id, Patient__c = patientId);

			try {
				System.debug('Provider Patient Juntion to Insert: ' + ppj);
				INSERT ppj;
			} catch (Exception e) {
				System.debug(e);
				//TODO: Pass back error to modal page and display message
			}
		}
	}
}