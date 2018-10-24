public class addressResponseWrapper {

		public String AddressLine1;
		public String AddressLine2;
		public String AddressLine3;
		public String City;
		public String State;
		public String ZipOrPostalCode;
		public String Message;
		public Boolean AddressVerified;

		public addressResponseWrapper() {

		}

		public static AddressResponseWrapper parse(String json) {
    		return (AddressResponseWrapper) System.JSON.deserialize(json, AddressResponseWrapper.class);
   		}

 }