/**
 * Created by danielpulache on 10/27/17.
 */

public with sharing class CreateSalesOrderController {
    public Account patient {get; set;}
    public Opportunity oppty {get; set;}
    public static Id patientId {get; set;}

    public class Data {
//        public List<PayorData> payors;
        public List<AddressData> addresses;
        public List<AddressData> billingAddresses;
        public List<ProviderData> providers;
        public List<AddressData> deliveryAddresses;
    }

//    public class PayorData{
//        public String name;
//        public String groupName;
//        public String id;
//        public PayorData(Insurance_Payor__c p) {
//            this.name = p.Name;
//            this.id = p.Id;
//            this.groupName = p.Group_Name__c;
//        }
//    }
    public class AddressData {
        public String name;
        public String street;
        public String city;
        public String state;
        public String zip;
        public String id;
        public Boolean isPrimary;
        public AddressData(Provider__c p) {
            this.name = 'Dr. '+p.Name;
            this.id = p.Id;
            this.state = p.State__c;
            this.city = p.City__c;
            this.street = String.isBlank(p.Address2__c) ? p.Address__c : p.Address__c +', '+ p.Address2__c;
            this.zip = p.Zip__c;
            this.isPrimary = true;
        }
        public AddressData(Address_Data__c d) {
            this.name = d.Name;
            this.id = d.Id;
            this.state = d.State_Province__c;
            this.city = d.City__c;
            this.street = d.Street__c;
            this.zip = d.Zip_Postal_Code__c;
            this.isPrimary = false;
            if(d.Primary__c) {
                this.isPrimary = true;
            }
        }
    }
    public class ProviderData{
        public String name;
        public String phone;
        public String id;
        public ProviderData(Provider__c p) {
            this.name = p.Name;
            this.id = p.Id;
            this.phone =  p.Phone__c;
        }
    }

    @RemoteAction
    public static Data getSalesOrderData(String patientIdTemp) {
        patientId = patientIdTemp;
        Data d = new Data();
//        d.payors = getPayors();
        AddressData primaryBillingAddress = getPrimaryBillingAddress();
        AddressData primaryShippingAddress = getPrimaryShippingAddress();
        List<AddressData> addresses = getAddresses();
        // Get your list of all addresses besides primary billing and delivery
        d.addresses = orderAddressesBasedOnPrimaryAddress(addresses);

        // Billing addresses = primary billing address + rest of the list
        List<addressData> billingAddresses = new List<CreateSalesOrderController.AddressData>();
        billingAddresses.add(primaryBillingAddress);
        billingAddresses.addall(addresses);
        d.billingAddresses = billingAddresses;

        d.providers = getProviders();

        List<AddressData> doctorAddresses = getDoctorAddresses();

        // Delivery addresses = primary shipping address + rest of the list
        List<AddressData> deliveryAddresses = new List<CreateSalesOrderController.AddressData>();
        if(primaryShippingAddress.street == NULL && primaryBillingAddress.street != NULL) {
            deliveryAddresses.add(primaryBillingAddress);
        } else {
            deliveryAddresses.add(primaryShippingAddress);
        }
        deliveryAddresses.addAll(addresses);
        deliveryAddresses.addAll(doctorAddresses);
        d.deliveryAddresses = deliveryAddresses;

        return d;
    }
    @RemoteAction
    public static void goCreateSalesOrder(String oppId, String addressId, String deliveryAddressId, String orderingProviderId, String primaryProviderId) {
        system.debug(oppId);
        system.debug(addressId);
        system.debug(deliveryAddressId);
        system.debug(orderingProviderId);
        system.debug(primaryProviderId);
        Opportunity theOppty = [SELECT Id, StageName FROM Opportunity WHERE Id =: oppId LIMIT 1];
        theOppty.StageName = 'Closed Won';
        update theOppty;

        List<Map<String, object>> infoList = new List<Map<String, object>>();
        Map<String, object> infoMap = new Map<String, object>();
        infoMap.put('oppId', oppId);
        infoMap.put('addressId', addressId);
        infoMap.put('deliveryAddressId', deliveryAddressId);
        infoMap.put('orderingProviderId', orderingProviderId);
        infoMap.put('primaryProviderId', primaryProviderId);
        infoList.add(infoMap);
        String theJSONString = JSON.serialize(infoList, true);
        SolaraHubIntegration.createSalesOrderUpdateOptions(theJSONString);
    }


//    private static List<PayorData> getPayors() {
//        List<PayorData> payors = new List<PayorData>();
//        for (Insurance_Payor__c payor : [SELECT Id, Name, Group_Name__c FROM Insurance_Payor__c WHERE Id IN (SELECT Insurance__c FROM Insurance_Patient_Junction__c WHERE Account__c =: patientId)]) {
//            payors.add(new PayorData(payor));
//        }
//        return payors;
//    }
    private static List<AddressData> getAddresses() {
        List<AddressData> addresses = new List<AddressData>();

        for (Address_Data__c address : [SELECT Id, Name, Street__c, City__c, State_Province__c, Zip_Postal_Code__c, Primary__c FROM Address_Data__c WHERE Account__c =: patientId AND NAME != 'Primary Billing Address' AND NAME != 'Primary Delivery Address']) {
            if(address.Street__c != NULL && address.Street__c != NULL && address.City__c != NULL && address.State_Province__c != NULL) {
                addresses.add(new AddressData(address));
            }
        }
        return addresses;
    }

    private static AddressData getPrimaryBillingAddress() {
        return new AddressData([SELECT Id, Name, Street__c, City__c, State_Province__c, Zip_Postal_Code__c, Primary__c FROM Address_Data__c WHERE Account__c =: patientId AND Name = 'Primary Billing Address' LIMIT 1]);
    }

    private static AddressData getPrimaryShippingAddress() {
        return new AddressData([SELECT Id, Name, Street__c, City__c, State_Province__c, Zip_Postal_Code__c, Primary__c FROM Address_Data__c WHERE Account__c =: patientId AND Name = 'Primary Delivery Address' LIMIT 1]);
    }

    private static List<ProviderData> getProviders() {
        List<ProviderData> providers = new List<ProviderData>();
        for (Provider__c provider : [SELECT Id, Name, Phone__c FROM Provider__c WHERE Id IN (SELECT Provider__c FROM Provider_Patient_Junction__c WHERE Patient__c =: patientId)]) {
            providers.add(new ProviderData(provider));
        }
        return providers;
    }

    private static List<AddressData> getDoctorAddresses() {
        List<AddressData> addresses = new List<AddressData>();
        for(Provider__c providerAddress : [SELECT Id, Name, Address__c, Address2__c, City__c, State__c, Zip__c FROM Provider__c WHERE Id IN (SELECT Provider__c FROM Provider_Patient_Junction__c WHERE Patient__c =: patientId)]) {
            addresses.add(new AddressData(providerAddress));
        }
        return addresses;
    }

    private static List<AddressData> orderAddressesBasedOnPrimaryAddress(List<AddressData> theAddressList) {
        AddressData isPrimaryAddress = null;
        for(AddressData theCurrentAddress : theAddressList) {
            if(theCurrentAddress.isPrimary) {
                isPrimaryAddress = theCurrentAddress;
                break;
            }
        }
        if(isPrimaryAddress != null) {
            Set<AddressData> theOrderedAddressSet = new Set<AddressData>{isPrimaryAddress};
            theOrderedAddressSet.addAll(theAddressList);
            return new List<AddressData>(theOrderedAddressSet);
        }
        return theAddressList;
    }
}