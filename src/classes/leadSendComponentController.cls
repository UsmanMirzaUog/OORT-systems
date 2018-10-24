public with sharing class leadSendComponentController {

	@AuraEnabled
	public static String getLeadName(ID leadid){
		return [SELECT ID, Name FROM Lead WHERE ID = :leadid LIMIT 1][0].Name;
	}

 	@AuraEnabled
 	public static String sendLeadToHub(Id leadId){

		List<Lead_Products__c> lps = [SELECT Quantity__c, Product__r.External_Id__c FROM Lead_Products__c WHERE Lead__r.Id = :leadId];
		String query = Utils.getSelectStarQueryForSobjectType('Lead');
		system.debug (query);
		Lead l = Database.query(query);
		system.debug (l);
		String theJson = createLeadJson(l,lps);
		Boolean success = false;
		String returnString = '';
		try {
			SolaraHubIntegration.callHubService('createLead','POST',theJson);
			success = true;
			 } catch(Exception e) { success = false;}
		if (success) {
			returnString = 'Success';
		} else {
			returnString = 'Error along the way.';
		}

		return returnString;
	}

	public static String createLeadJson(Lead theLead, List<Lead_Products__c> theLeadProducts) {

        LeadWrapper lw = new LeadWrapper(theLead, theLeadProducts);
        String pretty = JSON.serialize(lw, true);
        return pretty;  
	}

	public class leadWrapper {

		public String FirstName {get; set;}
		public String LastName {get; set;}
		public Date DOB {get; set;}
		public String BillingAddress1 {get; set;}
		public String BillingAddress2 {get; set;}
		public String BillingAddress3 {get; set;}
		public String BillingCity {get; set;}
		public Integer BillingState {get; set;}
		public String BillingPostalCode {get; set;}
		public Integer LeadType {get; set;}
		public Integer LeadSource {get; set;}
		public Integer Manufacturer {get; set;}
		public Integer ProductCategory {get; set;}
		public String ManufacturerID {get; set;}
		public Boolean TrackLead {get; set;}
		public String MobilePhone {get; set;}
		public String HomePhone {get; set;}
		public Integer Preferred_Method_Of_Contact {get; set;}
		public String EMAIL {get; set;}
		public Integer Outside_Sales_Rep {get; set;}
		public String Doctor_FirstName  {get; set;}
		public String Doctor_LastName  {get; set;}
		public String Doctor_NPI  {get; set;}
		public String Doctor_Address  {get; set;}
		public String Doctor_Phone  {get; set;}
		public Date Date_Last_Seen_By_Doctor  {get; set;}
		public Integer Times_Testing_Per_Day  {get; set;}
		public Integer Times_Injecting_Per_Day  {get; set;}
		public Boolean Newly_Diagnosed  {get; set;}
		public Date Last_Date_of_Service  {get; set;}
		public Integer Supply_Amount {get; set;}
		public Integer Supplies_Remaining {get; set;}
		public Integer Brand_Of_Ts {get; set;}
		public Integer Needle_Size {get; set;}
		public Integer Brand_Of_Sensors {get; set;}
		public Boolean Ok_To_SW {get; set;}
		public Integer Current_Pump {get; set;}
		public Integer Brand_Of_Ips {get; set;}
		public Integer Site_Change {get; set;}
		public String Current_Pump_Serial_Number {get; set;}
		public String Purchase_Date_Of_Current_Pump {get; set;}
		public Integer Purchasing_Insurance {get; set;}
		public Integer Pump_Purchased_Through {get; set;}
		public String Issues_With_Current_Pump {get; set;}
		public Boolean Explain_Rx {get; set;}
		public Boolean Explain_Aob  {get; set;}
		public String Notes {get; set;}
		public String Additional_Notes {get; set;}
		public String Gender {get; set;}
		public Boolean IsPing {get; set;}
		public DateTime DiagnosisDate {get; set;}
		public Boolean ReferredToRetail {get; set;}
		public Boolean NewToCGMTherapy {get; set;}
		public List<LeadInsurances> LeadInsurances {get; set;}
		public List<LeadDocuments> LeadDocuments {get; set;}
		public List<QuotationDetailVM> QuotationDetailVM {get; set;}
		public leadWrapper(Lead theLead, List<Lead_Products__c> leadProducts) {
			this.FirstName = theLead.FirstName == null ? '' : theLead.FirstName;
			this.LastName = theLead.LastName == null ? '' : theLead.LastName;
			this.DOB = theLead.Date_Of_Birth__c; // make required field?
			this.BillingAddress1 = theLead.Street;
			this.BillingAddress2 = theLead.Street;
			this.BillingAddress3 = theLead.Street;
			this.BillingCity = theLead.City;
			this.BillingState = 1;
			this.BillingPostalCode = theLead.PostalCode;
			this.LeadType = 1;
			this.LeadSource = 1;
			this.Manufacturer = 1;
			this.ProductCategory = Integer.valueOf(theLead.ProductCategory__c);
			this.ManufacturerID = theLead.ManufacturerID__c;
			this.TrackLead = theLead.TrackLead__c;
			this.MobilePhone = theLead.MobilePhone;
			this.HomePhone = theLead.Phone;
			this.Preferred_Method_Of_Contact = 146;
			this.Email = theLead.Email;
			this.Outside_Sales_Rep = Integer.valueOf(theLead.Outside_Sales_Rep__c);
			this.Doctor_FirstName = theLead.Doctor_FirstName__c;
			this.Doctor_LastName = theLead.Doctor_LastName__c;
			this.Doctor_NPI = theLead.Doctor_NPI__c;
			this.Doctor_Address = theLead.Doctor_Address__c;
			this.Doctor_Phone = String.valueOf(theLead.Doctor_Phone__c);
			this.Date_Last_Seen_By_Doctor = theLead.Date_Last_Seen_By_Doctor__c;
			this.Times_Testing_Per_Day = Integer.valueOf(theLead.Times_Testing_Per_Day__c);
			this.Times_Injecting_Per_Day = Integer.valueOf(theLead.Times_Injecting_Per_Day__c);
			this.Newly_Diagnosed = theLead.Newly_Diagnosed__c;
			this.Last_Date_of_Service = theLead.Last_Date_of_Service__c;
			this.Supply_Amount = Integer.valueOf(theLead.Supply_Amount__c);
			this.Supplies_Remaining = Integer.valueOf(theLead.Supplies_Remaining__c);
			//this.Brand_Of_Ts = theLead.Brand_Of_Ts__c == null ? '' : theLead.Brand_Of_Ts__c;
			//this.Needle_Size = theLead.Needle_Size__c == null ? '' : theLead.Needle_Size__c;
			//this.Brand_Of_Sensors = theLead.Brand_Of_Sensors__c == null ? '' : theLead.Brand_Of_Sensors__c;
			this.Ok_To_SW = theLead.Ok_To_SW__c;
			//this.Current_Pump = theLead.Current_Pump__c == null ? '' : theLead.Current_Pump__c;
			//this.Brand_Of_Ips = theLead.Street == null ? '' : theLead.Street;
			this.Site_Change = Integer.valueOf(theLead.Site_Change__c);
			//this.Current_Pump_Serial_Number = theLead.Current_Pump_Serial_Number__c;
			//this.Purchase_Date_Of_Current_Pump = theLead.Purchase_Date_Of_Current_Pump;
			//this.Purchasing_Insurance = theLead.Purchasing_Insurance == null ? '' : theLead.Purchasing_Insurance;
			//this.Pump_Purchased_Through = theLead.Pump_Purchased_Through__c == null ? '' : theLead.Pump_Purchased_Through__c;
			this.Issues_With_Current_Pump = theLead.Issues_With_Current_Pump__c;
			this.Explain_Rx = theLead.Explain_Rx__c;
			this.Explain_Aob = theLead.Explain_Aob__c;
			this.Notes = theLead.Notes__c;
			//this.Additional_Notes = theLead.Additional_Notes__c;
			this.Gender = theLead.Gender__c;
			this.IsPing = theLead.IsPing__c;
			this.DiagnosisDate = theLead.DiagnosisDate__c;
			this.ReferredToRetail = theLead.ReferredToRetail__c;
			this.NewToCGMTherapy = theLead.NewToCGMTherapy__c;
			// insurance
			// documents
			// products
			List<QuotationDetailVM> qps= new List<QuotationDetailVM>();
			List<LeadInsurances> lis = new List<LeadInsurances>();
			List<LeadDocuments> ldcs = new List<LeadDocuments>();
			for (Lead_Products__c lp : leadProducts) {
				QuotationDetailVM qp = new QuotationDetailVM();
				qp.ItemHubID = lp.Product__r.External_Id__c;
				qp.Quantity = Integer.valueOf(lp.Quantity__c);
				qps.add(qp);
			}
			LeadInsurances li = new LeadInsurances(theLead);
			li.CustomerStatedInsurance = theLead.CustomerStatedInsurance__c;
			//lis.add(li);
			this.QuotationDetailVM = qps;
			this.LeadInsurances = lis;
			this.LeadDocuments = ldcs;
		}
	}
		public class QuotationDetailVM {
		public String ItemHubID {get; set;}
		public Integer Quantity {get; set;}
	}

	public class LeadInsurances {
		public String CustomerStatedInsurance {get; set;}
		public String CustomerStatedPhone {get; set;}
		public Integer PayorLevel {get; set;}
		public String PayorHubID {get; set;}
		public String PayorPhone {get; set;}
		public String PolicyNo {get; set;}
		public String NCDPDPolicyNo {get; set;}
		public String NCPDPGroupNo {get; set;}
		public String PolicyHolderName {get; set;}
		public String StartDate {get; set;}
		public String EndDate {get; set;}
		public String RelationToPolicyHolder{get; set;}
		public LeadInsurances(Lead theLead){
			this.CustomerStatedInsurance = theLead.CustomerStatedInsurance__c;
			this.CustomerStatedPhone = theLead.CustomerStatedPhone__c;
			this.PayorLevel = Integer.valueOf(theLead.PayorLevel__c);
			this.PayorHubID = theLead.PayorHubID__c;
			this.payorPhone = theLead.PayorPhone__c;
			this.PolicyNo = theLead.PolicyNo__c;
			this.NCDPDPolicyNo = theLead.NCDPDPolicyNo__c;
			this.NCPDPGroupNo = theLead.NCPDPGroupNo__c;
			this.PolicyHolderName = theLead.Policy_Holder_Name__c;
			this.StartDate = String.valueOf(theLead.StartDate__c);
			this.EndDate = String.valueOf(theLead.EndDate__c);
			this.RelationToPolicyHolder = theLead.RelationToPolicyHolder__c;
		}
	}

	public class LeadDocuments {
		public String DocumentName {get; set;}
		public String DocumentExt {get; set;}
		public String DocumentData {get; set;}
	}
}